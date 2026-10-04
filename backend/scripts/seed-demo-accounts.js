require("dotenv").config();
const { auth } = require("../src/config/firebase");
const { connectMongoDB, closeMongoDB, getDb } = require("../src/config/mongodb");
const { normalizeStudentId } = require("../src/modules/auth/auth.validator");
const { ROLES } = require("../src/common/constants/roles");
const { STUDENT_STATUS } = require("../src/common/constants/student");

function formatFirebasePassword(password) {
  if (typeof password !== "string") return "";
  if (password.length < 6) {
    return `${password}#CampusEATS`;
  }
  return password;
}

function getInternalStudentFirebaseEmail(studentId) {
  const normalizedId = normalizeStudentId(studentId);
  const encodedId = Buffer.from(normalizedId).toString("base64url");
  return `${encodedId}@students.campuseats.internal`;
}

const ADMIN_ACCOUNTS = [
  {
    staffId: "admin.bengalurucafe",
    email: "admin.bengalurucafe@campuseats.local",
    password: "1234",
    name: "Bengaluru Cafe Admin",
    role: ROLES.ADMIN,
    cafeteria: "Bengaluru Cafe",
    cafeteriaId: "bengaluru",
    title: "Bengaluru Cafe Admin",
  },
  {
    staffId: "admin.pesucafe",
    email: "admin.pesucafe@campuseats.local",
    password: "1234",
    name: "PESU Cafe Admin",
    role: ROLES.ADMIN,
    cafeteria: "PESU Cafe",
    cafeteriaId: "pesucafe",
    title: "PESU Cafe Admin",
  },
  {
    staffId: "admin.nonveg",
    email: "admin.nonveg@campuseats.local",
    password: "1234",
    name: "Nonveg Admin",
    role: ROLES.ADMIN,
    cafeteria: "Nonveg",
    cafeteriaId: "nonveg",
    title: "Nonveg Admin",
  },
];

const STUDENT_ACCOUNTS = [
  {
    studentId: "PES1UG24CA003",
    name: "Student 003",
    program: "B.Tech",
    password: "1234",
    role: ROLES.STUDENT,
    status: STUDENT_STATUS.ACTIVE,
  },
  {
    studentId: "PES1UG24CA059",
    name: "Student 059",
    program: "B.Tech",
    password: "1234",
    role: ROLES.STUDENT,
    status: STUDENT_STATUS.ACTIVE,
  },
  {
    studentId: "PES1UG24CA076",
    name: "Student 076",
    program: "B.Tech",
    password: "1234",
    role: ROLES.STUDENT,
    status: STUDENT_STATUS.ACTIVE,
  },
  {
    studentId: "PES1UG24CA180",
    name: "Student 180",
    program: "B.Tech",
    password: "1234",
    role: ROLES.STUDENT,
    status: STUDENT_STATUS.ACTIVE,
  },
];

const FACULTY_ACCOUNTS = [
  {
    rollNumber: "FAC001",
    staffId: "fac001",
    email: "fac001@faculty.campuseats.local",
    password: "1234",
    name: "Faculty 01",
    role: ROLES.FACULTY,
    status: "ACTIVE",
    program: "Faculty",
  },
  {
    rollNumber: "FAC002",
    staffId: "fac002",
    email: "fac002@faculty.campuseats.local",
    password: "1234",
    name: "Faculty 02",
    role: ROLES.FACULTY,
    status: "ACTIVE",
    program: "Faculty",
  },
  {
    rollNumber: "FAC003",
    staffId: "fac003",
    email: "fac003@faculty.campuseats.local",
    password: "1234",
    name: "Faculty 03",
    role: ROLES.FACULTY,
    status: "ACTIVE",
    program: "Faculty",
  },
];

async function ensureFirebaseUser(email, password, displayName) {
  const formattedPassword = formatFirebasePassword(password);
  try {
    const user = await auth.createUser({
      email,
      password: formattedPassword,
      displayName,
      emailVerified: false,
    });
    return user;
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      const user = await auth.getUserByEmail(email);
      await auth.updateUser(user.uid, {
        password: formattedPassword,
        displayName,
        disabled: false,
      });
      return user;
    }
    throw error;
  }
}

