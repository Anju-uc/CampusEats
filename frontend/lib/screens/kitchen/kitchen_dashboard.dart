import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';

import 'orders_screen.dart';
import 'preparing_orders.dart';
import 'ready_orders.dart';
import 'completed_orders.dart';

class KitchenDashboard extends StatefulWidget {
  const KitchenDashboard({super.key});

  @override
  State<KitchenDashboard> createState() =>
      _KitchenDashboardState();
}

class _KitchenDashboardState
    extends State<KitchenDashboard> {

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  // ============================================================
  // DASHBOARD CARD
  // ============================================================

  Widget dashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String count,
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

          decoration: BoxDecoration(
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

            children: [
              Container(
                height: 52,
                width: 52,

                decoration:
                    BoxDecoration(
                  color:
                      color.withOpacity(0.14),

                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                count,

                style: TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(height: 3),

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

              const SizedBox(height: 5),

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

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget topWelcomeCard() {
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
                  Colors.white.withOpacity(
                0.20,
              ),

              shape:
                  BoxShape.circle,
            ),

            child: const Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Kitchen Control 👨‍🍳',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Manage today's campus orders",

                  style: TextStyle(
                    color: Colors.white70,
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

  // ============================================================
  // SECTION TITLE
  // ============================================================

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

        const SizedBox(height: 4),

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF9F4),

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            Colors.orange,

        foregroundColor:
            Colors.white,

        title: const Text(
          'Kitchen Dashboard',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon:
                const Icon(Icons.refresh),

            onPressed: () {
              context
                  .read<OrderProvider>()
                  .loadOrders();
            },
          ),
        ],
      ),

      body: Consumer<OrderProvider>(
        builder: (
          context,
          orderProvider,
          child,
        ) {
          // ======================================================
          // COUNTS
          // ======================================================

          final orders =
              orderProvider.orders;

          final totalOrders =
              orders.length;

          final confirmedOrders =
              orderProvider
                  .getOrdersByStatus(
                'Confirmed',
              )
                  .length;

          final preparingOrders =
              orderProvider
                  .getOrdersByStatus(
                'Preparing',
              )
                  .length;

          final readyOrders =
              orderProvider
                  .getOrdersByStatus(
                'Ready',
              )
                  .length;

          final completedOrders =
              orderProvider
                  .getOrdersByStatus(
                'Completed',
              )
                  .length;

          return RefreshIndicator(
            color: Colors.orange,

            onRefresh: () async {
              await orderProvider
                  .loadOrders();
            },

            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  topWelcomeCard(),

                  const SizedBox(
                    height: 25,
                  ),

                  sectionTitle(
                    "Today's Orders",
                    'Live order status from your database',
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  // ==================================================
                  // ORDER CARDS
                  // ==================================================

                  GridView.count(
                    crossAxisCount: 2,

                    crossAxisSpacing: 14,

                    mainAxisSpacing: 14,

                    childAspectRatio: 0.95,

                    shrinkWrap: true,

                    physics:
                        const NeverScrollableScrollPhysics(),

                    children: [
                      // ==================================================
                      // NEW / CONFIRMED
                      // ==================================================

                      dashboardCard(
                        context,

                        Icons.restaurant,

                        'New Orders',

                        'Incoming orders',

                        confirmedOrders
                            .toString(),

                        Colors.deepOrange,

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

                      // ==================================================
                      // PREPARING
                      // ==================================================

                      dashboardCard(
                        context,

                        Icons
                            .local_fire_department,

                        'Preparing',

                        'Orders being cooked',

                        preparingOrders
                            .toString(),

                        Colors.orange,

                        () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const PreparingOrders(),
                            ),
                          );
                        },
                      ),

                      // ==================================================
                      // READY
                      // ==================================================

                      dashboardCard(
                        context,

                        Icons
                            .notifications_active,

                        'Ready',

                        'Ready for pickup',

                        readyOrders
                            .toString(),

                        Colors.blue,

                        () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const ReadyOrders(),
                            ),
                          );
                        },
                      ),

                      // ==================================================
                      // COMPLETED
                      // ==================================================

                      dashboardCard(
                        context,

                        Icons.check_circle,

                        'Completed',

                        'Finished orders',

                        completedOrders
                            .toString(),

                        Colors.green,

                        () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const CompletedOrders(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  // ==================================================
                  // TOTAL ORDERS
                  // ==================================================

                  Container(
                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets.all(18),

                    decoration:
                        BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      border:
                          Border.all(
                        color:
                            Colors.grey.shade200,
                      ),
                    ),

                    child: Row(
                      children: [
                        Container(
                          height: 50,
                          width: 50,

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.orange
                                    .withOpacity(
                              0.12,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),

                          child:
                              const Icon(
                            Icons.receipt_long,

                            color:
                                Colors.orange,
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              const Text(
                                'Total Orders',

                                style:
                                    TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                '$totalOrders orders in database',

                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          totalOrders
                              .toString(),

                          style:
                              const TextStyle(
                            fontSize: 28,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  sectionTitle(
                    'Quick Actions',
                    'Common kitchen operations',
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ==================================================
                  // ALL ORDERS
                  // ==================================================

                  _quickAction(
                    icon:
                        Icons.receipt_long,

                    title:
                        'All Orders',

                    subtitle:
                        'View all orders',

                    color:
                        Colors.deepOrange,

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

                  // ==================================================
                  // PREPARING
                  // ==================================================

                  _quickAction(
                    icon:
                        Icons.restaurant_menu,

                    title:
                        'Preparing Orders',

                    subtitle:
                        'Manage food preparation',

                    color:
                        Colors.orange,

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const PreparingOrders(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // READY
                  // ==================================================

                  _quickAction(
                    icon:
                        Icons.notifications_active,

                    title:
                        'Ready for Pickup',

                    subtitle:
                        'View ready orders',

                    color:
                        Colors.blue,

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const ReadyOrders(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // COMPLETED
                  // ==================================================

                  _quickAction(
                    icon:
                        Icons.history,

                    title:
                        'Completed Orders',

                    subtitle:
                        'View completed orders',

                    color:
                        Colors.green,

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const CompletedOrders(),
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
          );
        },
      ),
    );
  }

  // ============================================================
  // QUICK ACTION
  // ============================================================

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