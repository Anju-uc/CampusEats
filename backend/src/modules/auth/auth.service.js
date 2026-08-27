const { auth } = require("../../config/firebase");

async function registerUser({ name, email, password }) {
  try {
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: name,
      emailVerified: false,
    });

    return {
      uid: userRecord.uid,
      name: userRecord.displayName,
      email: userRecord.email,
    };
  } catch (error) {
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

    if (error.code === "auth/password-does-not-meet-requirements") {
      const err = new Error("Password does not meet Firebase requirements");
      err.statusCode = 400;
      throw err;
    }

    throw error;
  }
}

async function loginUser({ email, password }) {
  const apiKey = process.env.FIREBASE_WEB_API_KEY;

  if (!apiKey) {
    const err = new Error("FIREBASE_WEB_API_KEY is not configured");
    err.statusCode = 500;
    throw err;
  }

  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true,
      }),
    }
  );

  const data = await response.json();

  if (!response.ok) {
    const message = data?.error?.message;

    if (message === "EMAIL_NOT_FOUND" || message === "INVALID_PASSWORD") {
      const err = new Error("Invalid email or password");
      err.statusCode = 401;
      throw err;
    }

    if (message === "USER_DISABLED") {
      const err = new Error("User account is disabled");
      err.statusCode = 403;
      throw err;
    }

    const err = new Error("Firebase authentication failed");
    err.statusCode = 401;
    throw err;
  }

  return {
    uid: data.localId,
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