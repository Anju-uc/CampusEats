import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderRatingDialog extends StatefulWidget {
  final String orderId;
  final String foodName;
  final String cafeteria;
  final Function(int rating, String review)? onReviewSubmitted;

  const OrderRatingDialog({
    super.key,
    required this.orderId,
    required this.foodName,
    required this.cafeteria,
    this.onReviewSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String foodName,
    required String cafeteria,
    Function(int rating, String review)? onReviewSubmitted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OrderRatingDialog(
        orderId: orderId,
        foodName: foodName,
        cafeteria: cafeteria,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  State<OrderRatingDialog> createState() => _OrderRatingDialogState();
}

class _OrderRatingDialogState extends State<OrderRatingDialog> {
  int _selectedRating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating < 1 || _selectedRating > 5) {
      setState(() {
        _errorMessage = "Please select a rating between 1 and 5 stars";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final reviewText = _reviewController.text.trim();
      await ApiService.submitOrderReview(
        orderId: widget.orderId,
        rating: _selectedRating,
        review: reviewText.isNotEmpty ? reviewText : null,
      );

      if (mounted) {
        widget.onReviewSubmitted?.call(_selectedRating, reviewText);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thank you for your feedback!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Rate your order",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "${widget.foodName} • ${widget.cafeteria}",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // 1-5 STARS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _selectedRating = starIndex;
                          });
                        },
                  icon: Icon(
                    starIndex <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 38,
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              _getRatingLabel(_selectedRating),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 16),

            // MULTILINE REVIEW TEXT FIELD
            TextField(
              controller: _reviewController,
              maxLines: 3,
              maxLength: 500,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                hintText: "Write a review (optional)",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFFFFFBF7),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 1.5),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 16),

            // SUBMIT & SKIP BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "SKIP",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "SUBMIT REVIEW",
                            style: TextStyle(fontWeight: FontWeight.bold),
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

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return "Poor ★☆☆☆☆";
      case 2:
        return "Fair ★★☆☆☆";
      case 3:
        return "Good ★★★☆☆";
      case 4:
        return "Very Good ★★★★☆";
      case 5:
        return "Excellent ★★★★★";
      default:
        return "";
    }
  }
}

class ViewOrderReviewDialog extends StatelessWidget {
  final int rating;
  final String review;
  final String foodName;
  final String cafeteria;

  const ViewOrderReviewDialog({
    super.key,
    required this.rating,
    required this.review,
    required this.foodName,
    required this.cafeteria,
  });

  static void show(
    BuildContext context, {
    required int rating,
    required String review,
    required String foodName,
    required String cafeteria,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ViewOrderReviewDialog(
        rating: rating,
        review: review,
        foodName: foodName,
        cafeteria: cafeteria,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Your Review",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "$foodName • $cafeteria",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 32,
                );
              }),
            ),
            const SizedBox(height: 12),
            if (review.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  '"$review"',
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              Text(
                "No written review provided.",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("CLOSE"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
