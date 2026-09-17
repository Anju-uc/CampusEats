const fs = require("node:fs/promises");
const path = require("node:path");
const { connectMongoDB, getDb, closeMongoDB } = require("./src/config/mongodb");
const {
  STUDENT_PROGRAMS,
  STUDENT_STATUS,
  normalizeProgram,
} = require("./src/common/constants/student");
const { normalizeStudentId } = require("./src/modules/auth/auth.validator");

function fail(message) {
  throw new Error(message);
}

function validateRecord(record, index) {
  if (!record || typeof record !== "object") {
    fail(`Registry record ${index + 1} must be an object`);
  }

  if (typeof record.studentId !== "string" || !record.studentId.trim()) {
    fail(`Registry record ${index + 1} has an invalid studentId`);
  }

  if (typeof record.name !== "string" || record.name.trim().length < 2) {
    fail(`Registry record ${index + 1} has an invalid name`);
  }

  const program = normalizeProgram(record.program);
  if (!program || !STUDENT_PROGRAMS.includes(program)) {
    fail(`Registry record ${index + 1} has an unsupported program`);
  }

  if (!Object.values(STUDENT_STATUS).includes(record.status)) {
    fail(`Registry record ${index + 1} has an invalid status`);
  }

  if (!Number.isInteger(record.graduationYear) || record.graduationYear < 1900) {
    fail(`Registry record ${index + 1} has an invalid graduationYear`);
  }

  return {
    studentId: normalizeStudentId(record.studentId),
    name: record.name.trim(),
    program,
    status: record.status,
    graduationYear: record.graduationYear,
  };
}

async function synchronizeExistingUser({ db, auth, record, now = new Date() }) {
  const users = db.collection("users");
  const user = await users.findOne({ studentId: record.studentId });

  if (!user) {
    return null;
  }

  await users.updateOne(
    { _id: user._id },
    {
      $set: {
        studentId: record.studentId,
        name: record.name,
        program: record.program,
        status: record.status,
        updatedAt: now,
      },
    }
  );

  let firebaseUser;
  try {
    firebaseUser = await auth.getUser(user.uid);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      return { user, firebaseUser: null };
    }
    throw error;
  }

  const shouldDisable = record.status !== STUDENT_STATUS.ACTIVE;
  if (firebaseUser.disabled !== shouldDisable) {
    await auth.updateUser(user.uid, { disabled: shouldDisable });
  }

  if (shouldDisable) {
    await auth.revokeRefreshTokens(user.uid);
  }

  return { user, firebaseUser };
}

async function upsertRegistryRecord({ db, auth, record, now = new Date() }) {
  const collection = db.collection("studentRegistry");

  try {
    await collection.updateOne(
      { studentId: record.studentId },
      {
        $set: { ...record, updatedAt: now },
        $setOnInsert: { createdAt: now },
      },
      { upsert: true }
    );
  } catch (error) {
    if (error.code === 11000) {
      throw new Error(`Student registry already contains ${record.studentId}`);
    }
    throw error;
  }

  return synchronizeExistingUser({ db, auth, record, now });
}

async function seedStudentRegistry() {
  const inputPath = process.argv[2];
  if (!inputPath) {
    fail("Usage: node seed-student-registry.js <registry.json>");
  }

  const raw = await fs.readFile(path.resolve(inputPath), "utf8");
  const records = JSON.parse(raw);
  if (!Array.isArray(records)) {
    fail("Registry input must be a JSON array");
  }

  const normalizedRecords = records.map(validateRecord);
  const ids = new Set();
  for (const record of normalizedRecords) {
    if (ids.has(record.studentId)) {
      fail(`Duplicate studentId in input: ${record.studentId}`);
    }
    ids.add(record.studentId);
  }

  await connectMongoDB();
  const db = getDb();
  const now = new Date();
  let firebaseAuth;

  for (const record of normalizedRecords) {
    if (!firebaseAuth) {
      firebaseAuth = require("./src/config/firebase").auth;
    }

    await upsertRegistryRecord({
      db,
      auth: firebaseAuth,
      record,
      now,
    });
  }

  console.log(`Student registry seed completed: ${normalizedRecords.length} record(s).`);
}

if (require.main === module) {
  seedStudentRegistry()
    .catch((error) => {
      console.error("Student registry seed failed:", error.message);
      process.exitCode = 1;
    })
    .finally(async () => {
      await closeMongoDB();
    });
}

module.exports = {
  validateRecord,
  synchronizeExistingUser,
  upsertRegistryRecord,
  seedStudentRegistry,
};
