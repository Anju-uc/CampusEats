const crypto = require("node:crypto");
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
      password: formatFirebasePassword(password),
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

  if (!registryStudent || registryStudent.status !== STUDENT_STATUS.ACTIVE) {
    throw createError(GENERIC_LOGIN_ERROR, 401);
  }

  const existingUser = await users.findOne({
    studentId: normalizedStudentId,
  });
  if (existingUser && existingUser.status !== STUDENT_STATUS.ACTIVE) {
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
      password: formatFirebasePassword(password),
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

  let user = await users.findOne({
    $or: [{ uid: data.localId }, { studentId: normalizedStudentId }],
  });

  const now = new Date();
  if (!user) {
    user = {
      uid: data.localId,
      studentId: normalizedStudentId,
      name: registryStudent.name || data.displayName || "Student",
      program: registryStudent.program || "B.Tech",
      status: STUDENT_STATUS.ACTIVE,
      role: ROLES.STUDENT,
      createdAt: now,
      updatedAt: now,
    };
    await users.insertOne(user);
  } else {
    const updates = {};
    if (!user.studentId) updates.studentId = normalizedStudentId;
    if (!user.uid) updates.uid = data.localId;
    if (!user.name && (registryStudent.name || data.displayName)) {
      updates.name = registryStudent.name || data.displayName;
    }
    if (!user.program && registryStudent.program) {
      updates.program = registryStudent.program;
    }
    if (user.role !== ROLES.STUDENT) updates.role = ROLES.STUDENT;
    if (user.status !== STUDENT_STATUS.ACTIVE) updates.status = STUDENT_STATUS.ACTIVE;

    if (Object.keys(updates).length > 0) {
      updates.updatedAt = now;
      await users.updateOne({ _id: user._id }, { $set: updates });
      user = { ...user, ...updates };
    }
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

function formatFirebasePassword(password) {
  if (typeof password !== "string") return "";
  if (password.length < 6) {
    return `${password}#CampusEATS`;
  }
  return password;
}

function getInternalStaffFirebaseEmail(staffId) {
  const normalized = String(staffId || "").trim().toLowerCase();
  if (normalized.includes("@")) {
    return normalized;
  }
  const encoded = Buffer.from(normalized).toString("base64url");
  return `${encoded}@staff.campuseats.internal`;
}

async function loginStaff({ identifier, email, staffId, rollNumber, password }) {
  const loginId = String(identifier || email || staffId || rollNumber || "").trim();

  if (!loginId || !password) {
    throw createError("Staff identifier and password are required", 400);
  }

  const users = getDb().collection("users");
  const normalizedLower = loginId.toLowerCase();
  const upperId = loginId.toUpperCase();

  let user = await users.findOne({
    $or: [
      { email: normalizedLower },
      { staffId: normalizedLower },
      { staffId: loginId },
      { rollNumber: loginId },
      { rollNumber: upperId },
      { rollNumber: normalizedLower },
      { username: normalizedLower },
      { studentId: upperId },
      { studentId: loginId },
    ],
  });

  if (user) {
    const staffRoles = [ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY];
    if (!staffRoles.includes(user.role)) {
      throw createError("Invalid staff credentials", 401);
    }
    if (user.status !== "ACTIVE") {
      throw createError("Staff account is not active", 403);
    }
  }

  const apiKey = process.env.FIREBASE_WEB_API_KEY;
  if (!apiKey) {
    throw createError("FIREBASE_WEB_API_KEY is not configured", 500);
  }

  let firebaseEmail = user?.email;
  if (!firebaseEmail) {
    if (normalizedLower.includes("@")) {
      firebaseEmail = normalizedLower;
    } else if (normalizedLower.startsWith("admin.")) {
      firebaseEmail = `${normalizedLower}@campuseats.local`;
    } else if (normalizedLower.startsWith("fac")) {
      firebaseEmail = `${normalizedLower}@faculty.campuseats.local`;
    } else {
      firebaseEmail = getInternalStaffFirebaseEmail(user?.staffId || user?.rollNumber || loginId);
    }
  }

  const firebaseUrl =
    `https://identitytoolkit.googleapis.com/v1/` +
    `accounts:signInWithPassword?key=${apiKey}`;

  const response = await fetch(firebaseUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email: firebaseEmail,
      password: formatFirebasePassword(password),
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
      throw createError("Invalid staff credentials", 401);
    }
    throw createError("Firebase authentication failed", 401);
  }

  const resolvedUid = data.localId || user?.uid;

  if (!user) {
    user = await users.findOne({
      $or: [
        ...(resolvedUid ? [{ uid: resolvedUid }] : []),
        { email: firebaseEmail },
        { staffId: normalizedLower },
      ],
    });
  }

  const now = new Date();
  if (!user) {
    let inferredRole = ROLES.FACULTY;
    let cafeteria = "Bengaluru Cafe";
    let cafeteriaId = "bengaluru";
    if (normalizedLower.startsWith("admin.")) {
      inferredRole = ROLES.ADMIN;
      if (normalizedLower.includes("pesu")) {
        cafeteria = "PESU Cafe";
        cafeteriaId = "pesucafe";
      } else if (normalizedLower.includes("nonveg")) {
        cafeteria = "Nonveg";
        cafeteriaId = "nonveg";
      }
    } else if (normalizedLower.startsWith("kitchen.")) {
      inferredRole = ROLES.KITCHEN;
    }

    user = {
      uid: resolvedUid,
      staffId: normalizedLower,
      rollNumber: normalizedLower.startsWith("fac") ? upperId : undefined,
      email: firebaseEmail,
      name: data.displayName || `${cafeteria} ${inferredRole}`,
      role: inferredRole,
      status: "ACTIVE",
      cafeteria,
      cafeteriaId,
      title: `${cafeteria} ${inferredRole}`,
      createdAt: now,
      updatedAt: now,
    };
    await users.insertOne(user);
  } else if (data.localId && (!user.uid || user.uid !== data.localId)) {
    await users.updateOne({ _id: user._id }, { $set: { uid: data.localId, updatedAt: now } });
    user.uid = data.localId;
  }

  return {
    uid: user.uid || resolvedUid,
    staffId: user.staffId || user.rollNumber || user.email || loginId,
    rollNumber: user.rollNumber,
    email: user.email || user.staffId || loginId,
    name: user.name || user.displayName || user.role,
    role: user.role,
    status: user.status,
    cafeteria: user.cafeteria || "Bengaluru Cafe",
    cafeteriaId: user.cafeteriaId || "bengaluru",
    title: user.title || `${user.role} (${user.cafeteria || "Main"})`,
    idToken: data.idToken,
    refreshToken: data.refreshToken,
    expiresIn: data.expiresIn,
  };
}

async function provisionStaffUser({
  email,
  staffId,
  rollNumber,
  password,
  name,
  role,
  cafeteria = "Bengaluru Cafe",
  cafeteriaId = "bengaluru",
  title,
}) {
  if (![ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY].includes(role)) {
    throw createError(`Invalid staff role: ${role}`, 400);
  }
  const loginIdentifier = email || staffId || rollNumber;
  if (!loginIdentifier || !password) {
    throw createError("Staff identifier and password are required", 400);
  }

  const firebaseEmail = email || getInternalStaffFirebaseEmail(staffId || rollNumber);
  const users = getDb().collection("users");

  let userRecord;
  try {
    userRecord = await auth.createUser({
      email: firebaseEmail,
      password: formatFirebasePassword(password),
      displayName: name || role,
      emailVerified: false,
    });
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      userRecord = await auth.getUserByEmail(firebaseEmail);
      if (password) {
        await auth.updateUser(userRecord.uid, {
          password: formatFirebasePassword(password),
          disabled: false,
          displayName: name || role,
        });
      }
    } else {
      throw error;
    }
  }

  const now = new Date();
  const staffDoc = {
    uid: userRecord.uid,
    staffId: (staffId || email || rollNumber).toLowerCase(),
    email: (email || staffId || rollNumber).toLowerCase(),
    name: name || `${cafeteria} ${role}`,
    role,
    status: "ACTIVE",
    cafeteria,
    cafeteriaId,
    title: title || `${cafeteria} ${role}`,
    updatedAt: now,
  };

  if (rollNumber) {
    staffDoc.rollNumber = rollNumber;
  }

  const queryConditions = [
    { uid: userRecord.uid },
    { email: loginIdentifier.toLowerCase() },
    { staffId: loginIdentifier.toLowerCase() },
  ];
  if (rollNumber) {
    queryConditions.push({ rollNumber });
  }

  const existing = await users.findOne({ $or: queryConditions });

  if (existing) {
    await users.updateOne({ _id: existing._id }, { $set: staffDoc });
  } else {
    staffDoc.createdAt = now;
    await users.insertOne(staffDoc);
  }

  return {
    uid: userRecord.uid,
    email: staffDoc.email,
    staffId: staffDoc.staffId,
    name: staffDoc.name,
    role: staffDoc.role,
    status: staffDoc.status,
    cafeteria: staffDoc.cafeteria,
    cafeteriaId: staffDoc.cafeteriaId,
  };
}

