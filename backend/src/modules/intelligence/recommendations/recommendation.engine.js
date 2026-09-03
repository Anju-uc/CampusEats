function generateRecommendations(menuItems, excludedItemIds = []) {
    const excluded = new Set(
      excludedItemIds.map((id) => id.toString())
    );
  
    return menuItems
      .filter((item) => {
        if (!item.available) {
          return false;
        }
  
        return !excluded.has(item._id.toString());
      })
      .sort((a, b) => {
        if (a.category === b.category) {
          return a.price - b.price;
        }
  
        return a.category.localeCompare(b.category);
      })
      .slice(0, 5);
  }
  
  module.exports = {
    generateRecommendations,
  };