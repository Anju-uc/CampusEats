const { ObjectId } = require("mongodb");
const { getDb } = require("../../config/mongodb");

const COLLECTION_NAME = "menu";

function getCollection() {
  return getDb().collection(COLLECTION_NAME);
}

function isValidObjectId(id) {
  return ObjectId.isValid(id);
}

async function getAllMenuItems() {
  return getCollection()
    .find({})
    .sort({ createdAt: -1 })
    .toArray();
}

async function getAvailableMenuItems() {
  return getCollection()
    .find({ available: true })
    .sort({ createdAt: -1 })
    .toArray();
}

async function getMenuItemById(id) {
  if (!isValidObjectId(id)) {
    const error = new Error("Invalid menu item ID");
    error.statusCode = 400;
    throw error;
  }

  const item = await getCollection().findOne({
    _id: new ObjectId(id),
  });

  if (!item) {
    const error = new Error("Menu item not found");
    error.statusCode = 404;
    throw error;
  }

  return item;
}

async function createMenuItem({ name, description, price, category, imageUrl, available }) {
  const now = new Date();

  const item = {
    name,
    description: description || "",
    price: Number(price),
    category,
    imageUrl: imageUrl || "",
    available: available !== undefined ? Boolean(available) : true,
    createdAt: now,
    updatedAt: now,
  };

  const result = await getCollection().insertOne(item);

  return {
    _id: result.insertedId,
    ...item,
  };
}

async function updateMenuItem(id, updates) {
  if (!isValidObjectId(id)) {
    const error = new Error("Invalid menu item ID");
    error.statusCode = 400;
    throw error;
  }

  const allowedFields = [
    "name",
    "description",
    "price",
    "category",
    "imageUrl",
    "available",
  ];

  const updateData = {};

  for (const field of allowedFields) {
    if (updates[field] !== undefined) {
      updateData[field] =
        field === "price"
          ? Number(updates[field])
          : field === "available"
            ? Boolean(updates[field])
            : updates[field];
    }
  }

  updateData.updatedAt = new Date();

  const result = await getCollection().findOneAndUpdate(
    { _id: new ObjectId(id) },
    { $set: updateData },
    { returnDocument: "after" }
  );

  if (!result) {
    const error = new Error("Menu item not found");
    error.statusCode = 404;
    throw error;
  }

  return result;
}

async function deleteMenuItem(id) {
  if (!isValidObjectId(id)) {
    const error = new Error("Invalid menu item ID");
    error.statusCode = 400;
    throw error;
  }

  const result = await getCollection().deleteOne({
    _id: new ObjectId(id),
  });

  if (result.deletedCount === 0) {
    const error = new Error("Menu item not found");
    error.statusCode = 404;
    throw error;
  }

  return {
    deleted: true,
    id,
  };
}

module.exports = {
  getAllMenuItems,
  getAvailableMenuItems,
  getMenuItemById,
  createMenuItem,
  updateMenuItem,
  deleteMenuItem,
};