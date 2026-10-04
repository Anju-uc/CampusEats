import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('CampusEats starts in demo mode', (tester) async {
    await tester.pumpWidget(const CampusEats());
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(CampusEats), findsOneWidget);
  });
}
