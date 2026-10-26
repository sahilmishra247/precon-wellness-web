import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../services/theme_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/desktop_shell.dart';
import '../theme/app_colors.dart';

class EditClientScreen extends StatefulWidget {
  final Client client;
  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController genderController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  late TextEditingController goalController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  final ClientService clientService = ClientService();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.client.fullName);
    ageController = TextEditingController(text: widget.client.age.toString());
    genderController = TextEditingController(text: widget.client.gender);
    heightController = TextEditingController(text: widget.client.height.toString());
    weightController = TextEditingController(text: widget.client.weight.toString());
    goalController = TextEditingController(text: widget.client.goal);
    phoneController = TextEditingController(text: widget.client.phoneNumber);
    emailController = TextEditingController(text: widget.client.email);
  }

  @override
  void dispose() {
    nameController.dispose(); ageController.dispose(); genderController.dispose();
    heightController.dispose(); weightController.dispose(); goalController.dispose();
    phoneController.dispose(); emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final age = int.tryParse(ageController.text.trim());
    final height = double.tryParse(heightController.text.trim());
    final weight = double.tryParse(weightController.text.trim());

    if (nameController.text.trim().isEmpty || age == null || height == null ||
        weight == null || genderController.text.trim().isEmpty ||
        goalController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all fields correctly')));
      return;
    }

    setState(() => isSaving = true);

    try {
      if (widget.client.id != null) {
        await clientService.updateClient(
          id: widget.client.id!, name: nameController.text.trim(), age: age,
          gender: genderController.text.trim(), height: height, weight: weight,
          goal: goalController.text.trim(), phoneNumber: phoneController.text.trim(),
        );
      }

      widget.client.fullName = nameController.text.trim();
      widget.client.age = age; widget.client.gender = genderController.text.trim();
      widget.client.height = height; widget.client.weight = weight;
      widget.client.goal = goalController.text.trim(); widget.client.phoneNumber = phoneController.text.trim();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Client details updated'), backgroundColor: AppColors.success));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
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
              ? sideSheetAppBar(context, 'Edit client')
              : AppBar(
                  title: Text('Edit client', style: TextStyle(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w600, fontSize: 16)),
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
                      child: Text('Profile details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark), letterSpacing: -0.3)),
                    ),

                    _labeled('Full name', nameController, isDark),
                    const SizedBox(height: 16),

                    LayoutBuilder(builder: (context, constraints) {
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
                        _labeled('Gender', genderController, isDark),
                      ]);
                    }),
                    const SizedBox(height: 16),

                    LayoutBuilder(builder: (context, constraints) {
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
                        _labeled('Height (cm)', heightController, isDark, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        const SizedBox(height: 16),
                        _labeled('Weight (kg)', weightController, isDark, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      ]);
                    }),
                    const SizedBox(height: 16),

                    _labeled('Fitness goal', goalController, isDark),
                    const SizedBox(height: 16),
                    _labeled('Phone number', phoneController, isDark, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),

                    _label('Email', isDark),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      readOnly: true,
                      style: TextStyle(color: AppColors.textMuted(isDark)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.border(isDark).withValues(alpha: 0.5),
                        hintText: 'Email cannot be changed',
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveChanges,
                        child: isSaving
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save changes'),
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
