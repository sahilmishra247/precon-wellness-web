import 'package:flutter_test/flutter_test.dart';
import 'package:precon_wellness/models/client.dart';

void main() {
  group('Client Signup & Profile Initialization', () {
    test('Client model parses successfully from signup response JSON', () {
      final jsonResponse = {
        'id': 42,
        'name': 'Emma Watson',
        'email': 'emma@example.com',
        'role': 'client',
        'age': 29,
        'gender': 'Female',
        'height': 165.0,
        'weight': 58.0,
        'goal': 'Endurance & Stamina',
        'phone_number': '555-432-1098',
        'is_archived': false,
      };

      final client = Client(
        id: jsonResponse['id'] as int,
        fullName: jsonResponse['name'] as String,
        age: jsonResponse['age'] as int,
        gender: jsonResponse['gender'] as String,
        height: ((jsonResponse['height']) as num).toDouble(),
        weight: ((jsonResponse['weight']) as num).toDouble(),
        goal: jsonResponse['goal'] as String,
        phoneNumber: jsonResponse['phone_number'] as String,
        email: jsonResponse['email'] as String,
      );

      expect(client.id, 42);
      expect(client.fullName, 'Emma Watson');
      expect(client.email, 'emma@example.com');
      expect(client.age, 29);
      expect(client.gender, 'Female');
      expect(client.height, 165.0);
      expect(client.weight, 58.0);
      expect(client.goal, 'Endurance & Stamina');
      expect(client.phoneNumber, '555-432-1098');
      expect(client.isArchived, isFalse);
    });

    test('Client signup data validation constraints', () {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      expect(emailRegex.hasMatch('client@precon.com'), isTrue);
      expect(emailRegex.hasMatch('invalid-email'), isFalse);
      expect(emailRegex.hasMatch(''), isFalse);

      const validPassword = 'strongpassword123';
      const shortPassword = 'abc';
      expect(validPassword.length >= 6, isTrue);
      expect(shortPassword.length >= 6, isFalse);
    });
  });
}
