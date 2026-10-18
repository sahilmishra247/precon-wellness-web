import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:precon_wellness/models/client.dart';
import 'package:precon_wellness/models/food_item.dart';
import 'package:precon_wellness/screens/client_dashboard_screen.dart';

void main() {
  testWidgets('client dashboard exposes relevant read-only tools', (
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
    )..breakfastItems.add(FoodItem(name: 'Oats', amount: 50, unit: 'g'));

    await tester.pumpWidget(
      MaterialApp(home: ClientDashboardScreen(client: client)),
    );

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Diet Plan'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Workout Plan'), findsOneWidget);
    expect(find.text('Progress Tracking'), findsOneWidget);
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('Educational Resources'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Diet Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Oats'), findsOneWidget);
    expect(find.text('Add Breakfast Item'), findsNothing);
  });
}
