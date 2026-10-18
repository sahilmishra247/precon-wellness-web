import 'package:flutter_test/flutter_test.dart';
import 'package:precon_wellness/models/staff_member.dart';

void main() {
  group('Staff Management & Model Tests', () {
    test('StaffMember fromJson correctly parses coach account', () {
      final json = {
        'id': 10,
        'name': 'Coach Marcus',
        'email': 'marcus@precon.com',
        'role': 'coach',
        'phone_number': '555-0199',
        'specialty': 'Strength & Conditioning',
        'is_email_verified': true,
      };

      final staff = StaffMember.fromJson(json);

      expect(staff.id, 10);
      expect(staff.name, 'Coach Marcus');
      expect(staff.email, 'marcus@precon.com');
      expect(staff.role, 'coach');
      expect(staff.isCoach, isTrue);
      expect(staff.isDietician, isFalse);
      expect(staff.roleLabel, 'Fitness Coach');
      expect(staff.phoneNumber, '555-0199');
      expect(staff.specialty, 'Strength & Conditioning');
      expect(staff.isEmailVerified, isTrue);
    });

    test('StaffMember fromJson correctly parses dietician account', () {
      final json = {
        'id': 11,
        'name': 'Dr. Sarah Lin',
        'email': 'sarah@precon.com',
        'role': 'dietician',
        'phone_number': '555-0200',
        'specialty': 'Clinical Nutrition',
        'is_email_verified': true,
      };

      final staff = StaffMember.fromJson(json);

      expect(staff.id, 11);
      expect(staff.name, 'Dr. Sarah Lin');
      expect(staff.email, 'sarah@precon.com');
      expect(staff.role, 'dietician');
      expect(staff.isDietician, isTrue);
      expect(staff.isCoach, isFalse);
      expect(staff.roleLabel, 'Dietician');
      expect(staff.specialty, 'Clinical Nutrition');
    });

    test('StaffMember toJson produces matching payload', () {
      const staff = StaffMember(
        id: 15,
        name: 'Alex Rivera',
        email: 'alex@precon.com',
        role: 'coach',
        phoneNumber: '555-4321',
        specialty: 'Endurance',
        isEmailVerified: true,
      );

      final json = staff.toJson();

      expect(json['id'], 15);
      expect(json['name'], 'Alex Rivera');
      expect(json['email'], 'alex@precon.com');
      expect(json['role'], 'coach');
      expect(json['phone_number'], '555-4321');
      expect(json['specialty'], 'Endurance');
      expect(json['is_email_verified'], isTrue);
    });

    test('Staff filtering logic by role and search query', () {
      final staffList = [
        const StaffMember(
          id: 1,
          name: 'Alex Johnson',
          email: 'alex@precon.com',
          role: 'coach',
          specialty: 'Cardio',
        ),
        const StaffMember(
          id: 2,
          name: 'Bella Thorne',
          email: 'bella@precon.com',
          role: 'dietician',
          specialty: 'Keto & Low-Carb',
        ),
        const StaffMember(
          id: 3,
          name: 'Chris Hemsworth',
          email: 'chris@precon.com',
          role: 'coach',
          specialty: 'Hypertrophy',
        ),
      ];

      // Filter only coaches
      final coaches = staffList.where((s) => s.role == 'coach').toList();
      expect(coaches.length, 2);
      expect(coaches.map((c) => c.name), containsAll(['Alex Johnson', 'Chris Hemsworth']));

      // Filter only dieticians
      final dieticians = staffList.where((s) => s.role == 'dietician').toList();
      expect(dieticians.length, 1);
      expect(dieticians.first.name, 'Bella Thorne');

      // Search by specialty
      final ketoStaff = staffList
          .where((s) =>
              s.name.toLowerCase().contains('keto') ||
              s.specialty.toLowerCase().contains('keto'))
          .toList();
      expect(ketoStaff.length, 1);
      expect(ketoStaff.first.name, 'Bella Thorne');
    });
  });
}
