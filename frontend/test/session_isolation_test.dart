import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/cart_item.dart';
import 'package:frontend/providers/cart_provider.dart';

void main() {
  test('switching sessions does not retain another session cart', () async {
    final cart = CartProvider();

    await cart.switchSession('student:student-a');
    cart.addItem(
      CartItem(
        name: 'Meal A',
        image: '',
        price: 50,
      ),
    );
    expect(cart.items, hasLength(1));

    await cart.switchSession('faculty:faculty-a');
    expect(cart.items, isEmpty);

    await cart.switchSession('student:student-b');
    expect(cart.items, isEmpty);
  });
}