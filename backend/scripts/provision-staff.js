const readline = require("node:readline");
const { connectMongoDB, closeMongoDB } = require("../src/config/mongodb");
const { provisionStaffUser } = require("../src/modules/auth/auth.service");
const { ROLES } = require("../src/common/constants/roles");

function promptSecure(query) {
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
  const args = process.argv.slice(2);
  const getArg = (name) => {
    const prefix = `--${name}=`;
    const arg = args.find((a) => a.startsWith(prefix));
    return arg ? arg.substring(prefix.length) : process.env[name.toUpperCase()];
  };

  const email = getArg("email") || getArg("staffId");
  let password = getArg("password");
  const role = getArg("role") || ROLES.ADMIN;
  const name = getArg("name");
  const cafeteria = getArg("cafeteria") || "Bengaluru Cafe";

  if (!email) {
    console.error(
      "Usage: node scripts/provision-staff.js --email=<email> [--password=<password>] [--role=<Admin|Kitchen|Faculty>] [--name=<name>] [--cafeteria=<cafeteria>]"
    );
    process.exit(1);
  }

  if (!password) {
    password = await promptSecure(`Enter secure password for ${email}: `);
    if (!password) {
      console.error("Password cannot be empty.");
      process.exit(1);
    }
  }

  try {
    await connectMongoDB();
    console.log(`Provisioning ${role} account for: ${email}...`);

    const result = await provisionStaffUser({
      email,
      staffId: email,
      password,
      name,
      role,
      cafeteria,
    });

    console.log("Successfully provisioned staff account:", {
      uid: result.uid,
      email: result.email,
      name: result.name,
      role: result.role,
      cafeteria: result.cafeteria,
      status: result.status,
    });
  } catch (error) {
    console.error("Provisioning failed:", error.message);
    process.exit(1);
  } finally {
    await closeMongoDB();
  }
}

if (require.main === module) {
  main();
}

module.exports = { main };
