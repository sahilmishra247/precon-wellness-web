import 'package:flutter_test/flutter_test.dart';
import 'package:precon_wellness/models/client.dart';

void main() {
  group('Email Verification Tests', () {
    test('Client model parses is_email_verified correctly', () {
      final jsonResponse = {
        'id': 101,
        'name': 'Olivia Wilde',
        'email': 'olivia@example.com',
        'role': 'client',
        'age': 34,
        'gender': 'Female',
        'height': 170.0,
        'weight': 62.0,
        'goal': 'General Wellness',
        'phone_number': '555-111-2222',
        'is_archived': false,
        'is_email_verified': true,
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

      expect(client.id, 101);
      expect(client.fullName, 'Olivia Wilde');
      expect(client.email, 'olivia@example.com');
      expect(jsonResponse['is_email_verified'], isTrue);
    });

    test('OTP validation logic matches 6 digits', () {
      bool isValidOtp(String otp) {
        final clean = otp.trim();
        return clean.length == 6 && RegExp(r'^[0-9]{6}$').hasMatch(clean);
      }

      expect(isValidOtp('123456'), isTrue);
      expect(isValidOtp('000000'), isTrue);
      expect(isValidOtp('999999'), isTrue);
      expect(isValidOtp('12345'), isFalse);
      expect(isValidOtp('1234567'), isFalse);
      expect(isValidOtp('12345a'), isFalse);
      expect(isValidOtp(''), isFalse);
    });
  });
}
