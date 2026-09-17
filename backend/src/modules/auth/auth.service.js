const { auth } = require("../../config/firebase");
const { getDb } = require("../../config/mongodb");
const {
  STUDENT_STATUS,
  STUDENT_PROGRAMS,
} = require("../../common/constants/student");
const { ROLES } = require("../../common/constants/roles");
const { normalizeStudentId } = require("./auth.validator");

const GENERIC_LOGIN_ERROR = "Invalid student ID or password";

function createError(message, statusCode) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.isOperational = true;
  return error;
}

function getInternalFirebaseEmail(studentId) {
  const normalizedId = normalizeStudentId(studentId);
  const encodedId = Buffer.from(normalizedId)
    .toString("base64url");
  return `${encodedId}@students.campuseats.internal`;
}

function toStudentResponse(user, tokens = {}) {
  return {
    uid: user.uid,
    studentId: user.studentId,
    name: user.name,
    program: user.program,
    status: user.status,
    role: user.role,
    ...(tokens.idToken ? tokens : {}),
  };
}

async function registerUser({ studentId, password }) {
  const normalizedStudentId = normalizeStudentId(studentId);

  if (!normalizedStudentId) {
    throw createError("Student ID is required", 400);
  }

  const users = getDb().collection("users");
  const registry = getDb().collection("studentRegistry");
  const registryStudent = await registry.findOne({
    studentId: normalizedStudentId,
  });

  if (!registryStudent) {
    throw createError("Student is not authorized for registration", 403);
  }

  if (
    registryStudent.status !== STUDENT_STATUS.ACTIVE ||
    !STUDENT_PROGRAMS.includes(registryStudent.program)
  ) {
    throw createError("Student is not eligible for registration", 403);
  }

  const existingId = await users.findOne({ studentId: normalizedStudentId });

  if (existingId) {
    throw createError("Student ID already registered", 409);
  }

  const firebaseEmail = getInternalFirebaseEmail(normalizedStudentId);
  let userRecord;

  try {
    userRecord = await auth.createUser({
      email: firebaseEmail,
      password,
      displayName: registryStudent.name,
      emailVerified: false,
    });

    const now = new Date();
    const userDocument = {
      uid: userRecord.uid,
      studentId: normalizedStudentId,
      name: registryStudent.name,
      program: registryStudent.program,
      status: STUDENT_STATUS.ACTIVE,
      role: ROLES.STUDENT,
      createdAt: now,
      updatedAt: now,
    };

    try {
      await users.insertOne(userDocument);
    } catch (error) {
      if (error.code === 11000) {
        await auth.deleteUser(userRecord.uid);
        throw createError("Student ID already registered", 409);
      }
      await auth.deleteUser(userRecord.uid).catch(() => undefined);
      throw error;
    }

    return toStudentResponse(userDocument);
  } catch (error) {
    if (error.statusCode) {
      throw error;
    }

    if (error.code === "auth/email-already-exists") {
      throw createError("Student ID already registered", 409);
    }

    if (
      error.code === "auth/password-does-not-meet-requirements" ||
      error.code === "auth/weak-password"
    ) {
      throw createError("Password does not meet Firebase requirements", 400);
    }

    throw error;
  }
}

async function loginUser({ studentId, password }) {
  const normalizedStudentId = normalizeStudentId(studentId);
  const users = getDb().collection("users");
  const registry = getDb().collection("studentRegistry");
  const registryStudent = await registry.findOne({
    studentId: normalizedStudentId,
  });
  const user = await users.findOne({ studentId: normalizedStudentId });

  if (
    !registryStudent ||
    registryStudent.status !== STUDENT_STATUS.ACTIVE ||
    !user ||
    user.role !== ROLES.STUDENT ||
    user.status !== STUDENT_STATUS.ACTIVE
  ) {
    throw createError(GENERIC_LOGIN_ERROR, 401);
  }

  const apiKey = process.env.FIREBASE_WEB_API_KEY;

  if (!apiKey) {
    throw createError("FIREBASE_WEB_API_KEY is not configured", 500);
  }

  const firebaseUrl =
    `https://identitytoolkit.googleapis.com/v1/` +
    `accounts:signInWithPassword?key=${apiKey}`;
  const response = await fetch(firebaseUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email: getInternalFirebaseEmail(normalizedStudentId),
      password,
      returnSecureToken: true,
    }),
  });
  const data = await response.json();

  if (!response.ok) {
    const message = data?.error?.message;

    if (
      message === "EMAIL_NOT_FOUND" ||
      message === "INVALID_PASSWORD" ||
      message === "INVALID_LOGIN_CREDENTIALS" ||
      message === "USER_DISABLED"
    ) {
      throw createError(GENERIC_LOGIN_ERROR, 401);
    }

    throw createError("Firebase authentication failed", 401);
  }

  return toStudentResponse(user, {
    idToken: data.idToken,
    refreshToken: data.refreshToken,
    expiresIn: data.expiresIn,
  });
}

async function updateStudentStatus(studentId, status) {
  if (!Object.values(STUDENT_STATUS).includes(status)) {
    throw createError("Invalid student status", 400);
  }

  const users = getDb().collection("users");
  const registry = getDb().collection("studentRegistry");
  const normalizedStudentId = normalizeStudentId(studentId);
  const registryStudent = await registry.findOne({
    studentId: normalizedStudentId,
  });

  if (!registryStudent) {
    throw createError("Student not found", 404);
  }

  const user = await users.findOne({ studentId: normalizedStudentId });

  const now = new Date();
  await registry.updateOne(
    { _id: registryStudent._id },
    { $set: { status, updatedAt: now } }
  );

  if (!user) {
    return { ...registryStudent, status, updatedAt: now };
  }

  await users.updateOne({ _id: user._id }, { $set: { status, updatedAt: now } });

  if (status === STUDENT_STATUS.ACTIVE) {
    await auth.updateUser(user.uid, { disabled: false });
  } else {
    await auth.updateUser(user.uid, { disabled: true });
    await auth.revokeRefreshTokens(user.uid);
  }

  return { ...user, status, updatedAt: now };
}

module.exports = {
  GENERIC_LOGIN_ERROR,
  getInternalFirebaseEmail,
  registerUser,
  loginUser,
  updateStudentStatus,
};
