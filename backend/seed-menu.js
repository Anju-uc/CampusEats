const { connectMongoDB, getDb, closeMongoDB } = require("./src/config/mongodb");

const menuItems = [
  {
    name: "Masala Dosa",
    description: "Crispy dosa served with potato masala, sambar and chutney",
    price: 60,
    category: "South Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Dosa Special",
    description: "Special ghee roast dosa with potato masala and chutneys",
    price: 60,
    category: "South Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Idli",
    description: "Soft steamed idlis served with chutney and sambar",
    price: 30,
    category: "South Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Vada",
    description: "Crispy South Indian medu vada",
    price: 25,
    category: "South Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Idli Vada",
    description: "Soft idlis with crispy vada, sambar and chutney",
    price: 50,
    category: "South Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Set Dosa",
    description: "Soft and fluffy set dosa served with sagu and chutney",
    price: 50,
    category: "South Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Puri",
    description: "Hot fluffy puris served with potato sagu",
    price: 40,
    category: "South Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Bisi Bele Bath",
    description: "Traditional Karnataka-style spicy rice meal with boondi",
    price: 70,
    category: "South Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Lemon Rice",
    description: "Fresh lemon rice with peanuts and spices",
    price: 55,
    category: "South Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Chole Bhature",
    description: "Fluffy bhature served with spicy chole masala",
    price: 90,
    category: "North Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Chicken Biryani",
    description: "Aromatic basmati rice cooked with tender chicken and spices",
    price: 120,
    category: "Non-Veg",
    cafeteria: "Non-Veg Cafeteria",
    imageUrl: "",
    available: true,
  },
  {
    name: "Veg Biryani",
    description: "Spiced basmati rice with mixed vegetables and raita",
    price: 90,
    category: "Rice",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Paneer Rice",
    description: "Flavoured rice with paneer and vegetables",
    price: 90,
    category: "Rice",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Paneer Butter Masala",
    description: "Cottage cheese cubes in rich tomato cashew gravy",
    price: 110,
    category: "North Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Butter Naan",
    description: "Freshly baked tandoori naan brushed with butter",
    price: 35,
    category: "North Indian",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Veg Fried Rice",
    description: "Fried rice with fresh vegetables",
    price: 80,
    category: "Chinese",
    cafeteria: "Cafe PESU",
    imageUrl: "",
    available: true,
  },
  {
    name: "Veg Noodles",
    description: "Stir-fried noodles with vegetables",
    price: 75,
    category: "Chinese",
    cafeteria: "Cafe PESU",
    imageUrl: "",
    available: true,
  },
  {
    name: "Chicken Burger",
    description: "Crispy chicken patty burger with lettuce and mayo",
    price: 85,
    category: "Fast Food",
    cafeteria: "Cafe PESU",
    imageUrl: "",
    available: true,
  },
  {
    name: "Veg Burger",
    description: "Crispy vegetable patty burger with fresh veggies",
    price: 65,
    category: "Fast Food",
    cafeteria: "Cafe PESU",
    imageUrl: "",
    available: true,
  },
  {
    name: "Veg Pizza",
    description: "Cheesy pizza topped with capsicum, onion, and corn",
    price: 120,
    category: "Fast Food",
    cafeteria: "Cafe PESU",
    imageUrl: "",
    available: true,
  },
  {
    name: "French Fries",
    description: "Crispy golden potato fries",
    price: 60,
    category: "Snacks",
    cafeteria: "Cafe PESU",
    imageUrl: "",
    available: true,
  },
  {
    name: "Samosa",
    description: "Crispy potato-filled samosa",
    price: 25,
    category: "Snacks",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Veg Sandwich",
    description: "Grilled sandwich with vegetables and cheese",
    price: 55,
    category: "Snacks",
    cafeteria: "Cafe PESU",
    imageUrl: "",
    available: true,
  },
  {
    name: "Filter Coffee",
    description: "Authentic South Indian filter coffee",
    price: 30,
    category: "Beverages",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Cold Coffee",
    description: "Chilled creamy coffee",
    price: 50,
    category: "Beverages",
    cafeteria: "Cafe PESU",
    imageUrl: "",
    available: true,
  },
  {
    name: "Chai",
    description: "Hot brewed Indian spiced tea",
    price: 15,
    category: "Beverages",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Chocolate Shake",
    description: "Rich chocolate milkshake with ice cream",
    price: 70,
    category: "Beverages",
    cafeteria: "Cafe PESU",
    imageUrl: "",
    available: true,
  },
  {
    name: "Mango Lassi",
    description: "Sweet chilled mango lassi",
    price: 60,
    category: "Beverages",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Fresh Lime Soda",
    description: "Refreshing lime soda",
    price: 35,
    category: "Beverages",
    cafeteria: "Bengaluru Cafe",
    imageUrl: "",
    available: true,
  },
  {
    name: "Gulab Jamun",
    description: "Soft gulab jamun served warm",
    price: 40,
    category: "Desserts",
    cafeteria: "Bengaluru Cafe",
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