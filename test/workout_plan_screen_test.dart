import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:precon_wellness/models/client.dart';
import 'package:precon_wellness/screens/workout_plan_screen.dart';

void main() {
  testWidgets('saving an exercise closes the dialog without an exception', (
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

    await tester.pumpWidget(
      MaterialApp(home: WorkoutPlanScreen(client: client)),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Squat');
    await tester.enterText(find.byType(TextField).at(1), '3');
    await tester.enterText(find.byType(TextField).at(2), '10');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(client.exercises, hasLength(1));
    expect(client.exercises.single.name, 'Squat');
    expect(find.text('Squat'), findsOneWidget);
  });
}
