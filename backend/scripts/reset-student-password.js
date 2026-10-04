require("dotenv").config();
const readline = require("node:readline");
const { auth } = require("../src/config/firebase");

function getInternalFirebaseEmail(studentId) {
  const normalizedId = (studentId || "").trim().toUpperCase().replace(/\s+/g, "");
  const encodedId = Buffer.from(normalizedId).toString("base64url");
  return `${encodedId}@students.campuseats.internal`;
}

async function findStudentUser(identifier) {
  // If identifier looks like an SRN
  if (identifier && !identifier.includes("@") && identifier.length < 20) {
    const email = getInternalFirebaseEmail(identifier);
    try {
      return await auth.getUserByEmail(email);
    } catch (_) { }
  }

  // Try direct email
  if (identifier && identifier.includes("@")) {
    try {
      return await auth.getUserByEmail(identifier);
    } catch (_) { }
  }

  // Try direct UID
  if (identifier) {
    try {
      return await auth.getUser(identifier);
    } catch (_) { }
  }

  // Or search users list for active student
  const list = await auth.listUsers(10);
  const student = list.users.find((u) =>
    u.email?.endsWith("@students.campuseats.internal")
  );
  if (student) return student;

  throw new Error("Student Firebase account not found");
}

function promptHidden(query) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(query, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

async function main() {
  try {
    const targetIdentifier = process.argv[2];
    const user = await findStudentUser(targetIdentifier);

    console.log("Found existing student account in Firebase Authentication.");
    console.log(`Display Name: ${user.displayName || "Student"}`);
    console.log(`Account Status: ${user.disabled ? "DISABLED" : "ENABLED"}`);

    const newPassword = await promptHidden("Enter New Password (minimum 6 characters): ");

    if (!newPassword || newPassword.length < 6) {
      console.error("Error: Password must be at least 6 characters long.");
      process.exit(1);
    }

    const confirmPassword = await promptHidden("Confirm New Password: ");

    if (newPassword !== confirmPassword) {
      console.error("Error: Passwords do not match.");
      process.exit(1);
    }

    // Update ONLY password
    await auth.updateUser(user.uid, {
      password: newPassword,
    });

    // Verify user is still enabled
    const updatedUser = await auth.getUser(user.uid);

    console.log("\n==========================================");
    console.log("PASSWORD RESET STATUS: SUCCESS");
    console.log(`Firebase Account Enabled: ${!updatedUser.disabled}`);
    console.log("UID: [PROTECTED]");
    console.log("==========================================");

    process.exit(0);
  } catch (err) {
    console.error("\nPASSWORD RESET FAILED:", err.message);
    process.exit(1);
  }
}

main();
