import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:precon_wellness/models/client.dart';
import 'package:precon_wellness/screens/diet_plan_screen.dart';

void main() {
  testWidgets('saving a food item closes the dialog without an exception', (
    tester,
  ) async {
    final client = Client(
      fullName: 'Test Client',
      age: 30,
      gender: 'Female',
      height: 165,
      weight: 65,
      goal: 'Fitness',
      phoneNumber: '1234567890',
      email: 'test@example.com',
    );

    await tester.pumpWidget(MaterialApp(home: DietPlanScreen(client: client)));

    await tester.tap(find.text('Add Breakfast Item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Food Name'), 'Oats');
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '50');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(client.breakfastItems, hasLength(1));
    expect(client.breakfastItems.single.name, 'Oats');
    expect(find.text('Oats'), findsOneWidget);
  });
}
