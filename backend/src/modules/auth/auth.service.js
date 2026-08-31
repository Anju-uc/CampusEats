const { auth } = require("../../config/firebase");
const { getDb } = require("../../config/mongodb");

// ============================================================
// REGISTER USER
// ============================================================

async function registerUser({
  studentId,
  name,
  email,
  password,
  role = "Student",
}) {
  if (!studentId) {
    const err = new Error("Student ID is required");
    err.statusCode = 400;
    throw err;
  }

  const db = getDb();
  const users = db.collection("users");

  // Check whether the ID is already used.
  const existingId = await users.findOne({ studentId });

  if (existingId) {
    const err = new Error("Student ID already registered");
    err.statusCode = 409;
    throw err;
  }

  try {
    // Create Firebase account.
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: name,
      emailVerified: false,
    });

    // Store application user information in MongoDB.
    const userDocument = {
      uid: userRecord.uid,
      studentId,
      name: userRecord.displayName || name,
      email: userRecord.email || email,
      role,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await users.insertOne(userDocument);

    return {
      uid: userRecord.uid,
      studentId,
      name: userRecord.name || name,
      email: userRecord.email || email,
      role,
    };
  } catch (error) {
    // If Firebase account already exists.
    if (error.code === "auth/email-already-exists") {
      const err = new Error("Email already registered");
      err.statusCode = 409;
      throw err;
    }

    if (error.code === "auth/invalid-email") {
      const err = new Error("Invalid email address");
      err.statusCode = 400;
      throw err;
    }

    if (
      error.code === "auth/password-does-not-meet-requirements"
    ) {
      const err = new Error(
        "Password does not meet Firebase requirements"
      );
      err.statusCode = 400;
      throw err;
    }

    throw error;
  }
}

// ============================================================
// LOGIN USER
// ============================================================

async function loginUser({ studentId, email, password }) {
  const db = getDb();
  const users = db.collection("users");

  let loginEmail = email;
  let user = null;

  // If Student ID was entered, find the linked Firebase email.
  if (studentId) {
    user = await users.findOne({ studentId });

    if (!user) {
      const err = new Error("Invalid Student ID or password");
      err.statusCode = 401;
      throw err;
    }

    loginEmail = user.email;
  }

  if (!loginEmail) {
    const err = new Error("Student ID is required");
    err.statusCode = 400;
    throw err;
  }

  const apiKey = process.env.FIREBASE_WEB_API_KEY;

  if (!apiKey) {
    const err = new Error(
      "FIREBASE_WEB_API_KEY is not configured"
    );
    err.statusCode = 500;
    throw err;
  }

  const firebaseUrl =
    `https://identitytoolkit.googleapis.com/v1/` +
    `accounts:signInWithPassword?key=${apiKey}`;

  const response = await fetch(firebaseUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      email: loginEmail,
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
      message === "INVALID_LOGIN_CREDENTIALS"
    ) {
      const err = new Error(
        "Invalid Student ID or password"
      );
      err.statusCode = 401;
      throw err;
    }

    if (message === "USER_DISABLED") {
      const err = new Error("User account is disabled");
      err.statusCode = 403;
      throw err;
    }

    const err = new Error(
      "Firebase authentication failed"
    );
    err.statusCode = 401;
    throw err;
  }

  return {
    uid: data.localId,
    studentId: user?.studentId || studentId || null,
    name: user?.name || "",
    role: user?.role || "Student",
    email: data.email,
    idToken: data.idToken,
    refreshToken: data.refreshToken,
    expiresIn: data.expiresIn,
  };
}

module.exports = {
  registerUser,
  loginUser,
};