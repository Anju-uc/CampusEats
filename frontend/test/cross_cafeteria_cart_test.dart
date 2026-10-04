import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/cart_item.dart';
import 'package:frontend/providers/cart_provider.dart';
import 'package:frontend/widgets/cart_switch_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Cross-Cafeteria Cart Logic and Confirmation Dialog', () {
    test('1. Cart empty -> add Bengaluru Cafe item -> succeeds', () {
      final cart = CartProvider();
      expect(cart.items, isEmpty);
      expect(cart.currentCafeteria, isNull);

      final item = CartItem(
        name: 'Masala Dosa',
        image: '',
        price: 60,
        cafeteria: 'Bengaluru Cafe',
      );

      final added = cart.addItem(item);
      expect(added, isTrue);
      expect(cart.items, hasLength(1));
      expect(cart.currentCafeteria, 'Bengaluru Cafe');
      expect(cart.items.first.name, 'Masala Dosa');
    });

    test('2. Cart has Bengaluru Cafe item -> add another Bengaluru Cafe item -> succeeds', () {
      final cart = CartProvider();
      cart.addItem(CartItem(
        name: 'Masala Dosa',
        image: '',
        price: 60,
        cafeteria: 'Bengaluru Cafe',
      ));

      final item2 = CartItem(
        name: 'Filter Coffee',
        image: '',
        price: 20,
        cafeteria: 'Bengaluru Cafe',
      );

      final added = cart.addItem(item2);
      expect(added, isTrue);
      expect(cart.items, hasLength(2));
      expect(cart.currentCafeteria, 'Bengaluru Cafe');
    });

    test('3. Cart has Cafe PESU item -> hasDifferentCafeteria detects Bengaluru Cafe', () {
      final cart = CartProvider();
      cart.addItem(CartItem(
        name: 'Veg Burger',
        image: '',
        price: 80,
        cafeteria: 'Cafe PESU',
      ));

      expect(cart.currentCafeteria, 'Cafe PESU');
      expect(cart.hasDifferentCafeteria('Cafe PESU'), isFalse);
      expect(cart.hasDifferentCafeteria('Bengaluru Cafe'), isTrue);
      expect(cart.hasDifferentCafeteria('Non-Veg Cafeteria'), isTrue);
    });

    test('4. clearAndAddItem clears previous cafeteria and sets new item', () {
      final cart = CartProvider();
      cart.addItem(CartItem(
        name: 'Veg Burger',
        image: '',
        price: 80,
        cafeteria: 'Cafe PESU',
      ));

      expect(cart.items, hasLength(1));
      expect(cart.currentCafeteria, 'Cafe PESU');

      final newItem = CartItem(
        name: 'Masala Dosa',
        image: '',
        price: 60,
        cafeteria: 'Bengaluru Cafe',
      );

      cart.clearAndAddItem(newItem);

      expect(cart.items, hasLength(1));
      expect(cart.currentCafeteria, 'Bengaluru Cafe');
      expect(cart.items.first.name, 'Masala Dosa');
      expect(cart.items.first.cafeteria, 'Bengaluru Cafe');
    });

    testWidgets('5. Confirmation dialog CANCEL keeps existing cart', (tester) async {
      final cart = CartProvider();
      cart.addItem(CartItem(
        name: 'Veg Burger',
        image: '',
        price: 80,
        cafeteria: 'Cafe PESU',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CartProvider>.value(
            value: cart,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      final shouldSwitch = await showCartCafeteriaSwitchDialog(
                        context,
                        currentCafeteria: cart.currentCafeteria ?? 'Cafe PESU',
                      );
                      if (shouldSwitch) {
                        cart.clearAndAddItem(CartItem(
                          name: 'Masala Dosa',
                          image: '',
                          price: 60,
                          cafeteria: 'Bengaluru Cafe',
                        ));
                      }
                    },
                    child: const Text('Add Dosa'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to trigger dialog
      await tester.tap(find.text('Add Dosa'));
      await tester.pumpAndSettle();

      // Verify dialog text
      expect(find.text('Your cart has items from Cafe PESU'), findsOneWidget);
      expect(
        find.text('Your cart can contain items from only one cafeteria at a time.'),
        findsOneWidget,
      );
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('CLEAR CART & ADD'), findsOneWidget);

      // Tap CANCEL
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      // Dialog dismissed, old cart remains
      expect(cart.items, hasLength(1));
      expect(cart.currentCafeteria, 'Cafe PESU');
      expect(cart.items.first.name, 'Veg Burger');
    });

    testWidgets('6. Confirmation dialog CLEAR CART & ADD switches cart to new cafeteria', (tester) async {
      final cart = CartProvider();
      cart.addItem(CartItem(
        name: 'Veg Burger',
        image: '',
        price: 80,
        cafeteria: 'Cafe PESU',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CartProvider>.value(
            value: cart,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      final shouldSwitch = await showCartCafeteriaSwitchDialog(
                        context,
                        currentCafeteria: cart.currentCafeteria ?? 'Cafe PESU',
                      );
                      if (shouldSwitch) {
                        cart.clearAndAddItem(CartItem(
                          name: 'Masala Dosa',
                          image: '',
                          price: 60,
                          cafeteria: 'Bengaluru Cafe',
                        ));
                      }
                    },
                    child: const Text('Add Dosa'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to trigger dialog
      await tester.tap(find.text('Add Dosa'));
      await tester.pumpAndSettle();

      // Tap CLEAR CART & ADD
      await tester.tap(find.text('CLEAR CART & ADD'));
      await tester.pumpAndSettle();

      // Old cart cleared, new item added
      expect(cart.items, hasLength(1));
      expect(cart.currentCafeteria, 'Bengaluru Cafe');
      expect(cart.items.first.name, 'Masala Dosa');
    });

    test('7. Another student cart is unaffected by switching session', () async {
      final cartA = CartProvider();
      await cartA.switchSession('student:student-01');
      cartA.addItem(CartItem(
        name: 'Veg Burger',
        image: '',
        price: 80,
        cafeteria: 'Cafe PESU',
      ));

      final cartB = CartProvider();
      await cartB.switchSession('student:student-02');
      cartB.addItem(CartItem(
        name: 'Chicken Roll',
        image: '',
        price: 120,
        cafeteria: 'Non-Veg Cafeteria',
      ));

      // Student A switches cafeteria to Bengaluru Cafe
      cartA.clearAndAddItem(CartItem(
        name: 'Masala Dosa',
        image: '',
        price: 60,
        cafeteria: 'Bengaluru Cafe',
      ));

      expect(cartA.items, hasLength(1));
      expect(cartA.currentCafeteria, 'Bengaluru Cafe');
      expect(cartA.items.first.name, 'Masala Dosa');

      // Student B's cart remains intact and untouched
      expect(cartB.items, hasLength(1));
      expect(cartB.currentCafeteria, 'Non-Veg Cafeteria');
      expect(cartB.items.first.name, 'Chicken Roll');
    });
  });
}
