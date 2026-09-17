require("dotenv").config();

const config = {
  port: Number(process.env.PORT) || 5000,

  cors: {
    origins: (process.env.CORS_ORIGINS ||
      "http://localhost:3000,http://localhost:5000,http://127.0.0.1:3000,http://127.0.0.1:5000")
      .split(",")
      .map((origin) => origin.trim())
      .filter(Boolean),
  },

  mongodb: {
    uri: process.env.MONGODB_URI,
    dbName: process.env.MONGODB_DB_NAME,
  },

  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY
      ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n")
      : undefined,
    databaseURL: process.env.FIREBASE_DATABASE_URL,
  },
};

module.exports = config;