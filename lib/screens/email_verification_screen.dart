import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/theme_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_split_layout.dart';
import 'client_dashboard_screen.dart';
import 'login_screen.dart';
import '../utils/error_messages.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? userName;
  final Client? pendingClient;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.userName,
    this.pendingClient,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  Timer? _resendTimer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  void _startResendCountdown() {
    setState(() => _secondsRemaining = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    setState(() => _errorMessage = null);

    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < 6 && i < digits.length; i++) {
          _controllers[i].text = digits[i];
        }
        final nextFocus = digits.length < 6 ? digits.length : 5;
        _focusNodes[nextFocus].requestFocus();
        if (digits.length >= 6) _handleVerify();
        return;
      }
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentOtp.length == 6) _handleVerify();
      }
    }
  }

  Future<void> _handleVerify() async {
    final otp = _currentOtp.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final response = await _authService.verifyEmail(email: widget.email, otp: otp);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.containsKey('error')) {
        setState(() => _errorMessage = response['error']?.toString() ?? 'Verification failed');
        return;
      }

      final userData = response['user'] as Map<String, dynamic>? ?? {};
      final int userId = userData['id'] is int
          ? userData['id']
          : int.tryParse(userData['id']?.toString() ?? '') ?? widget.pendingClient?.id ?? 0;
      final String clientName = userData['name'] ?? widget.userName ?? widget.pendingClient?.fullName ?? 'Client';
      final String clientEmail = userData['email'] ?? widget.email;
      final String? jwtToken = response['access_token'];

      final client = widget.pendingClient ?? Client(
        id: userId, fullName: clientName,
        age: userData['age'] ?? 0, gender: userData['gender'] ?? '',
        height: ((userData['height'] ?? 0) as num).toDouble(),
        weight: ((userData['weight'] ?? 0) as num).toDouble(),
        goal: userData['goal'] ?? '', phoneNumber: userData['phone_number'] ?? '',
        email: clientEmail,
      );

      await SessionManager.setUser(
        id: userId,
        userName: clientName,
        userEmail: clientEmail,
        userRole: 'client',
        jwtToken: jwtToken,
        clientData: client,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(

        content: Text('Welcome, $clientName!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
      ));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ClientDashboardScreen(client: client)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = describeError(e); });
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResending) return;
    setState(() { _isResending = true; _errorMessage = null; });

    try {
      final response = await _authService.resendEmailOtp(email: widget.email);
      if (!mounted) return;
      setState(() => _isResending = false);

      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['error'] ?? 'Failed to resend code'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('New verification code sent!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
      ));

      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _startResendCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(describeError(e)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);

        return AuthSplitLayout(child: Scaffold(
          backgroundColor: AppColors.bg(isDark),
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary(isDark)),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              ),
            ),
            actions: [ThemeToggleButton(color: AppColors.textSecondary(isDark))],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.brandMuted(isDark),
                        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                        border: Border.all(color: AppColors.brand(isDark).withValues(alpha: 0.25)),
                      ),
                      child: Icon(Icons.mark_email_unread_outlined, size: 26, color: AppColors.brand(isDark)),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Check your email',
                      style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(isDark), letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "We've sent a 6-digit code to",
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.email,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.brand(isDark)),
                    ),
                    const SizedBox(height: 32),

                    // OTP boxes
                    Row(
                      children: List.generate(6, (index) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                          child: SizedBox(
                            height: 54,
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey == LogicalKeyboardKey.backspace) {
                                  if (_controllers[index].text.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                }
                              },
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 6,
                                style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(isDark),
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  fillColor: AppColors.inputFill(isDark),
                                  filled: true,
                                ),
                                onChanged: (v) => _onDigitChanged(index, v),
                              ),
                            ),
                          ),
                        ),
                      )),
                    ),
                    const SizedBox(height: 16),

                    // Error
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.errorMuted,
                          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: AppColors.error))),
                          ],
                        ),
                      ),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
                        child: _isLoading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Verify & continue'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Resend
                    if (_secondsRemaining > 0)
                      Text(
                        'Resend code in ${_secondsRemaining}s',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted(isDark)),
                      )
                    else
                      TextButton(
                        onPressed: _isResending ? null : _handleResend,
                        child: _isResending
                            ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Resend code'),
                      ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      ),
                      child: Text('Use a different account',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted(isDark))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
      },
    );
  }
}