function createCampusCheckinChallenge({ expiresIn = 120 } = {}) {
  const secret = process.env.CAMPUS_ACCESS_SECRET;
  const campusId = process.env.CAMPUS_ID;

  if (!secret || !campusId) {
    const error = new Error("Campus access verification is not configured");
    error.statusCode = 503;
    throw error;
  }

  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + expiresIn;
  const payload = Buffer.from(
    JSON.stringify({
      type: "CAMPUS_CHECKIN_CHALLENGE",
      campusId,
      iat,
      exp,
      jti: crypto.randomUUID(),
    })
  ).toString("base64url");
  const signature = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("base64url");

  return `${payload}.${signature}`;
}

async function verifyCampusCheckinAndIssueProof({ uid, checkinChallenge }) {
  const secret = process.env.CAMPUS_ACCESS_SECRET;
  const campusId = process.env.CAMPUS_ID;

  if (!secret || !campusId) {
    const error = new Error("Campus access verification is not configured");
    error.statusCode = 503;
    throw error;
  }

  if (!checkinChallenge || typeof checkinChallenge !== "string") {
    const error = new Error("Campus check-in challenge is required");
    error.statusCode = 400;
    throw error;
  }

  const parts = checkinChallenge.trim().split(".");
  if (parts.length !== 2) {
    const error = new Error("Invalid campus check-in challenge format");
    error.statusCode = 400;
    throw error;
  }

  const [payloadPart, signaturePart] = parts;
  const expectedSignature = crypto
    .createHmac("sha256", secret)
    .update(payloadPart)
    .digest("base64url");

  const providedSignature = Buffer.from(signaturePart);
  const expectedSignatureBuffer = Buffer.from(expectedSignature);
  const signaturesMatch =
    providedSignature.length === expectedSignatureBuffer.length &&
    crypto.timingSafeEqual(providedSignature, expectedSignatureBuffer);

  if (!signaturesMatch) {
    const error = new Error("Invalid campus check-in challenge signature");
    error.statusCode = 403;
    throw error;
  }

  let payload;
  try {
    payload = JSON.parse(Buffer.from(payloadPart, "base64url").toString("utf8"));
  } catch (_) {
    const error = new Error("Invalid campus check-in challenge payload");
    error.statusCode = 400;
    throw error;
  }

  const now = Math.floor(Date.now() / 1000);

  if (
    payload.type !== "CAMPUS_CHECKIN_CHALLENGE" ||
    payload.campusId !== campusId ||
    !Number.isInteger(payload.exp) ||
    payload.exp <= now ||
    !Number.isInteger(payload.iat) ||
    payload.iat > now ||
    payload.exp - payload.iat > 300 ||
    typeof payload.jti !== "string" ||
    payload.jti.length < 16 ||
    payload.jti.length > 128
  ) {
    const error = new Error("Campus check-in challenge has expired or is invalid");
    error.statusCode = 403;
    throw error;
  }

  try {
    await getDb().collection("campusCheckinChallenges").insertOne({
      jti: payload.jti,
      campusId: payload.campusId,
      claimedByUid: uid,
      expiresAt: new Date(payload.exp * 1000),
      consumedAt: new Date(),
    });
  } catch (err) {
    if (err.code === 11000) {
      const error = new Error("Campus check-in challenge has already been used");
      error.statusCode = 403;
      throw error;
    }
    throw err;
  }

  const proof = createCampusProof(uid);

  return {
    campusProof: proof,
    campusId,
    expiresInSeconds: 60,
  };
}

function createCampusProof(uid) {
  const secret = process.env.CAMPUS_ACCESS_SECRET;
  const campusId = process.env.CAMPUS_ID;

  if (!secret || !campusId) {
    const error = new Error("Campus access verification is not configured");
    error.statusCode = 503;
    throw error;
  }

  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 60;
  const payload = Buffer.from(
    JSON.stringify({
      uid,
      campusId,
      iat,
      exp,
      jti: crypto.randomUUID(),
    })
  ).toString("base64url");
  const signature = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("base64url");

  return `${payload}.${signature}`;
}

module.exports = {
  GENERIC_LOGIN_ERROR,
  getInternalFirebaseEmail,
  getInternalStaffFirebaseEmail,
  registerUser,
  loginUser,
  loginStaff,
  provisionStaffUser,
  updateStudentStatus,
  createCampusProof,
  createCampusCheckinChallenge,
  verifyCampusCheckinAndIssueProof,
};
