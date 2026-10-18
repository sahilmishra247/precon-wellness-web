import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/user_role.dart';
import '../services/theme_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_colors.dart';
import 'consultation_notes_screen.dart';
import 'diet_plan_screen.dart';
import 'edit_client_screen.dart';
import 'progress_screen.dart';
import 'workout_plan_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;
  final UserRole role;

  const ClientDetailsScreen({super.key, required this.client, required this.role});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  double _calculateBMI() {
    if (widget.client.height <= 0) return 0.0;
    final h = widget.client.height / 100;
    return widget.client.weight / (h * h);
  }

  (String, Color) _getBMICategory(double bmi, bool isDark) {
    if (bmi <= 0) return ('N/A', AppColors.primary);
    if (bmi < 18.5) return ('Underweight', AppColors.info);
    if (bmi < 25.0) return ('Normal', AppColors.success);
    if (bmi < 30.0) return ('Overweight', AppColors.warning);
    return ('Obese', AppColors.error);
  }

  Future<void> _openEditScreen() async {
    final updated = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => EditClientScreen(client: widget.client)),
    );
    if (updated == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);
        final isClientView = widget.role.isClient;
        final bmi = _calculateBMI();
        final (bmiCategory, bmiColor) = _getBMICategory(bmi, isDark);

        return Scaffold(
          backgroundColor: AppColors.bg(isDark),
          appBar: AppBar(
            title: Text(
              isClientView ? 'My profile' : widget.client.fullName,
              style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.w600),
            ),
            actions: [
              ThemeToggleButton(color: AppColors.textSecondary(isDark)),
              IconButton(
                tooltip: 'Edit',
                icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary(isDark), size: 20),
                onPressed: _openEditScreen,
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // ── Profile header ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.brandMuted(isDark),
                          child: Text(
                            widget.client.fullName.isNotEmpty ? widget.client.fullName[0].toUpperCase() : 'C',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.brand(isDark)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.client.fullName,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark), letterSpacing: -0.3)),
                              const SizedBox(height: 3),
                              Text(widget.client.email,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
                              if (widget.client.goal.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandMuted(isDark),
                                    borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                                  ),
                                  child: Text(widget.client.goal,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand(isDark))),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Metrics ─────────────────────────────────────────────
                  _sectionLabel('Health & body metrics', isDark),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _metricTile('Weight', '${widget.client.weight} kg', 'Current weight', AppColors.brand(isDark), isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _metricTile('Height', '${widget.client.height.toInt()} cm', 'Standing height', AppColors.info, isDark)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _metricTile('BMI', bmi > 0 ? bmi.toStringAsFixed(1) : '—', bmiCategory, bmiColor, isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _metricTile('Age', '${widget.client.age} yrs', widget.client.gender.isNotEmpty ? widget.client.gender : 'N/A', AppColors.warning, isDark)),
                  ]),
                  const SizedBox(height: 24),

                  // ── Contact ─────────────────────────────────────────────
                  _sectionLabel('Contact information', isDark),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface(isDark),
                      borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                      border: Border.all(color: AppColors.border(isDark)),
                    ),
                    child: Column(children: [
                      _infoRow(Icons.phone_outlined, 'Phone', widget.client.phoneNumber.isNotEmpty ? widget.client.phoneNumber : '—', isDark),
                      Divider(height: 1, indent: 54, color: AppColors.border(isDark)),
                      _infoRow(Icons.email_outlined, 'Email', widget.client.email, isDark),
                      Divider(height: 1, indent: 54, color: AppColors.border(isDark)),
                      _infoRow(Icons.flag_outlined, 'Goal', widget.client.goal.isNotEmpty ? widget.client.goal : 'General Wellness', isDark),
                      Divider(height: 1, indent: 54, color: AppColors.border(isDark)),
                      _infoRow(Icons.circle_outlined, 'Status', widget.client.isArchived ? 'Archived' : 'Active', isDark),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: _openEditScreen,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit profile'),
                  ),

                  // ── Staff-only management tools ──────────────────────────
                  if (!isClientView) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('Client management', isDark),
                    const SizedBox(height: 10),
                    _navRow(Icons.note_outlined, 'Consultation notes', isDark, () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ConsultationNotesScreen(client: widget.client, authorName: widget.role.label, readOnly: false)))),
                    if (widget.role.canViewDietPlans) ...[
                      _divider(isDark),
                      _navRow(Icons.restaurant_outlined, 'Diet plan', isDark, () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DietPlanScreen(client: widget.client, readOnly: false)))),
                    ],
                    if (widget.role.canViewWorkoutPlans) ...[
                      _divider(isDark),
                      _navRow(Icons.fitness_center_outlined, 'Workout plan', isDark, () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => WorkoutPlanScreen(client: widget.client, readOnly: false)))),
                    ],
                    if (widget.role.canViewProgress) ...[
                      _divider(isDark),
                      _navRow(Icons.show_chart_rounded, 'Progress tracking', isDark, () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ProgressScreen(client: widget.client, readOnly: false)))),
                    ],
                    Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border(isDark))))),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Text(label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: AppColors.textSecondary(isDark)));

  Widget _metricTile(String label, String value, String subtitle, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark), letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textSecondary(isDark)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted(isDark), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary(isDark))),
        ]),
      ]),
    );
  }

  Widget _navRow(IconData icon, String title, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.textSecondary(isDark)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted(isDark)),
        ]),
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(height: 1, color: AppColors.border(isDark));
}
