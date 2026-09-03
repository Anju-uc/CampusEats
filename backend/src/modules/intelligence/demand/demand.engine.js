function calculateDemand(orders) {
    const demandMap = new Map();
  
    for (const order of orders) {
      for (const item of order.items || []) {
        const key = item.menuItemId.toString();
  
        if (!demandMap.has(key)) {
          demandMap.set(key, {
            menuItemId: item.menuItemId,
            name: item.name,
            quantitySold: 0,
            revenue: 0,
          });
        }
  
        const entry = demandMap.get(key);
  
        entry.quantitySold += item.quantity;
        entry.revenue += item.subtotal;
      }
    }
  
    return [...demandMap.values()]
      .sort((a, b) => b.quantitySold - a.quantitySold);
  }
  
  module.exports = {
    calculateDemand,
  };