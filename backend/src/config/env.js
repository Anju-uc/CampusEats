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

  razorpay: {
    keyId: process.env.RAZORPAY_KEY_ID,
    keySecret: process.env.RAZORPAY_KEY_SECRET,
    webhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET,
  },

  cashfree: {
    clientId: process.env.CASHFREE_CLIENT_ID || process.env.CASHFREE_APP_ID,
    clientSecret: process.env.CASHFREE_CLIENT_SECRET || process.env.CASHFREE_SECRET_KEY,
    environment: process.env.CASHFREE_ENV || "sandbox",
    apiVersion: process.env.CASHFREE_API_VERSION || "2025-01-01",
  },
};

module.exports = config;