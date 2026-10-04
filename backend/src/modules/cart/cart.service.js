const { ObjectId } = require("mongodb");
const { getDb } = require("../../config/mongodb");

const CART_COLLECTION = "carts";
const MENU_COLLECTION = "menu";
const MAX_CART_QUANTITY = 99;

function validateQuantity(quantity) {
  if (!Number.isInteger(quantity) || quantity < 1 || quantity > MAX_CART_QUANTITY) {
    const error = new Error(`quantity must be an integer from 1 to ${MAX_CART_QUANTITY}`);
    error.statusCode = 400;
    throw error;
  }
}

function getCartCollection() {
  return getDb().collection(CART_COLLECTION);
}

function getMenuCollection() {
  return getDb().collection(MENU_COLLECTION);
}

function validateObjectId(id) {
  if (!ObjectId.isValid(id)) {
    const error = new Error("Invalid menu item ID");
    error.statusCode = 400;
    throw error;
  }
}

function escapeRegex(string) {
  return String(string).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

async function getCart(userId) {
  const cart = await getCartCollection().findOne({ userId });

  if (!cart) {
    return {
      userId,
      items: [],
      total: 0,
    };
  }

  const items = [];

  for (const cartItem of cart.items || []) {
    let menuItem = null;
    if (cartItem.menuItemId && ObjectId.isValid(String(cartItem.menuItemId))) {
      menuItem = await getMenuCollection().findOne({
        _id: new ObjectId(String(cartItem.menuItemId)),
      });
    }

    if (!menuItem && cartItem.menuItemId) {
      menuItem = await getMenuCollection().findOne({
        $or: [
          { id: String(cartItem.menuItemId) },
          { menuItemId: String(cartItem.menuItemId) },
        ],
      });
    }

    if (!menuItem && cartItem.name) {
      const escaped = escapeRegex(String(cartItem.name).trim());
      menuItem = await getMenuCollection().findOne({
        name: { $regex: new RegExp(`^${escaped}$`, "i") },
      });
    }

    if (menuItem) {
      const price = Number(menuItem.price);
      const quantity = Number(cartItem.quantity) || 1;
      items.push({
        menuItemId: menuItem._id,
        name: menuItem.name,
        price,
        quantity,
        subtotal: price * quantity,
        cafeteria: menuItem.cafeteria || cartItem.cafeteria || "Bengaluru Cafe",
        imageUrl: menuItem.imageUrl || cartItem.imageUrl || "",
      });
    } else if (cartItem.name && (cartItem.price !== undefined || cartItem.price === 0)) {
      const price = Number(cartItem.price) || 0;
      const quantity = Number(cartItem.quantity) || 1;
      items.push({
        menuItemId: cartItem.menuItemId || `item_${cartItem.name}`,
        name: cartItem.name,
        price,
        quantity,
        subtotal: price * quantity,
        cafeteria: cartItem.cafeteria || "Bengaluru Cafe",
        imageUrl: cartItem.imageUrl || "",
      });
    }
  }

  const total = items.reduce((sum, item) => sum + item.subtotal, 0);

  return {
    userId,
    items,
    total,
  };
}

async function addToCart(userId, menuItemId, quantity) {
  validateQuantity(quantity);
  validateObjectId(menuItemId);

  const menuItem = await getMenuCollection().findOne({
    _id: new ObjectId(menuItemId),
  });

  if (!menuItem) {
    const error = new Error("Menu item not found");
    error.statusCode = 404;
    throw error;
  }

  if (!menuItem.available) {
    const error = new Error("Menu item is not available");
    error.statusCode = 400;
    throw error;
  }

  const cart = await getCartCollection().findOne({ userId });

  if (!cart) {
    await getCartCollection().insertOne({
      userId,
      items: [
        {
          menuItemId: new ObjectId(menuItemId),
          quantity,
        },
      ],
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  } else {
    const existingItem = cart.items.find(
      (item) => item.menuItemId.toString() === menuItemId
    );

    if (existingItem) {
      await getCartCollection().updateOne(
        {
          userId,
          "items.menuItemId": new ObjectId(menuItemId),
        },
        {
          $inc: {
            "items.$.quantity": quantity,
          },
          $set: {
            updatedAt: new Date(),
          },
        }
      );
    } else {
      await getCartCollection().updateOne(
        { userId },
        {
          $push: {
            items: {
              menuItemId: new ObjectId(menuItemId),
              quantity,
            },
          },
          $set: {
            updatedAt: new Date(),
          },
        }
      );
    }
  }

  return getCart(userId);
}

async function updateCartItem(userId, menuItemId, quantity) {
  validateQuantity(quantity);
  validateObjectId(menuItemId);

  const menuItem = await getMenuCollection().findOne({
    _id: new ObjectId(menuItemId),
  });

  if (!menuItem) {
    const error = new Error("Menu item not found");
    error.statusCode = 404;
    throw error;
  }

  const result = await getCartCollection().updateOne(
    {
      userId,
      "items.menuItemId": new ObjectId(menuItemId),
    },
    {
      $set: {
        "items.$.quantity": quantity,
        updatedAt: new Date(),
      },
    }
  );

  if (result.matchedCount === 0) {
    const error = new Error("Cart item not found");
    error.statusCode = 404;
    throw error;
  }

  return getCart(userId);
}

async function removeFromCart(userId, menuItemId) {
  validateObjectId(menuItemId);

  const result = await getCartCollection().updateOne(
    { userId },
    {
      $pull: {
        items: {
          menuItemId: new ObjectId(menuItemId),
        },
      },
      $set: {
        updatedAt: new Date(),
      },
    }
  );

  if (result.matchedCount === 0) {
    const error = new Error("Cart not found");
    error.statusCode = 404;
    throw error;
  }

  return getCart(userId);
}

async function clearCart(userId) {
  await getCartCollection().updateOne(
    { userId },
    {
      $set: {
        items: [],
        updatedAt: new Date(),
      },
    },
    { upsert: true }
  );

  return getCart(userId);
}

async function syncCart(userId, items = []) {
  const validItems = [];
  if (Array.isArray(items)) {
    for (const item of items) {
      if (!item) continue;
      const rawId = item.menuItemId || item.backendMenuItemId || item.id || item._id;
      let menuItem = null;

      if (rawId && ObjectId.isValid(String(rawId))) {
        menuItem = await getMenuCollection().findOne({
          _id: new ObjectId(String(rawId)),
        });
      }

      if (!menuItem && rawId) {
        menuItem = await getMenuCollection().findOne({
          $or: [
            { id: String(rawId) },
            { menuItemId: String(rawId) },
            { itemId: String(rawId) },
          ],
        });
      }

      if (!menuItem && item.name) {
        const escaped = escapeRegex(String(item.name).trim());
        menuItem = await getMenuCollection().findOne({
          name: { $regex: new RegExp(`^${escaped}$`, "i") },
        });
      }

      const quantity = Math.max(
        1,
        Math.min(Number(item.quantity) || 1, MAX_CART_QUANTITY)
      );

      if (menuItem) {
        if (menuItem.available !== false) {
          validItems.push({
            menuItemId: menuItem._id,
            name: menuItem.name,
            price: Number(menuItem.price),
            quantity,
            cafeteria: menuItem.cafeteria || item.cafeteria || "Bengaluru Cafe",
          });
        }
      } else if (item.name && (Number(item.price) > 0 || item.price === 0)) {
        validItems.push({
          menuItemId: rawId ? String(rawId) : `item_${String(item.name).trim().toLowerCase().replace(/\s+/g, "_")}`,
          name: String(item.name).trim(),
          price: Number(item.price) || 0,
          quantity,
          cafeteria: item.cafeteria || "Bengaluru Cafe",
        });
      }
    }
  }

  const now = new Date();
  await getCartCollection().updateOne(
    { userId },
    {
      $set: {
        items: validItems,
        updatedAt: now,
      },
      $setOnInsert: {
        createdAt: now,
      },
    },
    { upsert: true }
  );

  return getCart(userId);
}

module.exports = {
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
  syncCart,
};