import 'package:flutter/material.dart';
import '../widgets/ui.dart';
import '../widgets/motion.dart';
import '../models/user_role.dart';
import '../services/appointment_service.dart';
import '../services/client_service.dart';
import '../services/theme_service.dart';
import '../services/session_manager.dart';
import '../widgets/confirm_exit_scope.dart';
import '../theme/app_colors.dart';
import '../layout/desktop.dart';
import 'add_client_screen.dart';
import 'appointments_screen.dart';
import 'archived_clients_screen.dart';
import 'clients_screen.dart';
import 'educational_resources_screen.dart';
import 'login_screen.dart';
import 'desktop/staff_workspace.dart';
import 'staff_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserRole role;
  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ClientService _clientService = ClientService();
  final AppointmentService _appointmentService = AppointmentService();

  int _activeClientCount = 0;
  int _appointmentCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final clients = await _clientService.getClients(isArchived: false);
      final appointments = await _appointmentService.getAppointments();
      if (mounted) {
        setState(() {
          _activeClientCount = clients.length;
          _appointmentCount = appointments.length;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wide browser windows get the desktop split view; phones keep this layout.
    if (isDesktopLayout(context)) return StaffWorkspace(role: widget.role);

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);

        return ConfirmExitScope(
          child: Scaffold(
            backgroundColor: AppColors.bg(isDark),
            appBar: AppBar(
              title: Text(
                widget.role.label,
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              actions: [
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
                        AppRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          body: RefreshIndicator(
            onRefresh: _loadStats,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      child: FadeSlideIn(
                        child: HeroBanner(
                          title: 'Dashboard',
                          subtitle: widget.role.canManageClients
                              ? 'Manage clients, programs and consultations'
                              : 'View client profiles, notes and assigned plans',
                        ),
                      ),
                    ),

                    // ── Stats ──────────────────────────────────────────────
                    FadeSlideIn(
                      index: 1,
                      child: Row(
                        children: [
                          Expanded(child: _statCard('Active clients', _isLoadingStats ? '…' : '$_activeClientCount', isDark)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard('Consultations', _isLoadingStats ? '…' : '$_appointmentCount', isDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Quick Actions ──────────────────────────────────────
                    if (widget.role.canManageClients) ...[
                      _sectionLabel('Quick actions', isDark),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _actionChip(
                            label: 'Add client',
                            icon: Icons.person_add_outlined,
                            isDark: isDark,
                            onTap: () async {
                              await Navigator.push(context, AppRoute(builder: (_) => const AddClientScreen()));
                              _loadStats();
                            },
                          ),
                          _actionChip(
                            label: 'New appointment',
                            icon: Icons.calendar_today_outlined,
                            isDark: isDark,
                            isPrimary: true,
                            onTap: () async {
                              await Navigator.push(context, AppRoute(builder: (_) => const AppointmentsScreen()));
                              _loadStats();
                            },
                          ),
                          if (widget.role.isAdmin)
                            _actionChip(
                              label: 'Staff directory',
                              icon: Icons.badge_outlined,
                              isDark: isDark,
                              onTap: () async {
                                await Navigator.push(context, AppRoute(builder: (_) => const StaffManagementScreen()));
                                _loadStats();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Navigation ─────────────────────────────────────────
                    _sectionLabel('Workspace', isDark),
                    const SizedBox(height: 10),
                    _navRow(
                      icon: Icons.people_outline_rounded,
                      title: widget.role.canManageClients ? 'Client directory' : 'Assigned clients',
                      isDark: isDark,
                      onTap: () async {
                        await Navigator.push(context, AppRoute(builder: (_) => ClientsScreen(role: widget.role)));
                        _loadStats();
                      },
                    ),
                    _divider(isDark),
                    _navRow(
                      icon: Icons.calendar_month_outlined,
                      title: 'Appointments & sessions',
                      isDark: isDark,
                      onTap: () async {
                        await Navigator.push(context, AppRoute(builder: (_) => const AppointmentsScreen()));
                        _loadStats();
                      },
                    ),
                    _divider(isDark),
                    _navRow(
                      icon: Icons.menu_book_outlined,
                      title: 'Educational library',
                      isDark: isDark,
                      onTap: () => Navigator.push(context, AppRoute(builder: (_) => const EducationalResourcesScreen())),
                    ),
                    if (widget.role.isAdmin) ...[
                      _divider(isDark),
                      _navRow(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Staff directory',
                        isDark: isDark,
                        onTap: () async {
                          await Navigator.push(context, AppRoute(builder: (_) => const StaffManagementScreen()));
                          _loadStats();
                        },
                      ),
                    ],
                    if (widget.role.canManageClients) ...[
                      _divider(isDark),
                      _navRow(
                        icon: Icons.archive_outlined,
                        title: 'Archived accounts',
                        isDark: isDark,
                        onTap: () async {
                          await Navigator.push(context, AppRoute(builder: (_) => const ArchivedClientsScreen()));
                          _loadStats();
                        },
                      ),
                    ],
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

  Widget _statCard(String title, String value, bool isDark) {
    final area = title.contains('Consult') ? AppColors.sessions : AppColors.progress;
    final icon = title.contains('Consult') ? Icons.event_note_rounded : Icons.people_alt_rounded;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: area.tint,
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: area.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: area.color, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const Spacer(),
          ]),
          const SizedBox(height: 14),
          CountUpText(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 13, color: area.ink, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy),
    );
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.brand(isDark) : AppColors.surface(isDark),
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
          border: Border.all(color: isPrimary ? AppColors.brand(isDark) : AppColors.border(isDark)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isPrimary ? Colors.white : AppColors.areaForIcon(icon).ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : AppColors.textPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navRow({required IconData icon, required String title, required bool isDark, required VoidCallback onTap}) {
    final area = AppColors.areaForIcon(icon);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: AppColors.lightBorderSubtle),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                IconChip(icon, area: area, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 15, color: AppColors.lightTextPrimary, fontWeight: FontWeight.w700)),
                ),
                Icon(Icons.arrow_forward_rounded, size: 18, color: area.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) => const SizedBox.shrink();
}
