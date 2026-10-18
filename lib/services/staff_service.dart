import 'api_config.dart';
import '../models/staff_member.dart';

class StaffService {
  Future<List<StaffMember>> getStaff({String? role}) async {
    final Map<String, dynamic> params = {};
    if (role != null && role.isNotEmpty) {
      params['role'] = role.toLowerCase();
    }

    final response = await ApiConfig.dio.get(
      '/users',
      queryParameters: params.isNotEmpty ? params : null,
    );

    final List<dynamic> data = response.data;
    final staff = data
        .map((json) => StaffMember.fromJson(json as Map<String, dynamic>))
        .where((user) {
          if (role != null && role.isNotEmpty) {
            return user.role.toLowerCase() == role.toLowerCase();
          }
          return user.isCoach || user.isDietician;
        })
        .toList();

    return staff;
  }

  Future<StaffMember> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
    String phoneNumber = '',
    String specialty = '',
  }) async {
    final response = await ApiConfig.dio.post(
      '/users',
      data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role.toLowerCase(),
        'phone_number': phoneNumber.trim(),
        'goal': specialty.trim(),
        'age': 30,
        'gender': 'Other',
        'height': 0.0,
        'weight': 0.0,
      },
    );

    return StaffMember.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteStaff(int id) async {
    await ApiConfig.dio.delete('/users/$id');
  }
}
