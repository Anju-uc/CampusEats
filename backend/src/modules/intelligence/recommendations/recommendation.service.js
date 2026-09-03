const { getDb } = require("../../../config/mongodb");
const { generateRecommendations } = require("./recommendation.engine");

async function getRecommendations(userId) {
  const db = getDb();

  const cart = await db.collection("carts").findOne({
    userId,
  });

  const excludedItemIds = cart?.items?.map(
    (item) => item.menuItemId
  ) || [];

  const menuItems = await db
    .collection("menu")
    .find({
      available: true,
    })
    .toArray();

  return generateRecommendations(
    menuItems,
    excludedItemIds
  );
}

module.exports = {
  getRecommendations,
};