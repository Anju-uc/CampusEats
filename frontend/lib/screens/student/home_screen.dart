import 'package:flutter/material.dart';

import 'food_details_screen.dart';
import 'cart_screen.dart';
import 'notification_screen.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';
import 'order_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "All";
  String searchText = "";

  final List<FoodItem> foods = [
    FoodItem(
      name: "Idli",
      price: "₹30",
      rating: "4.8",
      category: "South Indian",
      image: "assets/images/food/idli.jpg",
      description:
          "Soft steamed idlis served with chutney and sambar.",
      emoji: "🥣",
    ),
    FoodItem(
      name: "Vada",
      price: "₹25",
      rating: "4.7",
      category: "South Indian",
      image: "assets/images/food/vada.jpg",
      description:
          "Crispy South Indian medu vada.",
      emoji: "🍩",
    ),
    FoodItem(
      name: "Masala Dosa",
      price: "₹60",
      rating: "4.9",
      category: "South Indian",
      image: "assets/images/food/masala_dosa.jpg",
      description:
          "Crispy dosa filled with delicious potato masala.",
      emoji: "🥞",
    ),
    FoodItem(
      name: "Set Dosa",
      price: "₹50",
      rating: "4.7",
      category: "South Indian",
      image: "assets/images/food/set_dosa.jpg",
      description:
          "Soft and fluffy set dosa served with chutney.",
      emoji: "🥞",
    ),
    FoodItem(
      name: "Puri",
      price: "₹40",
      rating: "4.6",
      category: "South Indian",
      image: "assets/images/food/puri.jpg",
      description:
          "Hot fluffy puris with delicious side dish.",
      emoji: "🫓",
    ),
    FoodItem(
      name: "Bisi Bele Bath",
      price: "₹70",
      rating: "4.8",
      category: "South Indian",
      image: "assets/images/food/bisibele_bath.jpg",
      description:
          "Traditional Karnataka-style spicy rice meal.",
      emoji: "🍚",
    ),
    FoodItem(
      name: "Lemon Rice",
      price: "₹55",
      rating: "4.6",
      category: "South Indian",
      image: "assets/images/food/lemon_rice.jpg",
      description:
          "Fresh lemon rice with peanuts and spices.",
      emoji: "🍋",
    ),
    FoodItem(
      name: "Chole Bhature",
      price: "₹90",
      rating: "4.8",
      category: "North Indian",
      image: "assets/images/food/chole_bhature.jpg",
      description:
          "Fluffy bhature served with spicy chole.",
      emoji: "🍛",
    ),
    FoodItem(
      name: "Chicken Biryani",
      price: "₹120",
      rating: "4.9",
      category: "Chicken",
      image: "assets/images/food/chicken_biryani.jpg",
      description:
          "Aromatic chicken biryani with delicious spices.",
      emoji: "🍗",
    ),
    FoodItem(
      name: "Chicken 65",
      price: "₹110",
      rating: "4.8",
      category: "Chicken",
      image: "assets/images/food/chicken_65.jpg",
      description:
          "Crispy spicy Chicken 65.",
      emoji: "🍗",
    ),
    FoodItem(
      name: "Pizza",
      price: "₹140",
      rating: "4.7",
      category: "Fast Food",
      image: "assets/images/food/pizza.jpg",
      description:
          "Cheesy hot pizza perfect for your break.",
      emoji: "🍕",
    ),
    FoodItem(
      name: "Burger",
      price: "₹120",
      rating: "4.8",
      category: "Fast Food",
      image: "assets/images/food/burger.jpg",
      description:
          "Loaded campus-style burger.",
      emoji: "🍔",
    ),
    FoodItem(
      name: "Noodles",
      price: "₹90",
      rating: "4.7",
      category: "Chinese",
      image: "assets/images/food/noodles.jpg",
      description:
          "Hot and tasty Indo-Chinese noodles.",
      emoji: "🍜",
    ),
    FoodItem(
      name: "Coffee",
      price: "₹35",
      rating: "4.9",
      category: "Beverages",
      image: "assets/images/food/coffee.jpg",
      description:
          "Fresh hot coffee for your study session.",
      emoji: "☕",
    ),
    FoodItem(
      name: "Cold Coffee",
      price: "₹80",
      rating: "4.8",
      category: "Beverages",
      image: "assets/images/food/cold_coffee.jpg",
      description:
          "Creamy chilled cold coffee.",
      emoji: "🥤",
    ),
  ];

  // ============================================================
  // NAVIGATION
  // ============================================================

  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartScreen(),
      ),
    );
  }

  void openMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MenuScreen(),
      ),
    );
  }

  void openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationScreen(),
      ),
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  void openTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderTrackingScreen(),
      ),
    );
  }

  // ============================================================
  // OPEN FOOD DETAILS
  // IMPORTANT:
  // Only name, price and icon are passed.
  // NO isAvailable.
  // NO description.
  // ============================================================

  void openFood(FoodItem food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDetailsScreen(
          name: food.name,
          price: food.price,
          icon: food.icon,
        ),
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<FoodItem> get filteredFoods {
    return foods.where((food) {
      final categoryMatch =
          selectedCategory == "All" ||
          food.category == selectedCategory;

      final searchMatch =
          searchText.trim().isEmpty ||
          food.name
              .toLowerCase()
              .contains(searchText.toLowerCase());

      return categoryMatch && searchMatch;
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFF8A00),
        automaticallyImplyLeading: false,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CampusEats 🍴",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              "PES University • Student",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
            onPressed: openNotifications,
          ),

          IconButton(
            tooltip: "Track Order",
            icon: const Icon(
              Icons.local_shipping_outlined,
              color: Colors.white,
            ),
            onPressed: openTracking,
          ),

          IconButton(
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
            ),
            onPressed: openCart,
          ),

          IconButton(
            icon: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
            ),
            onPressed: openProfile,
          ),
        ],
      ),

      // ========================================================
      // FLOATING CART
      // ========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF8A00),
        onPressed: openCart,
        icon: const Icon(
          Icons.shopping_bag_rounded,
          color: Colors.white,
        ),
        label: const Text(
          "Cart",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF8A00),
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          if (index == 1) {
            openMenu();
          } else if (index == 2) {
            openCart();
          } else if (index == 3) {
            openProfile();
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: "Menu",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_rounded),
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),

        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            110,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Hey Student! 👋",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "What are you craving?",
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF202020),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Hungry between classes? We've got you 😋",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // SEARCH
              // ==================================================

              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),

                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },

                  decoration:
                      const InputDecoration(
                    hintText:
                        "Search dosa, biryani, pizza...",

                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Color(0xFFFF8A00),
                      size: 27,
                    ),

                    border: InputBorder.none,

                    contentPadding:
                        EdgeInsets.symmetric(
                      vertical: 17,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // TRACK ORDER
              // ==================================================

              GestureDetector(
                onTap: openTracking,

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.shade100,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        height: 55,
                        width: 55,

                        decoration:
                            BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Track Your Order",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "See your food status in real time",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        child: const Text(
                          "TRACK",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // BANNER
              // ==================================================

              Container(
                height: 190,
                width: double.infinity,

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF7A00),
                      Color(0xFFFFB347),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius:
                      BorderRadius.circular(28),

                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x30000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),

                child: Stack(
                  children: [
                    Positioned(
                      right: -25,
                      top: -30,

                      child: Container(
                        height: 150,
                        width: 150,

                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    Positioned(
                      right: 20,
                      bottom: 15,

                      child: Container(
                        height: 95,
                        width: 95,

                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),

                        child: const Center(
                          child: Text(
                            "🍕",
                            style: TextStyle(
                              fontSize: 55,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.all(22),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            "✨ STUDENT SPECIAL",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),

                          SizedBox(height: 12),

                          Text(
                            "Hungry?\nSkip the Queue! 😎",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              height: 1.05,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),

                          SizedBox(height: 10),

                          Text(
                            "Order • Pay • Track • Collect",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // CATEGORIES
              // ==================================================

              sectionTitle(
                "What are you in the mood for? 😋",
                "See All",
                openMenu,
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 108,

                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics:
                      const BouncingScrollPhysics(),

                  children: [
                    categoryCard("All", "🍽️"),
                    categoryCard(
                      "South Indian",
                      "🥞",
                    ),
                    categoryCard(
                      "North Indian",
                      "🍛",
                    ),
                    categoryCard(
                      "Chicken",
                      "🍗",
                    ),
                    categoryCard(
                      "Fast Food",
                      "🍔",
                    ),
                    categoryCard(
                      "Chinese",
                      "🍜",
                    ),
                    categoryCard(
                      "Beverages",
                      "☕",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // CAFETERIAS
              // ==================================================

              sectionTitle(
                "PES Cafeterias 🏫",
                "View All",
                openMenu,
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 150,

                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics:
                      const BouncingScrollPhysics(),

                  children: [
                    cafeCard(
                      "Bengaluru Cafe",
                      "Breakfast • Meals • Coffee",
                      "☕",
                    ),

                    cafeCard(
                      "Cafe PESU",
                      "Dosa • Pizza • Snacks",
                      "🍕",
                    ),

                    cafeCard(
                      "Non-Veg Cafeteria",
                      "Chicken • Biryani • Egg",
                      "🍗",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // TRENDING
              // ==================================================

              sectionTitle(
                "🔥 Trending with Students",
                "See All",
                openMenu,
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 280,

                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics:
                      const BouncingScrollPhysics(),

                  children: [
                    for (final food in foods.take(6))
                      foodCard(food),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // BETWEEN CLASSES CARD
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D2),
                  borderRadius:
                      BorderRadius.circular(24),
                ),

                child: Row(
                  children: [
                    Container(
                      height: 70,
                      width: 70,

                      decoration:
                          const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),

                      child: const Center(
                        child: Text(
                          "😋",
                          style: TextStyle(
                            fontSize: 40,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Between classes? ⚡",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            "Order now and collect without waiting!",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFFF8A00),
                      size: 18,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // POPULAR FOOD
              // ==================================================

              sectionTitle(
                "🍴 Popular on Campus",
                "View Menu",
                openMenu,
              ),

              const SizedBox(height: 15),

              ...filteredFoods
                  .take(8)
                  .map(
                    (food) => popularFoodTile(food),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY CARD
  // ============================================================

  Widget categoryCard(
    String title,
    String emoji,
  ) {
    final bool isSelected =
        selectedCategory == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = title;
        });
      },

      child: Container(
        width: 105,
        margin:
            const EdgeInsets.only(right: 12),

        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF8A00)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(20),

          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 30,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,

              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.black87,
                fontSize: 11,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CAFETERIA CARD
  // ============================================================

  Widget cafeCard(
    String title,
    String subtitle,
    String emoji,
  ) {
    return GestureDetector(
      onTap: openMenu,

      child: Container(
        width: 260,

        margin:
            const EdgeInsets.only(right: 14),

        padding: const EdgeInsets.all(17),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(22),

          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              height: 62,
              width: 62,

              decoration:
                  const BoxDecoration(
                color: Color(0xFFFFF0DE),
                shape: BoxShape.circle,
              ),

              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 32,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: Colors.green,
                        size: 8,
                      ),

                      SizedBox(width: 5),

                      Text(
                        "Open now",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FOOD CARD
  // ============================================================

  Widget foodCard(FoodItem food) {
    return GestureDetector(
      onTap: () => openFood(food),

      child: Container(
        width: 205,

        margin:
            const EdgeInsets.only(right: 15),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(22),

          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(22),
              ),

              child: Image.asset(
                food.image,
                height: 145,
                width: double.infinity,
                fit: BoxFit.cover,

                errorBuilder:
                    (context, error, stackTrace) {
                  return Container(
                    height: 145,
                    color:
                        const Color(0xFFFFF0DE),

                    child: Center(
                      child: Text(
                        food.emoji,
                        style:
                            const TextStyle(
                          fontSize: 55,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(12),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.orange,
                        size: 17,
                      ),

                      const SizedBox(width: 3),

                      Text(
                        food.rating,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        food.price,
                        style:
                            const TextStyle(
                          color: Colors.green,
                          fontWeight:
                              FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // POPULAR FOOD TILE
  // ============================================================

  Widget popularFoodTile(
    FoodItem food,
  ) {
    return GestureDetector(
      onTap: () => openFood(food),

      child: Container(
        margin:
            const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.all(10),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(20),

          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
            ),
          ],
        ),

        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(15),

              child: Image.asset(
                food.image,
                height: 70,
                width: 75,
                fit: BoxFit.cover,

                errorBuilder:
                    (context, error, stackTrace) {
                  return Container(
                    height: 70,
                    width: 75,

                    color:
                        const Color(0xFFFFF0DE),

                    child: Center(
                      child: Text(
                        food.emoji,
                        style:
                            const TextStyle(
                          fontSize: 30,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    food.name,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    food.category,
                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),

                      const SizedBox(width: 3),

                      Text(
                        food.rating,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Text(
              food.price,
              style:
                  const TextStyle(
                color: Colors.green,
                fontWeight:
                    FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SECTION TITLE
// ================================================================

Widget sectionTitle(
  String title,
  String action,
  VoidCallback onTap,
) {
  return Row(
    mainAxisAlignment:
        MainAxisAlignment.spaceBetween,

    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      GestureDetector(
        onTap: onTap,

        child: Text(
          action,
          style: const TextStyle(
            color: Color(0xFFFF8A00),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    ],
  );
}

// ================================================================
// FOOD MODEL
// ================================================================

class FoodItem {
  final String name;
  final String price;
  final String rating;
  final String category;
  final String image;
  final String description;
  final String emoji;

  FoodItem({
    required this.name,
    required this.price,
    required this.rating,
    required this.category,
    required this.image,
    required this.description,
    required this.emoji,
  });

  IconData get icon {
    switch (category) {
      case "Chicken":
        return Icons.set_meal_rounded;

      case "Fast Food":
        return Icons.fastfood_rounded;

      case "Chinese":
        return Icons.ramen_dining_rounded;

      case "Beverages":
        return Icons.local_cafe_rounded;

      case "North Indian":
        return Icons.restaurant_rounded;

      default:
        return Icons.rice_bowl_rounded;
    }
  }
}