import 'api_config.dart';
import '../models/client.dart';

class ClientService {
  Future<List<Client>> getClients({bool? isArchived}) async {
    final Map<String, dynamic> params = {'role': 'client'};
    if (isArchived != null) {
      params['is_archived'] = isArchived;
    }

    final response = await ApiConfig.dio.get(
      '/users',
      queryParameters: params,
    );

    final List<dynamic> data = response.data;
    return data.map((json) => Client.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<dynamic>> getUsers() async {
    final response = await ApiConfig.dio.get('/users');
    return response.data as List<dynamic>;
  }

  Future<Client> createClient({
    required String name,
    required String email,
    required String goal,
    required int age,
    required String gender,
    required double height,
    required double weight,
    String phoneNumber = '',
  }) async {
    final response = await ApiConfig.dio.post(
      '/users',
      data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': 'client123',
        'role': 'client',
        'age': age,
        'gender': gender.trim(),
        'height': height,
        'weight': weight,
        'goal': goal.trim(),
        'phone_number': phoneNumber.trim(),
      },
    );

    return Client.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Client> updateClient({
    required int id,
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? goal,
    String? phoneNumber,
    bool? isArchived,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (age != null) data['age'] = age;
    if (gender != null) data['gender'] = gender;
    if (height != null) data['height'] = height;
    if (weight != null) data['weight'] = weight;
    if (goal != null) data['goal'] = goal;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (isArchived != null) data['is_archived'] = isArchived;

    final response = await ApiConfig.dio.put(
      '/users/$id',
      data: data,
    );

    return Client.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> archiveClient(int id, {bool archive = true}) async {
    await ApiConfig.dio.put(
      '/users/$id/archive',
      queryParameters: {'archive': archive},
    );
  }

  Future<void> testConnection() async {
    await getUsers();
  }
}