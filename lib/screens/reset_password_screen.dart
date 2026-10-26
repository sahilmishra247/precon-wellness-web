import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_split_layout.dart';
import 'login_screen.dart';
import '../utils/error_messages.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthService _authService = AuthService();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
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
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _currentOtp => _otpControllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    setState(() => _errorMessage = null);

    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < 6 && i < digits.length; i++) {
          _otpControllers[i].text = digits[i];
        }
        final nextFocus = digits.length < 6 ? digits.length : 5;
        _otpFocusNodes[nextFocus].requestFocus();
        return;
      }
    }

    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isNotEmpty) {
      _otpFocusNodes[index].unfocus();
    }
  }

  Future<void> _handleReset() async {
    final otp = _currentOtp.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final response = await _authService.resetPassword(
        email: widget.email,
        otp: otp,
        newPassword: newPassword,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.containsKey('error')) {
        setState(() => _errorMessage = response['error']?.toString() ?? 'Reset failed');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Password reset successfully. Please log in.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
      ));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
      final response = await _authService.forgotPassword(email: widget.email);
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
        content: const Text('New reset code sent!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
      ));

      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
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

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary(isDark))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 14),
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18, color: AppColors.textMuted(isDark),
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.brandMuted(isDark),
                        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                        border: Border.all(color: AppColors.brand(isDark).withValues(alpha: 0.25)),
                      ),
                      child: Icon(Icons.lock_reset_rounded, size: 26, color: AppColors.brand(isDark)),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Reset your password',
                      style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(isDark), letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Enter the 6-digit code we sent to",
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
                                  if (_otpControllers[index].text.isEmpty && index > 0) {
                                    _otpFocusNodes[index - 1].requestFocus();
                                  }
                                }
                              },
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _otpFocusNodes[index],
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
                    const SizedBox(height: 20),

                    _passwordField(
                      label: 'New password',
                      controller: _newPasswordController,
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _passwordField(
                      label: 'Confirm new password',
                      controller: _confirmPasswordController,
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

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

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleReset,
                        child: _isLoading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Reset password'),
                      ),
                    ),
                    const SizedBox(height: 20),

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
                      child: Text('Back to login',
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
