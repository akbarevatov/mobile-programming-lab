import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cart_four_ways/setstate/cart_page_setstate.dart';

void main() {
  testWidgets('SetStateCartPage applies SAVE10 for 88.20 total', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SetStateCartPage()));

    final keyboardChip = find.widgetWithText(ActionChip, 'Keyboard · 49');
    await tester.tap(keyboardChip);
    await tester.pump();
    await tester.tap(keyboardChip);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'SAVE10');
    await tester.tap(find.text('Apply'));
    await tester.pump();

    expect(find.text('88.20'), findsOneWidget);
  });
}

