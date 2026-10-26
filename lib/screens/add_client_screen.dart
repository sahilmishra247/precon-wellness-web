import 'package:flutter/material.dart';
import '../services/client_service.dart';
import '../services/theme_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/desktop_shell.dart';
import '../theme/app_colors.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final genderController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final goalController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final ClientService clientService = ClientService();
  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    genderController.dispose();
    heightController.dispose();
    weightController.dispose();
    goalController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    final age = int.tryParse(ageController.text.trim());
    final height = double.tryParse(heightController.text.trim());
    final weight = double.tryParse(weightController.text.trim());

    if (nameController.text.trim().isEmpty ||
        age == null || height == null || weight == null ||
        genderController.text.trim().isEmpty ||
        goalController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields with valid values')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await clientService.createClient(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        goal: goalController.text.trim(),
        age: age,
        gender: genderController.text.trim(),
        height: height,
        weight: weight,
        phoneNumber: phoneController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Client added successfully'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating client: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);

        return Scaffold(
          backgroundColor: AppColors.bg(isDark),
          appBar: SideSheetScope.of(context)
              ? sideSheetAppBar(context, 'Add client')
              : AppBar(
                  title: Text('Add client', style: TextStyle(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w600, fontSize: 16)),
                  actions: [ThemeToggleButton(color: AppColors.textSecondary(isDark))],
                ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Client details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark), letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text('Fill in all required fields to register a new client.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
                      ]),
                    ),

                    _label('Full name', isDark),
                    const SizedBox(height: 6),
                    TextField(controller: nameController, style: TextStyle(color: AppColors.textPrimary(isDark))),
                    const SizedBox(height: 16),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth > 440;
                        if (wide) {
                          return Row(children: [
                            Expanded(child: _labeled('Age', ageController, isDark, keyboardType: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(flex: 2, child: _labeled('Gender (e.g. Female, Male)', genderController, isDark)),
                          ]);
                        }
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _labeled('Age', ageController, isDark, keyboardType: TextInputType.number),
                          const SizedBox(height: 16),
                          _labeled('Gender (e.g. Female, Male)', genderController, isDark),
                        ]);
                      },
                    ),
                    const SizedBox(height: 16),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth > 440;
                        if (wide) {
                          return Row(children: [
                            Expanded(child: _labeled('Height (cm)', heightController, isDark,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                            const SizedBox(width: 12),
                            Expanded(child: _labeled('Weight (kg)', weightController, isDark,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                          ]);
                        }
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _labeled('Height (cm)', heightController, isDark,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          const SizedBox(height: 16),
                          _labeled('Weight (kg)', weightController, isDark,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        ]);
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Fitness goal', isDark),
                    const SizedBox(height: 6),
                    TextField(controller: goalController,
                        style: TextStyle(color: AppColors.textPrimary(isDark)),
                        decoration: const InputDecoration(hintText: 'e.g. Weight Loss, Muscle Building')),
                    const SizedBox(height: 16),

                    _label('Phone number', isDark),
                    const SizedBox(height: 6),
                    TextField(controller: phoneController, keyboardType: TextInputType.phone,
                        style: TextStyle(color: AppColors.textPrimary(isDark))),
                    const SizedBox(height: 16),

                    _label('Email address', isDark),
                    const SizedBox(height: 6),
                    TextField(controller: emailController, keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: AppColors.textPrimary(isDark))),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveClient,
                        child: isSaving
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save client'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text, bool isDark) => Text(text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary(isDark)));

  Widget _labeled(String label, TextEditingController controller, bool isDark, {TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label, isDark),
      const SizedBox(height: 6),
      TextField(controller: controller, keyboardType: keyboardType, style: TextStyle(color: AppColors.textPrimary(isDark))),
    ]);
  }
}
