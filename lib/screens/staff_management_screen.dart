import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/staff_member.dart';
import '../services/staff_service.dart';
import '../services/theme_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/desktop_shell.dart';
import '../theme/app_colors.dart';
import '../utils/error_messages.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffService _staffService = StaffService();
  final TextEditingController _searchController = TextEditingController();

  List<StaffMember> _staff = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final staff = await _staffService.getStaff();
      if (mounted) setState(() { _staff = staff; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<StaffMember> get _filteredStaff {
    return _staff.where((m) {
      if (_selectedFilter == 'coach' && !m.isCoach) return false;
      if (_selectedFilter == 'dietician' && !m.isDietician) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return m.name.toLowerCase().contains(q) || m.email.toLowerCase().contains(q) || m.specialty.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Future<void> _deleteStaff(StaffMember member) async {
    HapticFeedback.lightImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete staff account?'),
        content: Text('Remove ${member.name} (${member.roleLabel})? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _staffService.deleteStaff(member.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${member.name} removed')));
        _loadStaff();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e)), backgroundColor: AppColors.error));
    }
  }

  void _showAddStaffDialog() {
    HapticFeedback.lightImpact();

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'staff123');
    final phoneController = TextEditingController();
    final specialtyController = TextEditingController();

    String selectedRole = 'coach';
    bool obscurePassword = true;
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = ThemeService.instance.isDark(context);

          return AlertDialog(
            title: const Text('Add staff account'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role selector
                    Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(isDark))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _roleToggle('Coach', 'coach', selectedRole, isDark, () {
                          setDialogState(() {
                            selectedRole = 'coach';
                            if (passwordController.text == 'diet123') passwordController.text = 'coach123';
                          });
                        })),
                        const SizedBox(width: 10),
                        Expanded(child: _roleToggle('Dietician', 'dietician', selectedRole, isDark, () {
                          setDialogState(() {
                            selectedRole = 'dietician';
                            if (passwordController.text == 'coach123') passwordController.text = 'diet123';
                          });
                        })),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name *')),
                    const SizedBox(height: 12),
                    TextField(controller: emailController, keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email address *')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Initial password *',
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                          onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: specialtyController,
                      decoration: InputDecoration(
                        labelText: selectedRole == 'coach' ? 'Specialty (e.g. Strength, HIIT)' : 'Specialty (e.g. Clinical Nutrition)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: phoneController, keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone (optional)')),

                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(dialogError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
              FilledButton(
                onPressed: isSubmitting ? null : () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim().toLowerCase();
                  final password = passwordController.text;

                  if (name.isEmpty) { setDialogState(() => dialogError = 'Name is required'); return; }
                  if (email.isEmpty || !email.contains('@')) { setDialogState(() => dialogError = 'Enter a valid email'); return; }
                  if (password.length < 6) { setDialogState(() => dialogError = 'Password must be 6+ characters'); return; }

                  setDialogState(() { isSubmitting = true; dialogError = null; });

                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _staffService.createStaff(
                      name: name, email: email, password: password, role: selectedRole,
                      phoneNumber: phoneController.text.trim(), specialty: specialtyController.text.trim(),
                    );
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    if (!mounted) return;
                    final roleTitle = selectedRole == 'coach' ? 'Coach' : 'Dietician';
                    messenger.showSnackBar(SnackBar(content: Text('$roleTitle account created for $name'), backgroundColor: AppColors.success));
                    _loadStaff();
                  } catch (e) {
                    setDialogState(() {
                      isSubmitting = false;
                      dialogError = e.toString().contains('already exists') ? 'A user with this email already exists' : describeError(e);
                    });
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create account'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _roleToggle(String label, String value, String current, bool isDark, VoidCallback onTap) {
    final selected = current == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandMuted(isDark) : AppColors.surface(isDark),
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
          border: Border.all(color: selected ? AppColors.brand(isDark) : AppColors.border(isDark), width: selected ? 1.5 : 1),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
            color: selected ? AppColors.brand(isDark) : AppColors.textSecondary(isDark),
          )),
        ),
      ),
    );
  }

  Widget _buildDesktop(bool isDark) {
    final staff = _filteredStaff;
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          PaneToolbar(
            title: 'Staff directory',
            subtitle: '${_staff.length} staff accounts',
            actions: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search staff',
                    isDense: true,
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted(isDark)),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _showAddStaffDialog,
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add staff'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  _filterChip('All', 'all', isDark),
                  const SizedBox(width: 8),
                  _filterChip('Coaches', 'coach', isDark),
                  const SizedBox(width: 8),
                  _filterChip('Dieticians', 'dietician', isDark),
                ]),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (_error != null)
                  Text('Could not load staff: $_error', style: const TextStyle(color: AppColors.error))
                else
                  PaneTable(
                    columns: const ['Name', 'Role', 'Email', 'Phone', 'Specialty'],
                    flex: const [3, 2, 4, 2, 3],
                    emptyText: 'No staff match',
                    rows: [
                      for (final m in staff)
                        PaneTableRow(
                          cells: [
                            Text(m.name, style: paneCellStyle(isDark, strong: true)),
                            Text(m.roleLabel, style: paneCellStyle(isDark)),
                            Text(m.email, style: paneCellStyle(isDark, muted: true), overflow: TextOverflow.ellipsis),
                            Text(m.phoneNumber.isEmpty ? '—' : m.phoneNumber, style: paneCellStyle(isDark, muted: true)),
                            Text(m.specialty.isEmpty ? '—' : m.specialty, style: paneCellStyle(isDark)),
                          ],
                          actions: [
                            RowAction(
                              icon: Icons.delete_outline_rounded,
                              tooltip: 'Delete account',
                              color: AppColors.error,
                              onPressed: () => _deleteStaff(m),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);

        if (DesktopPaneScope.of(context)) return _buildDesktop(isDark);

        return Scaffold(
          backgroundColor: AppColors.bg(isDark),
          appBar: AppBar(
            title: Text('Staff directory', style: TextStyle(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w600, fontSize: 16)),
            actions: [
              IconButton(icon: Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary(isDark)), tooltip: 'Refresh', onPressed: _loadStaff),
              ThemeToggleButton(color: AppColors.textSecondary(isDark)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddStaffDialog,
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Add staff'),
          ),
          body: RefreshIndicator(
            onRefresh: _loadStaff,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    // Search & Filter
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search staff…',
                              prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted(isDark)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted(isDark)),
                                      onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _filterChip('All', 'all', isDark),
                              const SizedBox(width: 8),
                              _filterChip('Coaches', 'coach', isDark),
                              const SizedBox(width: 8),
                              _filterChip('Dieticians', 'dietician', isDark),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(child: _buildBody(isDark)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String value, bool isDark) {
    final selected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(AppColors.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandMuted(isDark) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          border: Border.all(color: selected ? AppColors.brand(isDark) : AppColors.border(isDark)),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.brand(isDark) : AppColors.textSecondary(isDark),
        )),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: _loadStaff, icon: const Icon(Icons.refresh, size: 16), label: const Text('Try again')),
          ],
        ),
      ));
    }

    final list = _filteredStaff;
    if (list.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          _searchQuery.isNotEmpty ? 'No staff match "$_searchQuery".' : 'No staff accounts yet. Tap "Add staff" to get started.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark)),
          textAlign: TextAlign.center,
        ),
      ));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: list.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border(isDark)),
      itemBuilder: (context, index) {
        final member = list[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.brandMuted(isDark),
                child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : 'S',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.brand(isDark))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(member.name,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary(isDark)),
                        overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandMuted(isDark),
                        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                      ),
                      child: Text(member.roleLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brand(isDark))),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text(member.email, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
                  if (member.specialty.isNotEmpty)
                    Text(member.specialty, style: TextStyle(fontSize: 12, color: AppColors.textMuted(isDark))),
                ]),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                tooltip: 'Delete',
                onPressed: () => _deleteStaff(member),
              ),
            ],
          ),
        );
      },
    );
  }
}
