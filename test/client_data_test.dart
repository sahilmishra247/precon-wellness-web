import 'package:flutter_test/flutter_test.dart';
import 'package:precon_wellness/models/client.dart';
import 'package:precon_wellness/models/food_item.dart';
import 'package:precon_wellness/models/note.dart';

Client createClient(String name) {
  return Client(
    fullName: name,
    age: 30,
    gender: 'Female',
    height: 165,
    weight: 65,
    goal: 'Fitness',
    phoneNumber: '1234567890',
    email: '$name@example.com',
  );
}

void main() {
  test('plans and notes remain isolated per client', () {
    final first = createClient('First');
    final second = createClient('Second');

    first.breakfastItems.add(FoodItem(name: 'Oats', amount: 50, unit: 'g'));
    first.notes.add(
      Note(
        text: 'Initial consultation',
        createdAt: DateTime(2026, 6, 14),
        authorName: 'Coach',
      ),
    );

    expect(first.breakfastItems, hasLength(1));
    expect(first.notes, hasLength(1));
    expect(second.breakfastItems, isEmpty);
    expect(second.notes, isEmpty);
  });
}
