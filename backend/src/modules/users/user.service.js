const { auth } = require("../../config/firebase");
const { getDb } = require("../../config/mongodb");

async function getUserByUid(uid) {
  const user = await getDb().collection("users").findOne({ uid });

  if (!user) {
    const error = new Error("User not found");
    error.statusCode = 404;
    throw error;
  }

  return {
    uid: user.uid,
    studentId: user.studentId,
    name: user.name || "",
    program: user.program,
    status: user.status,
    role: user.role,
  };
}

async function updateUserProfile(uid, updates) {
  const allowedUpdates = {};

  if (updates.name !== undefined) {
    if (typeof updates.name !== "string" || updates.name.trim().length < 2) {
      const error = new Error("A valid name is required");
      error.statusCode = 400;
      throw error;
    }
    allowedUpdates.displayName = updates.name;
  }

  if (updates.phoneNumber !== undefined) {
    allowedUpdates.phoneNumber = updates.phoneNumber;
  }

  if (updates.photoURL !== undefined) {
    allowedUpdates.photoURL = updates.photoURL;
  }

  const updatedUser = await auth.updateUser(uid, allowedUpdates);

  if (updates.name !== undefined) {
    await getDb().collection("users").updateOne(
      { uid },
      { $set: { name: updates.name.trim(), updatedAt: new Date() } }
    );
  }

  return {
    uid: updatedUser.uid,
    name: updatedUser.displayName || "",
    phoneNumber: updatedUser.phoneNumber || "",
    photoURL: updatedUser.photoURL || "",
    emailVerified: updatedUser.emailVerified,
  };
}

module.exports = {
  getUserByUid,
  updateUserProfile,
};