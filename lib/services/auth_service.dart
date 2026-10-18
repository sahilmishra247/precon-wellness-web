import 'package:dio/dio.dart';
import 'api_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiConfig.dio.post(
        '/login',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('error')) {
          return Map<String, dynamic>.from(data);
        }
        if (data.containsKey('detail')) {
          return {'error': data['detail'].toString()};
        }
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {'error': 'Server response timed out. Please try again.'};
      }
      return {'error': e.message ?? 'Login failed. Check server connection.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }


  Future<Map<String, dynamic>> registerClient({
    required String name,
    required String email,
    required String password,
    int age = 0,
    String gender = '',
    double height = 0.0,
    double weight = 0.0,
    String goal = '',
    String phoneNumber = '',
  }) async {
    try {
      final response = await ApiConfig.dio.post(
        '/signup',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'role': 'client',
          'age': age,
          'gender': gender,
          'height': height,
          'weight': weight,
          'goal': goal.trim(),
          'phone_number': phoneNumber.trim(),
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('detail')) {
          return {'error': data['detail'].toString()};
        }
      }
      return {'error': e.message ?? 'Registration failed. Please try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await ApiConfig.dio.post(
        '/verify-email',
        data: {
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('detail')) {
          return {'error': data['detail'].toString()};
        }
      }
      return {'error': e.message ?? 'Email verification failed.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resendEmailOtp({
    required String email,
  }) async {
    try {
      final response = await ApiConfig.dio.post(
        '/resend-email-otp',
        data: {
          'email': email.trim().toLowerCase(),
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('detail')) {
          return {'error': data['detail'].toString()};
        }
      }
      return {'error': e.message ?? 'Failed to resend verification code.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await ApiConfig.dio.post(
        '/forgot-password',
        data: {
          'email': email.trim().toLowerCase(),
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('detail')) {
          return {'error': data['detail'].toString()};
        }
      }
      return {'error': e.message ?? 'Failed to send reset instructions.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await ApiConfig.dio.post(
        '/reset-password',
        data: {
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          'new_password': newPassword,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('detail')) {
          return {'error': data['detail'].toString()};
        }
      }
      return {'error': e.message ?? 'Failed to reset password.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
