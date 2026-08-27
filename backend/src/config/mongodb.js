const { MongoClient } = require("mongodb");
const config = require("./env");

let client;
let db;

async function connectMongoDB() {
  if (!config.mongodb.uri) {
    throw new Error("MONGODB_URI is not configured");
  }

  client = new MongoClient(config.mongodb.uri, {
    family: 4,
  });

  await client.connect();

  db = client.db(config.mongodb.dbName);

  await db.command({ ping: 1 });

  console.log("MongoDB connected successfully");

  return db;
}

function getDb() {
  if (!db) {
    throw new Error("MongoDB is not connected");
  }

  return db;
}

async function closeMongoDB() {
  if (client) {
    await client.close();
    client = null;
    db = null;
  }
}

module.exports = {
  connectMongoDB,
  getDb,
  closeMongoDB,
};