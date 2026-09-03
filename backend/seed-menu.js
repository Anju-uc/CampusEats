const { connectMongoDB, getDb, closeMongoDB } = require("./src/config/mongodb");

const menuItems = [
  {
    name: "Masala Dosa",
    description: "Crispy dosa served with potato masala, sambar and chutney",
    price: 60,
    category: "South Indian",
    imageUrl: "",
    available: true,
  },
  {
    name: "Idli Vada",
    description: "Soft idlis with crispy vada, sambar and chutney",
    price: 50,
    category: "South Indian",
    imageUrl: "",
    available: true,
  },
  {
    name: "Paneer Rice",
    description: "Flavoured rice with paneer and vegetables",
    price: 90,
    category: "Rice",
    imageUrl: "",
    available: true,
  },
  {
    name: "Veg Fried Rice",
    description: "Fried rice with fresh vegetables",
    price: 80,
    category: "Rice",
    imageUrl: "",
    available: true,
  },
  {
    name: "Veg Noodles",
    description: "Stir-fried noodles with vegetables",
    price: 75,
    category: "Chinese",
    imageUrl: "",
    available: true,
  },
  {
    name: "Samosa",
    description: "Crispy potato-filled samosa",
    price: 25,
    category: "Snacks",
    imageUrl: "",
    available: true,
  },
  {
    name: "Veg Sandwich",
    description: "Grilled sandwich with vegetables and cheese",
    price: 55,
    category: "Snacks",
    imageUrl: "",
    available: true,
  },
  {
    name: "French Fries",
    description: "Crispy golden potato fries",
    price: 65,
    category: "Snacks",
    imageUrl: "",
    available: true,
  },
  {
    name: "Mango Lassi",
    description: "Sweet chilled mango lassi",
    price: 60,
    category: "Beverages",
    imageUrl: "",
    available: true,
  },
  {
    name: "Fresh Lime Soda",
    description: "Refreshing lime soda",
    price: 40,
    category: "Beverages",
    imageUrl: "",
    available: true,
  },
  {
    name: "Cold Coffee",
    description: "Chilled creamy coffee",
    price: 70,
    category: "Beverages",
    imageUrl: "",
    available: true,
  },
  {
    name: "Gulab Jamun",
    description: "Soft gulab jamun served warm",
    price: 40,
    category: "Desserts",
    imageUrl: "",
    available: true,
  },
];

async function seedMenu() {
  try {
    await connectMongoDB();

    const db = getDb();
    const collection = db.collection("menu");

    const now = new Date();

    for (const item of menuItems) {
      await collection.updateOne(
        {
          name: item.name,
          category: item.category,
        },
        {
          $set: {
            ...item,
            updatedAt: now,
          },
          $setOnInsert: {
            createdAt: now,
          },
        },
        {
          upsert: true,
        }
      );
    }

    const count = await collection.countDocuments();

    console.log(`Menu seed completed successfully.`);
    console.log(`Menu documents currently in database: ${count}`);

    const items = await collection
      .find({})
      .sort({ createdAt: 1 })
      .toArray();

    console.log(items);

  } catch (error) {
    console.error("Menu seed failed:", error);
    process.exitCode = 1;
  } finally {
    await closeMongoDB();
  }
}

seedMenu();