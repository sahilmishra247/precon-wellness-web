import 'package:flutter/material.dart';
import 'models/user_role.dart';
import 'screens/client_dashboard_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_config.dart';
import 'services/session_manager.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();
  await SessionManager.init();
  runApp(const PreconWellnessApp());
}


class PreconWellnessApp extends StatelessWidget {
  const PreconWellnessApp({super.key});

  Widget _getInitialScreen() {
    if (SessionManager.isLoggedIn) {
      if (SessionManager.role == 'client' && SessionManager.client != null) {
        return ClientDashboardScreen(client: SessionManager.client!);
      } else if (SessionManager.role != null && SessionManager.role != 'client') {
        final role = UserRole.values.firstWhere(
          (r) => r.name == SessionManager.role,
          orElse: () => UserRole.admin,
        );
        return DashboardScreen(role: role);
      }
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Precon Wellness',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          home: _getInitialScreen(),
        );
      },
    );
  }
}
