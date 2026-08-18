import 'package:flutter/material.dart';

import 'add_food_screen.dart';
import 'manage_menu_screen.dart';
import 'orders_screen.dart';
import 'kitchen_dashboard.dart';
import 'reports_screen.dart';
import 'analytics_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // ==========================
  // DASHBOARD CARD
  // ==========================

  Widget dashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),

        child: Container(
          width: double.infinity,

          padding:
              const EdgeInsets.all(14),

          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(20),

            color:
                color.withOpacity(0.08),

            border: Border.all(
              color:
                  color.withOpacity(0.12),
            ),
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            mainAxisSize:
                MainAxisSize.min,

            children: [
              Container(
                height: 52,
                width: 52,

                decoration:
                    BoxDecoration(
                  color:
                      color.withOpacity(0.14),

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                title,

                textAlign:
                    TextAlign.center,

                maxLines: 2,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                subtitle,

                textAlign:
                    TextAlign.center,

                maxLines: 2,

                overflow:
                    TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================
  // WELCOME CARD
  // ==========================

  Widget welcomeCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Colors.orange,
            Colors.deepOrange,
          ],
        ),

        borderRadius:
            BorderRadius.circular(24),
      ),

      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,

            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withOpacity(0.20),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  "Welcome, Admin 👋",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  "Manage CampusEats from one place.",

                  style: TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================
  // SECTION TITLE
  // ==========================

  Widget sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style:
              const TextStyle(
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          subtitle,

          style: TextStyle(
            fontSize: 13,
            color:
                Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ==========================
  // BUILD
  // ==========================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF9F4),

      // ==========================
      // APP BAR
      // ==========================

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            Colors.orange,

        foregroundColor:
            Colors.white,

        title: const Text(
          "Admin Dashboard",

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
            ),

            onPressed: () {},
          ),
        ],
      ),

      // ==========================
      // BODY
      // ==========================

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              welcomeCard(),

              const SizedBox(
                height: 25,
              ),

              // ==========================
              // OVERVIEW
              // ==========================

              sectionTitle(
                "Overview",
                "Manage your CampusEats system",
              ),

              const SizedBox(
                height: 15,
              ),

              GridView.count(
                crossAxisCount: 2,

                crossAxisSpacing: 14,

                mainAxisSpacing: 14,

                childAspectRatio: 0.95,

                shrinkWrap: true,

                physics:
                    const NeverScrollableScrollPhysics(),

                children: [
                  // ADD FOOD

                  dashboardCard(
                    context,
                    Icons.fastfood,
                    "Add Food",
                    "Add new items",
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const AddFoodScreen(),
                        ),
                      );
                    },
                  ),

                  // MANAGE MENU

                  dashboardCard(
                    context,
                    Icons.restaurant_menu,
                    "Manage Menu",
                    "Edit campus menu",
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const ManageMenuScreen(),
                        ),
                      );
                    },
                  ),

                  // ORDERS

                  dashboardCard(
                    context,
                    Icons.receipt_long,
                    "Orders",
                    "View all orders",
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const OrdersScreen(),
                        ),
                      );
                    },
                  ),

                  // KITCHEN

                  dashboardCard(
                    context,
                    Icons.restaurant,
                    "Kitchen",
                    "Kitchen control",
                    Colors.deepOrange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const KitchenDashboard(),
                        ),
                      );
                    },
                  ),

                  // REPORTS

                  dashboardCard(
                    context,
                    Icons.bar_chart,
                    "Reports",
                    "View sales reports",
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ReportsScreen(),
                        ),
                      );
                    },
                  ),

                  // ANALYTICS

                  dashboardCard(
                    context,
                    Icons.analytics,
                    "Analytics",
                    "Track performance",
                    Colors.indigo,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(
                height: 28,
              ),

              // ==========================
              // QUICK MANAGEMENT
              // ==========================

              sectionTitle(
                "Quick Management",
                "Frequently used admin actions",
              ),

              const SizedBox(
                height: 14,
              ),

              // ADD FOOD

              _quickAction(
                icon:
                    Icons.add_circle_outline,

                title: "Add Food",

                subtitle:
                    "Add a new food item to the campus menu",

                color:
                    Colors.orange,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const AddFoodScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 12,
              ),

              // MANAGE MENU

              _quickAction(
                icon:
                    Icons.restaurant_menu,

                title: "Manage Menu",

                subtitle:
                    "Update food, prices and availability",

                color:
                    Colors.green,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const ManageMenuScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 12,
              ),

              // ORDERS

              _quickAction(
                icon:
                    Icons.receipt_long,

                title: "Manage Orders",

                subtitle:
                    "Check and manage student orders",

                color:
                    Colors.blue,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const OrdersScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 12,
              ),

              // KITCHEN

              _quickAction(
                icon:
                    Icons.restaurant,

                title: "Kitchen Control",

                subtitle:
                    "Monitor preparation and pickup",

                color:
                    Colors.deepOrange,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const KitchenDashboard(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 12,
              ),

              // REPORTS

              _quickAction(
                icon:
                    Icons.bar_chart,

                title: "Reports",

                subtitle:
                    "Check sales and order statistics",

                color:
                    Colors.purple,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ReportsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================
  // QUICK ACTION
  // ==========================

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(18),

      child: Container(
        padding:
            const EdgeInsets.all(15),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color:
                Colors.grey.shade200,
          ),
        ),

        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,

              decoration:
                  BoxDecoration(
                color:
                    color.withOpacity(0.12),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    subtitle,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color:
                  Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}