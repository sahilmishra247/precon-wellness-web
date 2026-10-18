import 'app_data.dart';
import '../models/client.dart';
import '../models/user_role.dart';

class AuthSession {
  final UserRole role;
  final Client? client;

  const AuthSession({required this.role, this.client});
}

class AuthData {
  static const Map<String, ({String password, UserRole role})> users = {
    'admin@precon.com': (password: 'admin123', role: UserRole.admin),
    'coach@precon.com': (password: 'coach123', role: UserRole.coach),
    'dietician@precon.com': (password: 'diet123', role: UserRole.dietician),
  };

  static const String clientPassword = 'client123';

  static AuthSession? authenticate(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    final user = users[normalizedEmail];
    if (user == null || user.password != password) {
      final client = AppData.clients.where(
        (client) => client.email.trim().toLowerCase() == normalizedEmail,
      );
      if (password == clientPassword && client.isNotEmpty) {
        return AuthSession(role: UserRole.client, client: client.first);
      }
      return null;
    }
    return AuthSession(role: user.role);
  }
}
