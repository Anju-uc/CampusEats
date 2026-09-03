require("dotenv").config();

const app = require("./app");
const { connectMongoDB } = require("./config/mongodb");
const config = require("./config/env");

async function startServer() {
  try {
    await connectMongoDB();

    app.listen(config.port, () => {
      console.log(
        `CampusEATS backend running on http://localhost:${config.port}`
      );
    });
  } catch (error) {
    console.error("Failed to start server:", error.message);
    process.exit(1);
  }
}

startServer();