async function seed() {
  console.log("Connecting to MongoDB Atlas...");
  await connectMongoDB();
  const db = getDb();
  const usersCollection = db.collection("users");
  const registryCollection = db.collection("studentRegistry");

  console.log("\n--- Seeding 3 Hotel Admin Accounts ---");
  for (const admin of ADMIN_ACCOUNTS) {
    const fbUser = await ensureFirebaseUser(admin.email, admin.password, admin.name);
    const now = new Date();
    const doc = {
      uid: fbUser.uid,
      staffId: admin.staffId.toLowerCase(),
      email: admin.email.toLowerCase(),
      name: admin.name,
      role: ROLES.ADMIN,
      status: "ACTIVE",
      cafeteria: admin.cafeteria,
      cafeteriaId: admin.cafeteriaId,
      title: admin.title,
      updatedAt: now,
    };

    const existing = await usersCollection.findOne({
      $or: [
        { uid: fbUser.uid },
        { staffId: admin.staffId.toLowerCase() },
        { email: admin.email.toLowerCase() },
      ],
    });

    if (existing) {
      await usersCollection.updateOne({ _id: existing._id }, { $set: doc });
    } else {
      doc.createdAt = now;
      await usersCollection.insertOne(doc);
    }
    console.log(`✓ Admin [${admin.staffId}] (${admin.cafeteria}) provisioned.`);
  }

  console.log("\n--- Seeding 4 Student Accounts ---");
  for (const student of STUDENT_ACCOUNTS) {
    const normId = normalizeStudentId(student.studentId);
    const fbEmail = getInternalStudentFirebaseEmail(normId);
    const fbUser = await ensureFirebaseUser(fbEmail, student.password, student.name);
    const now = new Date();

    // 1. Update Student Registry
    await registryCollection.updateOne(
      { studentId: normId },
      {
        $set: {
          studentId: normId,
          name: student.name,
          program: student.program,
          status: student.status,
          updatedAt: now,
        },
        $setOnInsert: { createdAt: now },
      },
      { upsert: true }
    );

    // 2. Update Users Collection
    const doc = {
      uid: fbUser.uid,
      studentId: normId,
      name: student.name,
      program: student.program,
      role: ROLES.STUDENT,
      status: STUDENT_STATUS.ACTIVE,
      updatedAt: now,
    };

    const existing = await usersCollection.findOne({
      $or: [{ uid: fbUser.uid }, { studentId: normId }],
    });

    if (existing) {
      await usersCollection.updateOne({ _id: existing._id }, { $set: doc });
    } else {
      doc.createdAt = now;
      await usersCollection.insertOne(doc);
    }
    console.log(`✓ Student [${normId}] (${student.name}) provisioned.`);
  }

  console.log("\n--- Seeding 3 Faculty Accounts ---");
  for (const faculty of FACULTY_ACCOUNTS) {
    const fbUser = await ensureFirebaseUser(faculty.email, faculty.password, faculty.name);
    const now = new Date();
    const doc = {
      uid: fbUser.uid,
      rollNumber: faculty.rollNumber,
      staffId: faculty.staffId.toLowerCase(),
      email: faculty.email.toLowerCase(),
      name: faculty.name,
      role: ROLES.FACULTY,
      status: "ACTIVE",
      program: "Faculty",
      title: faculty.name,
      updatedAt: now,
    };

    const existing = await usersCollection.findOne({
      $or: [
        { uid: fbUser.uid },
        { rollNumber: faculty.rollNumber },
        { staffId: faculty.staffId.toLowerCase() },
        { email: faculty.email.toLowerCase() },
      ],
    });

    if (existing) {
      await usersCollection.updateOne({ _id: existing._id }, { $set: doc });
    } else {
      doc.createdAt = now;
      await usersCollection.insertOne(doc);
    }
    console.log(`✓ Faculty [${faculty.rollNumber}] (${faculty.name}) provisioned.`);
  }

  // Cleanup any old test accounts that don't belong to the 10 demo accounts
  const demoUids = new Set();
  const allUsers = await usersCollection.find({}).toArray();
  for (const u of allUsers) {
    const isDemo =
      ADMIN_ACCOUNTS.some((a) => a.staffId.toLowerCase() === u.staffId) ||
      STUDENT_ACCOUNTS.some((s) => normalizeStudentId(s.studentId) === u.studentId) ||
      FACULTY_ACCOUNTS.some((f) => f.rollNumber === u.rollNumber);
    if (isDemo) {
      demoUids.add(u.uid);
    }
  }

  // Remove obsolete test accounts from Mongo if they are not in the 10 demo accounts
  const deleteRes = await usersCollection.deleteMany({ uid: { $nin: Array.from(demoUids) } });
  if (deleteRes.deletedCount > 0) {
    console.log(`Cleaned up ${deleteRes.deletedCount} non-demo user(s) from MongoDB.`);
  }

  // Clean Firebase Auth list to exact 10 users
  const fbList = await auth.listUsers(100);
  for (const u of fbList.users) {
    if (!demoUids.has(u.uid)) {
      await auth.deleteUser(u.uid).catch(() => undefined);
    }
  }

  // Final Summary
  const finalMongoCount = await usersCollection.countDocuments();
  const finalFbList = await auth.listUsers(100);
  console.log("\n==========================================");
  console.log(`Final MongoDB Users Count: ${finalMongoCount}`);
  console.log(`Final Firebase Auth Users Count: ${finalFbList.users.length}`);
  console.log("==========================================");
}

seed()
  .catch((err) => {
    console.error("Seed error:", err);
    process.exit(1);
  })
  .finally(() => closeMongoDB());
