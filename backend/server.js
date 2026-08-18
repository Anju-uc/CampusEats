const express = require("express");
const cors = require("cors");
const Database = require("better-sqlite3");

const app = express();

app.use(cors());
app.use(express.json());

// =====================================================
// DATABASE
// =====================================================

const db = new Database("campuseats.db");

console.log("✅ Database connected");

// =====================================================
// ORDERS TABLE
// =====================================================

db.prepare(`
  CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_name TEXT,
    student_email TEXT,
    items TEXT NOT NULL,
    total_amount REAL NOT NULL,
    status TEXT DEFAULT 'Confirmed',
    payment_status TEXT DEFAULT 'Pending',
    created_at TEXT NOT NULL
  )
`).run();

// =====================================================
// MENU TABLE
// =====================================================

db.prepare(`
  CREATE TABLE IF NOT EXISTS menu (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    description TEXT DEFAULT '',
    category TEXT DEFAULT 'Other',
    image TEXT DEFAULT '',
    is_available INTEGER DEFAULT 1,
    created_at TEXT NOT NULL
  )
`).run();

console.log("✅ Menu table ready");

// =====================================================
// SEED DEFAULT MENU
// =====================================================
// Only adds these foods if the menu table is empty.
// Existing menu data will NOT be deleted.
// =====================================================

const menuCount = db
  .prepare(`SELECT COUNT(*) AS count FROM menu`)
  .get().count;

if (menuCount === 0) {
  const insertMenu = db.prepare(`
    INSERT INTO menu
    (
      name,
      price,
      description,
      category,
      image,
      is_available,
      created_at
    )
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `);

  const defaultFoods = [
    [
      "Idli",
      30,
      "Soft and fresh South Indian idli served with chutney.",
      "South Indian",
      "idli.jpg"
    ],
    [
      "Vada",
      25,
      "Crispy South Indian medu vada.",
      "South Indian",
      "vada.jpg"
    ],
    [
      "Masala Dosa",
      60,
      "Crispy dosa filled with delicious potato masala.",
      "South Indian",
      "masala_dosa.jpg"
    ],
    [
      "Set Dosa",
      50,
      "Soft and fluffy set dosa served with chutney.",
      "South Indian",
      "set_dosa.jpg"
    ],
    [
      "Puri",
      45,
      "Hot and crispy puri served with tasty curry.",
      "South Indian",
      "puri.jpg"
    ],
    [
      "Bisibele Bath",
      60,
      "Traditional Karnataka style bisibele bath.",
      "South Indian",
      "bisibele_bath.jpg"
    ],
    [
      "Lemon Rice",
      50,
      "Fresh lemon rice with South Indian spices.",
      "Rice",
      "lemon_rice.jpg"
    ],
    [
      "Chole Bhature",
      80,
      "Spicy chole served with soft bhature.",
      "North Indian",
      "chole_bhature.jpg"
    ],
    [
      "Chicken Biryani",
      150,
      "Aromatic chicken biryani with flavorful spices.",
      "Non Veg",
      "chicken_biryani.jpg"
    ],
    [
      "Chicken 65",
      120,
      "Crispy spicy chicken starter.",
      "Non Veg",
      "chicken_65.jpg"
    ],
    [
      "Pizza",
      130,
      "Cheesy and delicious campus style pizza.",
      "Fast Food",
      "pizza.jpg"
    ],
    [
      "Burger",
      100,
      "Fresh burger with tasty fillings.",
      "Fast Food",
      "burger.jpg"
    ],
    [
      "Noodles",
      90,
      "Hot and tasty stir-fried noodles.",
      "Fast Food",
      "noodles.jpg"
    ],
    [
      "Coffee",
      30,
      "Fresh hot coffee.",
      "Beverages",
      "coffee.jpg"
    ],
    [
      "Cold Coffee",
      60,
      "Chilled creamy cold coffee.",
      "Beverages",
      "cold_coffee.jpg"
    ]
  ];

  const insertMany = db.transaction((foods) => {
    for (const food of foods) {
      insertMenu.run(
        food[0],
        food[1],
        food[2],
        food[3],
        food[4],
        1,
        new Date().toISOString()
      );
    }
  });

  insertMany(defaultFoods);

  console.log("✅ Default menu added");
}

