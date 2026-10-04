import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../services/cashfree/cashfree_checkout_service.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String _statusMessage = '';

  // Scheduled pickup state
  bool _isScheduled = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = _getDefaultTime(_selectedDate);
  }

  List<TimeOfDay> _getAvailableTimeSlots(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final earliestValid = now.add(const Duration(minutes: 20));

    final List<TimeOfDay> slots = [];
    for (int hour = 8; hour <= 17; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        if (hour == 17 && minute > 0) break; // Ends at 05:00 PM
        final slotDt = DateTime(date.year, date.month, date.day, hour, minute);
        if (isToday && slotDt.isBefore(earliestValid)) {
          continue;
        }
        slots.add(TimeOfDay(hour: hour, minute: minute));
      }
    }
    return slots;
  }

  TimeOfDay _getDefaultTime([DateTime? forDate]) {
    final date = forDate ?? _selectedDate ?? DateTime.now();
    final slots = _getAvailableTimeSlots(date);
    if (slots.isNotEmpty) {
      return slots.first;
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  DateTime _getScheduledPickupDateTime() {
    final date = _selectedDate ?? DateTime.now();
    final time = _selectedTime ?? _getDefaultTime(date);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatTime(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatPickupWindow(DateTime pickupAt) {
    final endAt = pickupAt.add(const Duration(minutes: 15));
    final startTod = TimeOfDay(hour: pickupAt.hour, minute: pickupAt.minute);
    final endTod = TimeOfDay(hour: endAt.hour, minute: endAt.minute);
    return '${_formatTime(startTod)} – ${_formatTime(endTod)}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        final available = _getAvailableTimeSlots(picked);
        if (_selectedTime == null ||
            !available.any(
              (s) =>
                  s.hour == _selectedTime!.hour &&
                  s.minute == _selectedTime!.minute,
            )) {
          _selectedTime = _getDefaultTime(picked);
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final date = _selectedDate ?? DateTime.now();
    final availableSlots = _getAvailableTimeSlots(date);

    if (availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No more pickup slots available for today (08:00 AM – 05:00 PM). Please select tomorrow or a future date.",
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<TimeOfDay>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Pickup Time (${_formatDate(date)})",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Text(
                  "Available slots (08:00 AM – 05:00 PM, 15-min intervals):",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: availableSlots.length,
                    itemBuilder: (context, index) {
                      final slot = availableSlots[index];
                      final isCurrent = _selectedTime != null &&
                          _selectedTime!.hour == slot.hour &&
                          _selectedTime!.minute == slot.minute;
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(slot),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Colors.orange
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.orange
                                  : Colors.orange.shade200,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _formatTime(slot),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? Colors.white
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedTime = selected;
      });
    }
  }

  // ============================================================
  // PROCESS CASHFREE SANDBOX PAYMENT (NORMAL FOOD-DELIVERY FLOW)
  // ============================================================

  Future<void> _processPayment() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // ------------------------------------------------------------
    // 1. CHECK CART
    // ------------------------------------------------------------
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your cart is empty."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cafeteria = cartProvider.items.first.cafeteria.isNotEmpty
        ? cartProvider.items.first.cafeteria
        : 'Bengaluru Cafe';

    if (cartProvider.items.any((item) => item.cafeteria.isNotEmpty && item.cafeteria != cafeteria)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All items in an order must belong to one cafeteria."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    DateTime? scheduledPickupDateTime;
    if (_isScheduled) {
      scheduledPickupDateTime = _getScheduledPickupDateTime();
      final now = DateTime.now();
      if (scheduledPickupDateTime
          .isBefore(now.add(const Duration(minutes: 20)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Scheduled pickup time must satisfy the minimum preparation lead time (at least 20 mins from now).",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final hour = scheduledPickupDateTime.hour;
      final minute = scheduledPickupDateTime.minute;
      if (hour < 8 || (hour > 17 || (hour == 17 && minute > 0))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Scheduled pickup time must be between 08:00 AM and 05:00 PM.",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Preparing your order...';
    });

    try {
      // ------------------------------------------------------------
      // 2. CREATE CASHFREE SANDBOX ORDER ON BACKEND
      // ------------------------------------------------------------
      final cartPayload = cartProvider.items.map((item) {
        return {
          'menuItemId': item.backendMenuItemId ?? item.menuItemId,
          'name': item.name,
          'quantity': item.quantity,
          'price': item.price,
        };
      }).toList();

      final orderResult = await ApiService.createPaymentOrder(
        cafeteria: cafeteria,
        items: cartPayload,
        orderType: _isScheduled ? 'SCHEDULED' : 'ASAP',
        scheduledPickupAt: _isScheduled && scheduledPickupDateTime != null
            ? scheduledPickupDateTime.toIso8601String()
            : null,
      );

      final String paymentSessionId =
          orderResult['paymentSessionId']?.toString() ?? '';
      final String orderId =
          orderResult['cashfreeOrderId']?.toString() ??
          orderResult['orderId']?.toString() ??
          '';
      final String environment =
          orderResult['environment']?.toString() ?? 'sandbox';

      if (paymentSessionId.isEmpty || orderId.isEmpty) {
        throw Exception(
          'Payment session could not be initialized. Please try again.',
        );
      }

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Opening Cashfree checkout...';
      });

      // ------------------------------------------------------------
      // 3. LAUNCH CASHFREE HOSTED CHECKOUT MODAL
      // ------------------------------------------------------------
      final options = CashfreeCheckoutOptions(
        paymentSessionId: paymentSessionId,
        orderId: orderId,
        environment: environment,
      );

      final paymentSuccess = await CashfreeCheckoutService.openCheckout(
        options,
      );

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Confirming order with kitchen...';
      });

      // ------------------------------------------------------------
      // 4. VERIFY CASHFREE PAYMENT ON BACKEND & CREATE ORDER
      // ------------------------------------------------------------
      final verificationResult = await ApiService.verifyPayment(
        orderId: paymentSuccess.orderId,
        cashfreeOrderId: paymentSuccess.orderId,
      );

      if (!mounted) return;

      // ------------------------------------------------------------
      // 5. CLEAR CART ONLY AFTER CONFIRMED SUCCESSFUL PAYMENT
      // ------------------------------------------------------------
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final dynamic createdOrder = verificationResult['order'];
      OrderModel? newlyCreatedOrder;

      if (createdOrder is Map) {
        final orderMap = Map<String, dynamic>.from(createdOrder);
        orderProvider.addOrder(orderMap);
        newlyCreatedOrder = OrderModel.fromMap(orderMap);
      }

      cartProvider.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isScheduled
              ? "Scheduled order reserved! Kitchen will prepare at the right time."
              : "Order confirmed! Your meal is being prepared."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // ------------------------------------------------------------
      // 6. NAVIGATE TO SUCCESS SCREEN
      // ------------------------------------------------------------
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessScreen(order: newlyCreatedOrder),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint("PAYMENT / ORDER ERROR: $e");

      final rawError = e.toString().replaceFirst('Exception: ', '');
      final isCancelled = rawError.toLowerCase().contains('cancelled') ||
          rawError.toLowerCase().contains('dismissed') ||
          rawError.toLowerCase().contains('closed');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCancelled
                ? "Payment cancelled. Your cart and schedule have been saved."
                : (rawError.contains('cart is empty') || rawError.contains('Cart is empty')
                    ? "Your cart is empty."
                    : (rawError.contains('session') || rawError.contains('expired')
                        ? "Your session has expired. Please log in again."
                        : (rawError.contains('Scheduled pickup time')
                            ? rawError
                            : "Payment could not be completed. Please try again."))),
          ),
          backgroundColor: isCancelled ? Colors.orange.shade800 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
      }
    }
  }

  // ============================================================
  // BUILD FOOD-DELIVERY CHECKOUT SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cafeteriaName = cartProvider.items.isNotEmpty &&
            cartProvider.items.first.cafeteria.isNotEmpty
        ? cartProvider.items.first.cafeteria
        : 'Bengaluru Cafe';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: false,
        title: const Text(
          "Checkout",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: cartProvider.items.isEmpty
          ? _buildEmptyCartView()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. PICKUP LOCATION CARD
                        _buildPickupLocationCard(cafeteriaName),
                        const SizedBox(height: 16),

                        // 2. PICKUP TIME SCHEDULING CARD
                        _buildPickupTimeCard(),
                        const SizedBox(height: 16),

                        // 3. ITEMIZED ORDER SUMMARY
                        _buildItemizedOrderSummary(cartProvider),
                        const SizedBox(height: 16),

                        // 4. BILL BREAKDOWN
                        _buildBillDetails(cartProvider),
                        const SizedBox(height: 16),

                        // 5. PAYMENT METHOD
                        _buildPaymentMethodCard(),
                        const SizedBox(height: 20),

                        // 6. SAFE & SECURE BADGE
                        _buildSecureNotice(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // 7. STICKY BOTTOM PAY BAR
                _buildBottomPayBar(cartProvider),
              ],
            ),
    );
  }

  Widget _buildEmptyCartView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "Your cart is empty",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Add delicious meals from the campus cafeteria to order.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Browse Menu"),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupLocationCard(String cafeteriaName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cafeteriaName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "PICKUP",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Campus Food Court • Ready in 15-20 mins",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupTimeCard() {
    final scheduledPickup = _getScheduledPickupDateTime();
    final pickupWindowStr = _formatPickupWindow(scheduledPickup);
    final pickupTimeStr = _formatTime(
      TimeOfDay(hour: scheduledPickup.hour, minute: scheduledPickup.minute),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.schedule_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                "Pickup Time",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // TOGGLE BUTTONS
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isScheduled = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: !_isScheduled ? Colors.orange : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !_isScheduled ? Colors.orange : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 18,
                            color: !_isScheduled ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Pickup Now",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: !_isScheduled ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isScheduled = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _isScheduled ? Colors.orange : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isScheduled ? Colors.orange : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: _isScheduled ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Schedule Pickup",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isScheduled ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_isScheduled) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // DATE & TIME PICKERS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event, size: 18, color: Colors.orange),
                    label: Text(
                      _formatDate(_selectedDate ?? DateTime.now()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      side: BorderSide(color: Colors.orange.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 18, color: Colors.orange),
                    label: Text(
                      _formatTime(_selectedTime ?? _getDefaultTime()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      side: BorderSide(color: Colors.orange.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // SCHEDULE SUMMARY BOX
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_alarms_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Scheduled Pickup: $pickupTimeStr",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      "Pickup Window: $pickupWindowStr",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.only(left: 26),
                    child: Text(
                      "Pay now to reserve your pickup.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemizedOrderSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Items Ordered",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "${cartProvider.itemCount} ${cartProvider.itemCount == 1 ? 'item' : 'items'}",
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cartProvider.items.length,
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFF1F3F5)),
            ),
            itemBuilder: (context, index) {
              final item = cartProvider.items[index];
              return Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 1.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      "${item.quantity}x",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "₹${item.totalPrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBillDetails(CartProvider cartProvider) {
    final double itemTotal = cartProvider.totalAmount;
    const double gst = 3.0;
    final double toPay = itemTotal + gst;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bill Details",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Item Total", style: TextStyle(fontSize: 14, color: Colors.black54)),
              Text(
                "₹${itemTotal.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cafeteria Pickup Fee", style: TextStyle(fontSize: 14, color: Colors.black54)),
              Text(
                "FREE / ₹0",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("GST", style: TextStyle(fontSize: 14, color: Colors.black54)),
              Text(
                "₹3",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "To Pay",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "₹${toPay.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Payment Method",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cashfree Sandbox Checkout",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "UPI, QR, Cards, Net Banking & Wallets",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecureNotice() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            "100% Safe & Secure Payments via Cashfree",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPayBar(CartProvider cartProvider) {
    final double toPay = cartProvider.totalAmount + 3.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_statusMessage.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "TOTAL",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "₹${toPay.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.orange.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "PAY & PLACE ORDER",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
