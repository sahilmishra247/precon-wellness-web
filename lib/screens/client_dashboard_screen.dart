import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../models/user_role.dart';
import '../services/appointment_service.dart';
import '../services/theme_service.dart';
import '../services/session_manager.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/confirm_exit_scope.dart';
import '../utils/url_helper.dart';
import '../theme/app_colors.dart';
import '../layout/desktop.dart';
import 'consultation_notes_screen.dart';
import 'diet_plan_screen.dart';
import 'progress_screen.dart';
import 'workout_plan_screen.dart';
import 'educational_resources_screen.dart';
import 'appointments_screen.dart';
import 'client_details_screen.dart';
import 'login_screen.dart';
import 'desktop/client_workspace.dart';

class ClientDashboardScreen extends StatefulWidget {
  final Client client;
  const ClientDashboardScreen({super.key, required this.client});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final AppointmentService _appointmentService = AppointmentService();

  List<Appointment> _upcomingAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    try {
      final now = DateTime.now();
      final appointments = await _appointmentService.getAppointments(clientEmail: widget.client.email);
      final upcoming = appointments.where((a) => a.appointmentDate.isAfter(now)).toList()
        ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      if (mounted) {
        setState(() {
          _upcomingAppointments = upcoming;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateBMI() {
    if (widget.client.height <= 0) return 0.0;
    final hMeters = widget.client.height / 100;
    return widget.client.weight / (hMeters * hMeters);
  }

  (String, Color) _getBMICategory(double bmi) {
    if (bmi <= 0) return ('N/A', AppColors.primary);
    if (bmi < 18.5) return ('Underweight', AppColors.info);
    if (bmi < 25.0) return ('Normal', AppColors.success);
    if (bmi < 30.0) return ('Overweight', AppColors.warning);
    return ('Obese', AppColors.error);
  }

  @override
  Widget build(BuildContext context) {
    // Wide browser windows get the desktop split view; phones keep this layout.
    if (isDesktopLayout(context)) return ClientWorkspace(client: widget.client);

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);
        final bmi = _calculateBMI();
        final (bmiCategory, bmiColor) = _getBMICategory(bmi);
        final firstName = widget.client.fullName.split(' ').first;

        return ConfirmExitScope(
          child: Scaffold(
            backgroundColor: AppColors.bg(isDark),
            appBar: AppBar(
              title: Text(
                'My health',
                style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              actions: [
                ThemeToggleButton(color: AppColors.textSecondary(isDark)),
                IconButton(
                  tooltip: 'Log out',
                  icon: Icon(Icons.logout_rounded, color: AppColors.textSecondary(isDark), size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Log out?'),
                        content: const Text('Are you sure you want to log out of your account?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Log out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await SessionManager.clear();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          body: RefreshIndicator(
            onRefresh: _loadClientData,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $firstName',
                            style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(isDark), letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (widget.client.goal.isNotEmpty)
                            Text(
                              'Goal: ${widget.client.goal}',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark)),
                            ),
                        ],
                      ),
                    ),

                    // ── Metrics ───────────────────────────────────────────
                    _sectionLabel('Health metrics', isDark),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _metricTile('Initial weight', '${widget.client.weight} kg',
                            'See Progress tracking for current', isDark)),
                        const SizedBox(width: 10),
                        Expanded(child: _metricTile('Height', '${widget.client.height.toInt()} cm', null, isDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _metricTile(
                          'BMI',
                          bmi > 0 ? bmi.toStringAsFixed(1) : '—',
                          bmiCategory,
                          isDark,
                          accent: bmiColor,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _metricTile(
                          'Age',
                          '${widget.client.age} yrs',
                          widget.client.gender.isNotEmpty ? widget.client.gender : null,
                          isDark,
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Wellness tools ─────────────────────────────────────
                    _sectionLabel('Wellness tools', isDark),
                    const SizedBox(height: 10),
                    _navRow(icon: Icons.person_outline_rounded, title: 'My profile', isDark: isDark,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                              ClientDetailsScreen(client: widget.client, role: UserRole.client)));
                          _loadClientData();
                        }),
                    _divider(isDark),
                    _navRow(icon: Icons.note_alt_outlined, title: 'Consultation notes', isDark: isDark,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                            ConsultationNotesScreen(client: widget.client, authorName: widget.client.fullName, readOnly: true)))),
                    _divider(isDark),
                    _navRow(icon: Icons.restaurant_outlined, title: 'Diet plan', isDark: isDark,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                            DietPlanScreen(client: widget.client, readOnly: true)))),
                    _divider(isDark),
                    _navRow(icon: Icons.fitness_center_outlined, title: 'Workout plan', isDark: isDark,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                            WorkoutPlanScreen(client: widget.client, readOnly: true)))),
                    _divider(isDark),
                    _navRow(icon: Icons.show_chart_rounded, title: 'Progress tracking', isDark: isDark,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                              ProgressScreen(client: widget.client, readOnly: false)));
                          _loadClientData();
                        }),
                    _divider(isDark),
                    _navRow(icon: Icons.calendar_month_outlined, title: 'Appointments', isDark: isDark,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                              AppointmentsScreen(client: widget.client, readOnly: true)));
                          _loadClientData();
                        }),
                    _divider(isDark),
                    _navRow(icon: Icons.menu_book_outlined, title: 'Educational library', isDark: isDark,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EducationalResourcesScreen()))),
                    Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border(isDark))))),

                    // ── Upcoming appointments ──────────────────────────────
                    const SizedBox(height: 24),
                    _sectionLabel('Upcoming sessions', isDark),
                    const SizedBox(height: 10),

                    if (_isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                    else if (_upcomingAppointments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No upcoming consultations. Reach out to your coach to schedule a session.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark)),
                        ),
                      )
                    else
                      ..._upcomingAppointments.map((apt) => _appointmentTile(apt, isDark)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: AppColors.textSecondary(isDark)),
    );
  }

  Widget _metricTile(String label, String value, String? subtitle, bool isDark, {Color? accent}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark), letterSpacing: -0.3)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12, color: accent ?? AppColors.textMuted(isDark), fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _navRow({required IconData icon, required String title, required bool isDark, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary(isDark)),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(height: 1, color: AppColors.border(isDark));

  Widget _appointmentTile(Appointment apt, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.brand(isDark)),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(apt.appointmentDate),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark)),
              ),
            ],
          ),
          if (apt.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(apt.notes, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
          ],
          if (apt.meetingLink.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => UrlHelper.openUrl(context, apt.meetingLink),
              onLongPress: () => UrlHelper.copyToClipboard(context, apt.meetingLink),
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.video_call_rounded, size: 16, color: AppColors.brand(isDark)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        apt.meetingLink,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.brand(isDark),
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.brand(isDark),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded, size: 12, color: AppColors.brand(isDark)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} $hour:$minute';
  }
}
