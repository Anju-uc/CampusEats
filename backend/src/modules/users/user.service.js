const { auth } = require("../../config/firebase");

async function getUserByUid(uid) {
  const userRecord = await auth.getUser(uid);

  return {
    uid: userRecord.uid,
    name: userRecord.displayName || "",
    email: userRecord.email || "",
    phoneNumber: userRecord.phoneNumber || "",
    photoURL: userRecord.photoURL || "",
    emailVerified: userRecord.emailVerified,
  };
}

async function updateUserProfile(uid, updates) {
  const allowedUpdates = {};

  if (updates.name !== undefined) {
    allowedUpdates.displayName = updates.name;
  }

  if (updates.phoneNumber !== undefined) {
    allowedUpdates.phoneNumber = updates.phoneNumber;
  }

  if (updates.photoURL !== undefined) {
    allowedUpdates.photoURL = updates.photoURL;
  }

  const updatedUser = await auth.updateUser(uid, allowedUpdates);

  return {
    uid: updatedUser.uid,
    name: updatedUser.displayName || "",
    email: updatedUser.email || "",
    phoneNumber: updatedUser.phoneNumber || "",
    photoURL: updatedUser.photoURL || "",
    emailVerified: updatedUser.emailVerified,
  };
}

module.exports = {
  getUserByUid,
  updateUserProfile,
};