import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'client_dashboard_screen.dart';

import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'email_verification_screen.dart';
import 'reset_password_screen.dart';
import '../services/auth_service.dart';
import '../models/client.dart';
import '../models/user_role.dart';
import '../services/session_manager.dart';
import '../services/api_config.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/confirm_exit_scope.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool obscurePassword = true;
  bool isLoading = false;
  String? emailError;
  String? passwordError;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_validateEmail);
    passwordController.addListener(_validatePassword);
  }

  void _validateEmail() {
    final email = emailController.text;
    if (email.isEmpty) {
      setState(() => emailError = null);
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => emailError = 'Enter a valid email address');
    } else {
      setState(() => emailError = null);
    }
  }

  void _validatePassword() {
    final password = passwordController.text;
    if (password.isEmpty) {
      setState(() => passwordError = null);
      return;
    }
    if (password.length < 6) {
      setState(() => passwordError = 'Minimum 6 characters');
    } else {
      setState(() => passwordError = null);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailError != null || passwordError != null) {
      _showSnack('Please fix the errors before signing in', isError: true);
      return;
    }
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnack('Please fill in all fields', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.containsKey('error')) {
        if (response['error'] == 'EMAIL_NOT_VERIFIED') {
          _showSnack(
            response['message'] ?? 'Please verify your email address to continue.',
            isWarning: true,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(
                email: response['email'] ?? emailController.text.trim(),
              ),
            ),
          );
          return;
        }
        _showSnack(response['error'], isError: true);
        return;
      }

      if (response['role'] == 'client') {
        final client = Client(
          id: response['id'],
          fullName: response['name'] ?? '',
          age: response['age'] ?? 0,
          gender: response['gender'] ?? '',
          height: ((response['height'] ?? 0) as num).toDouble(),
          weight: ((response['weight'] ?? 0) as num).toDouble(),
          goal: response['goal'] ?? '',
          phoneNumber: response['phone_number'] ?? '',
          email: response['email'] ?? '',
        );

        await SessionManager.setUser(
          id: response['id'],
          userName: response['name'] ?? '',
          userEmail: response['email'] ?? '',
          userRole: response['role'] ?? 'client',
          jwtToken: response['access_token'],
          clientData: client,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ClientDashboardScreen(client: client)),
        );
      } else {
        await SessionManager.setUser(
          id: response['id'],
          userName: response['name'] ?? '',
          userEmail: response['email'] ?? '',
          userRole: response['role'] ?? 'admin',
          jwtToken: response['access_token'],
        );


        if (!mounted) return;
        final role = UserRole.values.firstWhere(
          (r) => r.name == response['role'],
          orElse: () => UserRole.admin,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(role: role)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      final msg = error is DioException && error.message != null
          ? error.message!
          : 'Connection error. Check server settings.';
      _showSnack(msg, isError: true);
    }

  }

  void _showSnack(String message, {bool isError = false, bool isWarning = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    if (isError) {
      bg = AppColors.error;
    } else if (isWarning) {
      bg = AppColors.warning;
    } else {
      bg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightTextPrimary;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
      ),
    );
  }

  void _showForgotPassword() {
    HapticFeedback.lightImpact();
    final resetEmailController = TextEditingController(text: emailController.text.trim());
    bool isSending = false;
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Reset password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Enter your account's email and we'll send you a reset code."),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Email address',
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        setDialogState(() => errorText = 'Enter a valid email address');
                        return;
                      }
                      setDialogState(() { isSending = true; errorText = null; });

                      final response = await authService.forgotPassword(email: email);

                      if (!dialogContext.mounted) return;
                      if (response.containsKey('error')) {
                        setDialogState(() {
                          isSending = false;
                          errorText = response['error']?.toString() ?? 'Failed to send reset code';
                        });
                        return;
                      }

                      Navigator.pop(dialogContext);
                      if (!mounted) return;
                      _showSnack('If an account exists for that email, a reset code has been sent.');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResetPasswordScreen(email: email),
                        ),
                      );
                    },
              child: isSending
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send code'),
            ),
          ],
        ),
      ),
    );
  }

  void _showServerSettings() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    bool isTesting = false;
    bool? testSuccess;
    String? testMessage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Server Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backend FastAPI server URL',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'http://172.20.28.159:8000',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Quick Presets',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _presetChip('Wi-Fi PC (172.20.28.159)', 'http://172.20.28.159:8000', controller, setDialogState),
                    _presetChip('USB Cable (127.0.0.1)', 'http://127.0.0.1:8000', controller, setDialogState),
                    _presetChip('Emulator (10.0.2.2)', 'http://10.0.2.2:8000', controller, setDialogState),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: isTesting
                      ? null
                      : () async {
                          setDialogState(() {
                            isTesting = true;
                            testSuccess = null;
                            testMessage = null;
                          });
                          final ok = await ApiConfig.testConnection(controller.text);
                          setDialogState(() {
                            isTesting = false;
                            testSuccess = ok;
                            testMessage = ok
                                ? 'Connected successfully'
                                : 'Connection failed — check IP & network';
                          });
                        },
                  icon: isTesting
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering_rounded, size: 16),
                  label: Text(isTesting ? 'Testing…' : 'Test Connection'),
                ),
                if (testMessage != null) ...[
                  const SizedBox(height: 10),
                  _statusBadge(testSuccess == true, testMessage!),
                ],
                const SizedBox(height: 10),
                Text(
                  'Tip: Connect PC and phone to the same Wi-Fi network.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted(Theme.of(context).brightness == Brightness.dark),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ApiConfig.setBaseUrl(controller.text);
                Navigator.pop(dialogContext);
                _showSnack('Server URL updated');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, String url, TextEditingController c, StateSetter s) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () => s(() {
        c.text = url;
      }),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _statusBadge(bool ok, String message) {
    final color = ok ? AppColors.success : AppColors.error;
    final bgColor = ok ? AppColors.successMuted : AppColors.errorMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoAccounts() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demo Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _demoTile('Admin', 'admin@precon.com', 'admin123', isDark),
            _divider(isDark),
            _demoTile('Coach', 'coach@precon.com', 'coach123', isDark),
            _divider(isDark),
            _demoTile('Dietician', 'dietician@precon.com', 'diet123', isDark),
            _divider(isDark),
            _demoTile('Client', 'john@gmail.com', 'client123', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 1,
    color: AppColors.border(isDark),
  );

  Widget _demoTile(String role, String email, String password, bool isDark) {
    return InkWell(
      onTap: () {
        emailController.text = email;
        passwordController.text = password;
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(AppColors.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$email  ·  $password',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.textMuted(isDark),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConfirmExitScope(
      child: Scaffold(
        backgroundColor: AppColors.bg(isDark),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppColors.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ThemeToggleButton(
                      color: AppColors.textSecondary(isDark),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary(isDark),
                        size: 20,
                      ),
                      tooltip: 'Server Settings',
                      onPressed: _showServerSettings,
                    ),
                  ],
                ),
                const SizedBox(height: AppColors.space32),

                // Logo + wordmark
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: AppColors.space16),

                Text(
                  'Precon Wellness',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(isDark),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppColors.space4),
                Text(
                  'Professional health & fitness management',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: AppColors.space48),

                // Form
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email
                      _label('Email address', isDark),
                      const SizedBox(height: AppColors.space8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: AppColors.textPrimary(isDark),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          errorText: emailError,
                        ),
                      ),
                      const SizedBox(height: AppColors.space16),

                      // Password row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _label('Password', isDark),
                          GestureDetector(
                            onTap: _showForgotPassword,
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.brand(isDark),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppColors.space8),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: TextStyle(
                          color: AppColors.textPrimary(isDark),
                          fontSize: 14,
                        ),
                        onSubmitted: (_) => login(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          errorText: passwordError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textMuted(isDark),
                            ),
                            onPressed: () =>
                                setState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppColors.space24),

                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          child: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign in'),
                        ),
                      ),
                      const SizedBox(height: AppColors.space16),

                      // Footer links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen()),
                            ),
                            child: Text(
                              'Create account',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brand(isDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppColors.space8),
                      Center(
                        child: TextButton(
                          onPressed: _showDemoAccounts,
                          child: Text(
                            'View demo credentials',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted(isDark),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _label(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary(isDark),
      ),
    );
  }
}