// =====================================================
// TEST ROUTE
// =====================================================

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "🚀 CampusEATS Backend is Running!"
  });
});

// =====================================================
// GET MENU
// =====================================================

app.get("/menu", (req, res) => {
  try {
    const rows = db.prepare(`
      SELECT *
      FROM menu
      ORDER BY id ASC
    `).all();

    const menu = rows.map((food) => ({
      id: food.id,
      name: food.name,
      price: food.price,
      description: food.description,
      category: food.category,
      image: food.image,
      imagePath: food.image,
      isAvailable: Boolean(food.is_available),
      createdAt: food.created_at
    }));

    res.json({
      success: true,
      count: menu.length,
      menu: menu
    });

  } catch (error) {
    console.error("❌ Get menu error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to load menu"
    });
  }
});

// =====================================================
// ADD MENU ITEM
// =====================================================

app.post("/menu", (req, res) => {
  try {
    const {
      name,
      price,
      description,
      category,
      image,
      imagePath,
      isAvailable
    } = req.body;

    // -----------------------------
    // VALIDATION
    // -----------------------------

    if (!name || name.toString().trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Food name is required"
      });
    }

    if (price === undefined || price === null) {
      return res.status(400).json({
        success: false,
        message: "Food price is required"
      });
    }

    const numericPrice = Number(price);

    if (Number.isNaN(numericPrice) || numericPrice < 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid food price"
      });
    }

    // -----------------------------
    // IMAGE
    // -----------------------------

    const finalImage =
      image ||
      imagePath ||
      "";

    // -----------------------------
    // INSERT
    // -----------------------------

    const result = db.prepare(`
      INSERT INTO menu
      (
        name,
        price,
        description,
        category,
        image,
        is_available,
        created_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(
      name.toString().trim(),
      numericPrice,
      description
        ? description.toString().trim()
        : "",
      category
        ? category.toString().trim()
        : "Other",
      finalImage.toString(),
      isAvailable === false ? 0 : 1,
      new Date().toISOString()
    );

    // -----------------------------
    // GET CREATED FOOD
    // -----------------------------

    const food = db.prepare(`
      SELECT *
      FROM menu
      WHERE id = ?
    `).get(result.lastInsertRowid);

    res.status(201).json({
      success: true,
      message: "Food added successfully",
      food: {
        id: food.id,
        name: food.name,
        price: food.price,
        description: food.description,
        category: food.category,
        image: food.image,
        imagePath: food.image,
        isAvailable: Boolean(food.is_available),
        createdAt: food.created_at
      }
    });

  } catch (error) {
    console.error("❌ Add menu error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to add food"
    });
  }
});

// =====================================================
// UPDATE MENU ITEM
// =====================================================

app.put("/menu/:id", (req, res) => {
  try {
    const id = Number(req.params.id);

    const {
      name,
      price,
      description,
      category,
      image,
      imagePath,
      isAvailable
    } = req.body;

    // -----------------------------
    // CHECK FOOD
    // -----------------------------

    const existingFood = db.prepare(`
      SELECT *
      FROM menu
      WHERE id = ?
    `).get(id);

    if (!existingFood) {
      return res.status(404).json({
        success: false,
        message: "Food item not found"
      });
    }

    // -----------------------------
    // VALUES
    // -----------------------------

    const finalName =
      name !== undefined
        ? name.toString().trim()
        : existingFood.name;

    const finalPrice =
      price !== undefined
        ? Number(price)
        : existingFood.price;

    const finalDescription =
      description !== undefined
        ? description.toString().trim()
        : existingFood.description;

    const finalCategory =
      category !== undefined
        ? category.toString().trim()
        : existingFood.category;

    const finalImage =
      image !== undefined
        ? image.toString()
        : imagePath !== undefined
            ? imagePath.toString()
            : existingFood.image;

    const finalAvailability =
      isAvailable !== undefined
        ? isAvailable
          ? 1
          : 0
        : existingFood.is_available;

    // -----------------------------
    // VALIDATION
    // -----------------------------

    if (finalName === "") {
      return res.status(400).json({
        success: false,
        message: "Food name cannot be empty"
      });
    }

    if (
      Number.isNaN(finalPrice) ||
      finalPrice < 0
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid food price"
      });
    }

    // -----------------------------
    // UPDATE
    // -----------------------------

    db.prepare(`
      UPDATE menu
      SET
        name = ?,
        price = ?,
        description = ?,
        category = ?,
        image = ?,
        is_available = ?
      WHERE id = ?
    `).run(
      finalName,
      finalPrice,
      finalDescription,
      finalCategory,
      finalImage,
      finalAvailability,
      id
    );

    const updatedFood = db.prepare(`
      SELECT *
      FROM menu
      WHERE id = ?
    `).get(id);

    res.json({
      success: true,
      message: "Food updated successfully",
      food: {
        id: updatedFood.id,
        name: updatedFood.name,
        price: updatedFood.price,
        description: updatedFood.description,
        category: updatedFood.category,
        image: updatedFood.image,
        imagePath: updatedFood.image,
        isAvailable:
          Boolean(updatedFood.is_available),
        createdAt: updatedFood.created_at
      }
    });

  } catch (error) {
    console.error("❌ Update menu error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to update food"
    });
  }
});

// =====================================================
// DELETE MENU ITEM
// =====================================================

app.delete("/menu/:id", (req, res) => {
  try {
    const id = Number(req.params.id);

    const result = db.prepare(`
      DELETE FROM menu
      WHERE id = ?
    `).run(id);

    if (result.changes === 0) {
      return res.status(404).json({
        success: false,
        message: "Food item not found"
      });
    }

    res.json({
      success: true,
      message: "Food deleted successfully"
    });

  } catch (error) {
    console.error("❌ Delete menu error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to delete food"
    });
  }
});

// =====================================================
// UPDATE FOOD AVAILABILITY
// =====================================================

app.patch("/menu/:id/availability", (req, res) => {
  try {
    const id = Number(req.params.id);

    const { isAvailable } = req.body;

    if (typeof isAvailable !== "boolean") {
      return res.status(400).json({
        success: false,
        message: "isAvailable must be true or false"
      });
    }

    const result = db.prepare(`
      UPDATE menu
      SET is_available = ?
      WHERE id = ?
    `).run(
      isAvailable ? 1 : 0,
      id
    );

    if (result.changes === 0) {
      return res.status(404).json({
        success: false,
        message: "Food item not found"
      });
    }

    const food = db.prepare(`
      SELECT *
      FROM menu
      WHERE id = ?
    `).get(id);

    res.json({
      success: true,
      message: "Food availability updated",
      food: {
        id: food.id,
        name: food.name,
        isAvailable:
          Boolean(food.is_available)
      }
    });

  } catch (error) {
    console.error(
      "❌ Availability update error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Failed to update availability"
    });
  }
});

// =====================================================
// CAFETERIAS
// =====================================================

app.get("/cafeterias", (req, res) => {
  res.json({
    success: true,
    cafeterias: [
      {
        id: 1,
        name: "PESU Cafeteria 1",
        location: "Ring Road Campus"
      },
      {
        id: 2,
        name: "PESU Cafeteria 2",
        location: "Ring Road Campus"
      },
      {
        id: 3,
        name: "PESU Cafeteria 3",
        location: "Ring Road Campus"
      }
    ]
  });
});

// =====================================================
// PLACE ORDER
// =====================================================

app.post("/orders", (req, res) => {
  try {
    const {
      studentName,
      studentEmail,
      items,
      totalAmount,
      paymentStatus
    } = req.body;

    if (!items) {
      return res.status(400).json({
        success: false,
        message: "Order items are required"
      });
    }

    if (totalAmount === undefined) {
      return res.status(400).json({
        success: false,
        message: "Total amount is required"
      });
    }

    const createdAt =
      new Date().toISOString();

    const result = db.prepare(`
      INSERT INTO orders
      (
        student_name,
        student_email,
        items,
        total_amount,
        status,
        payment_status,
        created_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(
      studentName || "Student",
      studentEmail || "",
      JSON.stringify(items),
      Number(totalAmount),
      "Confirmed",
      paymentStatus || "Pending",
      createdAt
    );

    const order = db.prepare(`
      SELECT *
      FROM orders
      WHERE id = ?
    `).get(result.lastInsertRowid);

    res.status(201).json({
      success: true,
      message: "Order placed successfully",
      order: {
        id: order.id,
        studentName: order.student_name,
        studentEmail: order.student_email,
        items: JSON.parse(order.items),
        totalAmount: order.total_amount,
        status: order.status,
        paymentStatus: order.payment_status,
        createdAt: order.created_at
      }
    });

  } catch (error) {
    console.error("❌ Order error:", error);

    res.status(500).json({
      success: false,
      message: "Failed to place order"
    });
  }
});

