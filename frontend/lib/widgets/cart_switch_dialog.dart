import 'package:flutter/material.dart';

/// Shows a confirmation dialog when adding an item from a different cafeteria
/// than the one currently in the cart.
///
/// Returns `true` if the user clicks "CLEAR CART & ADD", `false` if "CANCEL".
Future<bool> showCartCafeteriaSwitchDialog(
  BuildContext context, {
  required String currentCafeteria,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Your cart has items from $currentCafeteria',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Your cart can contain items from only one cafeteria at a time.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'CLEAR CART & ADD',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
