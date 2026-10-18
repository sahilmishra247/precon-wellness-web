import 'package:flutter_test/flutter_test.dart';
import 'package:precon_wellness/data/auth_data.dart';
import 'package:precon_wellness/models/user_role.dart';

void main() {
  test('hardcoded users authenticate with the expected roles', () {
    expect(
      AuthData.authenticate('admin@precon.com', 'admin123')?.role,
      UserRole.admin,
    );
    expect(
      AuthData.authenticate('coach@precon.com', 'coach123')?.role,
      UserRole.coach,
    );
    expect(
      AuthData.authenticate('dietician@precon.com', 'diet123')?.role,
      UserRole.dietician,
    );
  });

  test('client users authenticate to their own client record', () {
    final session = AuthData.authenticate('john@gmail.com', 'client123');

    expect(session?.role, UserRole.client);
    expect(session?.client?.fullName, 'John Smith');
  });

  test('invalid credentials are rejected', () {
    expect(AuthData.authenticate('admin@precon.com', 'wrong'), isNull);
    expect(AuthData.authenticate('unknown@precon.com', 'admin123'), isNull);
  });
}