// =====================================================
// GET ALL ORDERS
// =====================================================

app.get("/orders", (req, res) => {
  try {
    const rows = db.prepare(`
      SELECT *
      FROM orders
      ORDER BY id DESC
    `).all();

    const orders = rows.map((order) => ({
      id: order.id,
      studentName: order.student_name,
      studentEmail: order.student_email,
      items: JSON.parse(order.items),
      totalAmount: order.total_amount,
      status: order.status,
      paymentStatus: order.payment_status,
      createdAt: order.created_at
    }));

    res.json({
      success: true,
      count: orders.length,
      orders: orders
    });

  } catch (error) {
    console.error(
      "❌ Fetch orders error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Failed to fetch orders"
    });
  }
});

// =====================================================
// GET SINGLE ORDER
// =====================================================

app.get("/orders/:id", (req, res) => {
  try {
    const order = db.prepare(`
      SELECT *
      FROM orders
      WHERE id = ?
    `).get(req.params.id);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: "Order not found"
      });
    }

    res.json({
      success: true,
      order: {
        id: order.id,
        studentName: order.student_name,
        studentEmail: order.student_email,
        items: JSON.parse(order.items),
        totalAmount: order.total_amount,
        status: order.status,
        paymentStatus: order.payment_status,
        createdAt: order.created_at
      }
    });

  } catch (error) {
    console.error(
      "❌ Fetch order error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Failed to fetch order"
    });
  }
});

