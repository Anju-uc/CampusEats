const { ObjectId } = require("mongodb");
const { getDb } = require("../../config/mongodb");

const CART_COLLECTION = "carts";
const MENU_COLLECTION = "menu";

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
    const menuItem = await getMenuCollection().findOne({
      _id: cartItem.menuItemId,
    });

    if (menuItem) {
      items.push({
        menuItemId: menuItem._id,
        name: menuItem.name,
        price: menuItem.price,
        quantity: cartItem.quantity,
        subtotal: menuItem.price * cartItem.quantity,
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

module.exports = {
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
};