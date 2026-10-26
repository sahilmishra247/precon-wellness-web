import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_split_layout.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final phoneController = TextEditingController();

  final AuthService authService = AuthService();

  String selectedGender = 'Female';
  String selectedGoal = 'General Wellness';

  final List<String> genderOptions = const [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  final List<String> goalOptions = const [
    'General Wellness',
    'Weight Loss',
    'Muscle Building',
    'Endurance & Stamina',
    'Prenatal & Postnatal',
    'Flexibility & Mobility',
  ];

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  @override
  void initState() {
    super.initState();
    nameController.addListener(_validateName);
    emailController.addListener(_validateEmail);
    passwordController.addListener(_validatePassword);
    confirmPasswordController.addListener(_validateConfirmPassword);
  }

  void _validateName() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      setState(() => nameError = 'Full name is required');
    } else {
      setState(() => nameError = null);
    }
  }

  void _validateEmail() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() => emailError = 'Email address is required');
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
      setState(() => passwordError = 'Password is required');
      return;
    }
    if (password.length < 6) {
      setState(() => passwordError = 'Minimum 6 characters');
    } else {
      setState(() => passwordError = null);
    }
    if (confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }
  }

  void _validateConfirmPassword() {
    final confirm = confirmPasswordController.text;
    final password = passwordController.text;
    if (confirm != password) {
      setState(() => confirmPasswordError = 'Passwords do not match');
    } else {
      setState(() => confirmPasswordError = null);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    HapticFeedback.lightImpact();

    _validateName();
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();

    if (nameError != null || emailError != null || passwordError != null || confirmPasswordError != null) {
      _showSnack('Please fix the errors before continuing', isError: true);
      return;
    }

    if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      _showSnack('Please fill in all required fields', isError: true);
      return;
    }

    setState(() => isLoading = true);

    final int age = int.tryParse(ageController.text.trim()) ?? 0;
    final double height = double.tryParse(heightController.text.trim()) ?? 0.0;
    final double weight = double.tryParse(weightController.text.trim()) ?? 0.0;

    try {
      final response = await authService.registerClient(
        name: nameController.text.trim(),
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text,
        age: age,
        gender: selectedGender,
        height: height,
        weight: weight,
        goal: selectedGoal,
        phoneNumber: phoneController.text.trim(),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.containsKey('error')) {
        _showSnack(response['error'] ?? 'Registration failed', isError: true);
        return;
      }

      final int userId = response['id'] is int ? response['id'] : int.tryParse(response['id'].toString()) ?? 0;
      final String clientName = response['name'] ?? nameController.text.trim();
      final String clientEmail = response['email'] ?? emailController.text.trim().toLowerCase();

      final client = Client(
        id: userId,
        fullName: clientName,
        age: response['age'] ?? age,
        gender: response['gender'] ?? selectedGender,
        height: ((response['height'] ?? height) as num).toDouble(),
        weight: ((response['weight'] ?? weight) as num).toDouble(),
        goal: response['goal'] ?? selectedGoal,
        phoneNumber: response['phone_number'] ?? phoneController.text.trim(),
        email: clientEmail,
      );

      _showSnack('Account created! Check your email for the verification code.');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: clientEmail,
            userName: clientName,
            pendingClient: client,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnack('Error: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.error
            : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightTextPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
      ),
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
              onPressed: () => Navigator.pop(context),
            ),
            actions: [ThemeToggleButton(color: AppColors.textSecondary(isDark))],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create account',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(isDark),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start your wellness journey with Precon',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Section: Account ──────────────────────────────────
                      _sectionLabel('Account', isDark),
                      const SizedBox(height: 12),
                      _field('Full name', nameController, isDark, errorText: nameError),
                      const SizedBox(height: 12),
                      _field('Email address', emailController, isDark,
                          keyboardType: TextInputType.emailAddress, errorText: emailError),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 400;
                          if (wide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _passwordField('Password', passwordController, obscurePassword, isDark,
                                    onToggle: () => setState(() => obscurePassword = !obscurePassword),
                                    errorText: passwordError)),
                                const SizedBox(width: 12),
                                Expanded(child: _passwordField('Confirm', confirmPasswordController, obscureConfirmPassword, isDark,
                                    onToggle: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                                    errorText: confirmPasswordError)),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              _passwordField('Password', passwordController, obscurePassword, isDark,
                                  onToggle: () => setState(() => obscurePassword = !obscurePassword),
                                  errorText: passwordError),
                              const SizedBox(height: 12),
                              _passwordField('Confirm password', confirmPasswordController, obscureConfirmPassword, isDark,
                                  onToggle: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                                  errorText: confirmPasswordError),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Section: Health Profile ───────────────────────────
                      _sectionLabel('Health profile', isDark),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 400;
                          if (wide) {
                            return Row(
                              children: [
                                SizedBox(width: 100, child: _field('Age', ageController, isDark, keyboardType: TextInputType.number)),
                                const SizedBox(width: 12),
                                Expanded(child: _dropdown('Gender', selectedGender, genderOptions, isDark,
                                    onChanged: (v) { if (v != null) setState(() => selectedGender = v); })),
                              ],
                            );
                          }
                          return Column(children: [
                            _field('Age', ageController, isDark, keyboardType: TextInputType.number),
                            const SizedBox(height: 12),
                            _dropdown('Gender', selectedGender, genderOptions, isDark,
                                onChanged: (v) { if (v != null) setState(() => selectedGender = v); }),
                          ]);
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 400;
                          if (wide) {
                            return Row(
                              children: [
                                Expanded(child: _field('Height (cm)', heightController, isDark,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                                const SizedBox(width: 12),
                                Expanded(child: _field('Weight (kg)', weightController, isDark,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                              ],
                            );
                          }
                          return Column(children: [
                            _field('Height (cm)', heightController, isDark,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                            const SizedBox(height: 12),
                            _field('Weight (kg)', weightController, isDark,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          ]);
                        },
                      ),
                      const SizedBox(height: 12),
                      _dropdown('Fitness goal', selectedGoal, goalOptions, isDark,
                          onChanged: (v) { if (v != null) setState(() => selectedGoal = v); }),
                      const SizedBox(height: 12),
                      _field('Phone number', phoneController, isDark,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 28),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleSignup,
                          child: isLoading
                              ? const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Create account'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account?',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text('Sign in',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brand(isDark))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
      },
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textSecondary(isDark),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, bool isDark, {
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, isDark),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 14),
          decoration: InputDecoration(errorText: errorText),
        ),
      ],
    );
  }

  Widget _passwordField(String label, TextEditingController controller, bool obscure, bool isDark, {
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, isDark),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 14),
          decoration: InputDecoration(
            errorText: errorText,
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

  Widget _dropdown(String label, String value, List<String> items, bool isDark, {
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, isDark),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: value,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 14)),
          )).toList(),
          onChanged: onChanged,
          dropdownColor: AppColors.surface(isDark),
          style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 14),
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, bool isDark) {
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