// =====================================================
// UPDATE ORDER STATUS
// =====================================================

app.put("/orders/:id/status", (req, res) => {
  try {
    const { status } = req.body;

    const allowedStatuses = [
      "Confirmed",
      "Preparing",
      "Ready",
      "Completed",
      "Cancelled"
    ];

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid order status"
      });
    }

    const result = db.prepare(`
      UPDATE orders
      SET status = ?
      WHERE id = ?
    `).run(
      status,
      req.params.id
    );

    if (result.changes === 0) {
      return res.status(404).json({
        success: false,
        message: "Order not found"
      });
    }

    const order = db.prepare(`
      SELECT *
      FROM orders
      WHERE id = ?
    `).get(req.params.id);

    res.json({
      success: true,
      message: "Order status updated",
      order: {
        id: order.id,
        status: order.status
      }
    });

  } catch (error) {
    console.error(
      "❌ Status update error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Failed to update order status"
    });
  }
});

// =====================================================
// ANALYTICS
// =====================================================

app.get("/analytics", (req, res) => {
  try {
    // ---------------------------------------------------
    // ALL TIME
    // ---------------------------------------------------

    const totalOrders = db.prepare(`
      SELECT COUNT(*) AS count
      FROM orders
    `).get().count;

    const totalRevenue = db.prepare(`
      SELECT COALESCE(
        SUM(total_amount),
        0
      ) AS revenue
      FROM orders
      WHERE status != 'Cancelled'
    `).get().revenue;

    // ---------------------------------------------------
    // TODAY
    // ---------------------------------------------------

    const todayRevenue = db.prepare(`
      SELECT COALESCE(
        SUM(total_amount),
        0
      ) AS revenue
      FROM orders
      WHERE status != 'Cancelled'
      AND date(created_at)
          = date('now', 'localtime')
    `).get().revenue;

    const todayOrders = db.prepare(`
      SELECT COUNT(*) AS count
      FROM orders
      WHERE date(created_at)
          = date('now', 'localtime')
    `).get().count;

    // ---------------------------------------------------
    // THIS WEEK
    // ---------------------------------------------------

    const weekRevenue = db.prepare(`
      SELECT COALESCE(
        SUM(total_amount),
        0
      ) AS revenue
      FROM orders
      WHERE status != 'Cancelled'
      AND date(created_at)
          >= date(
            'now',
            'localtime',
            '-6 days'
          )
    `).get().revenue;

    const weekOrders = db.prepare(`
      SELECT COUNT(*) AS count
      FROM orders
      WHERE date(created_at)
          >= date(
            'now',
            'localtime',
            '-6 days'
          )
    `).get().count;

    // ---------------------------------------------------
    // THIS MONTH
    // ---------------------------------------------------

    const monthRevenue = db.prepare(`
      SELECT COALESCE(
        SUM(total_amount),
        0
      ) AS revenue
      FROM orders
      WHERE status != 'Cancelled'
      AND date(created_at)
          >= date(
            'now',
            'localtime',
            'start of month'
          )
    `).get().revenue;

    const monthOrders = db.prepare(`
      SELECT COUNT(*) AS count
      FROM orders
      WHERE date(created_at)
          >= date(
            'now',
            'localtime',
            'start of month'
          )
    `).get().count;

    // ---------------------------------------------------
    // ORDER STATUS
    // ---------------------------------------------------

    const preparing = db.prepare(`
      SELECT COUNT(*) AS count
      FROM orders
      WHERE status = 'Preparing'
    `).get().count;

    const ready = db.prepare(`
      SELECT COUNT(*) AS count
      FROM orders
      WHERE status = 'Ready'
    `).get().count;

    const completed = db.prepare(`
      SELECT COUNT(*) AS count
      FROM orders
      WHERE status = 'Completed'
    `).get().count;

    const confirmed = db.prepare(`
      SELECT COUNT(*) AS count
      FROM orders
      WHERE status = 'Confirmed'
    `).get().count;

    // ---------------------------------------------------
    // RESPONSE
    // ---------------------------------------------------

    res.json({
      success: true,

      allTime: {
        orders: totalOrders,
        revenue: totalRevenue
      },

      today: {
        orders: todayOrders,
        revenue: todayRevenue
      },

      week: {
        orders: weekOrders,
        revenue: weekRevenue
      },

      month: {
        orders: monthOrders,
        revenue: monthRevenue
      },

      status: {
        confirmed: confirmed,
        preparing: preparing,
        ready: ready,
        completed: completed
      }
    });

  } catch (error) {
    console.error(
      "❌ Analytics error:",
      error
    );

    res.status(500).json({
      success: false,
      message: "Failed to load analytics"
    });
  }
});

// =====================================================
// SERVER
// =====================================================

const PORT = 5000;

app.listen(PORT, () => {
  console.log("======================================");
  console.log("🚀 CampusEATS Backend Started");
  console.log(`🌐 http://localhost:${PORT}`);
  console.log("📋 Menu:       /menu");
  console.log("➕ Add Menu:   POST /menu");
  console.log("✏️ Edit Menu:  PUT /menu/:id");
  console.log("🗑️ Delete:     DELETE /menu/:id");
  console.log("🔄 Availability PATCH /menu/:id/availability");
  console.log("🏫 Cafeterias: /cafeterias");
  console.log("🛒 Orders:     /orders");
  console.log("📊 Analytics:  /analytics");
  console.log("======================================");
});