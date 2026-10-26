import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../models/health_tag.dart';
import '../../models/user_role.dart';
import '../../services/client_service.dart';
import '../../services/health_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_exit_scope.dart';
import '../../widgets/desktop_shell.dart';
import '../../widgets/health_tags.dart';
import '../add_client_screen.dart';
import '../appointments_screen.dart';
import '../archived_clients_screen.dart';
import '../consultation_notes_screen.dart';
import '../diet_plan_screen.dart';
import '../edit_client_screen.dart';
import '../educational_resources_screen.dart';
import '../progress_screen.dart';
import '../staff_management_screen.dart';
import '../workout_plan_screen.dart';
import 'client_overview.dart';
import '../../utils/error_messages.dart';

enum _Section { clients, appointments, library, staff, archived }

enum _ClientTab { overview, notes, diet, workout, progress, sessions }

/// Desktop layout for admins, coaches and dieticians: icon rail, a client
/// list that can be hidden, and the selected client's record with tabs.
class StaffWorkspace extends StatefulWidget {
  final UserRole role;
  const StaffWorkspace({super.key, required this.role});

  @override
  State<StaffWorkspace> createState() => _StaffWorkspaceState();
}

class _StaffWorkspaceState extends State<StaffWorkspace> {
  // Kept across rebuilds of the workspace (e.g. resizing the window).
  static bool _listHidden = false;

  static const double _listWidth = 320;

  final ClientService _clientService = ClientService();
  final HealthService _healthService = HealthService();
  final _searchController = TextEditingController();

  _Section _section = _Section.clients;
  _ClientTab _tab = _ClientTab.overview;
  List<Client> _clients = [];
  Client? _selected;
  bool _isLoading = true;
  String _query = '';

  // Bumped after edits so the open client's panes reload.
  int _detailVersion = 0;

  List<_Section> get _sections => [
        _Section.clients,
        _Section.appointments,
        _Section.library,
        if (widget.role.isAdmin) _Section.staff,
        if (widget.role.canManageClients) _Section.archived,
      ];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final results = await Future.wait([
        _clientService.getClients(isArchived: false),
        // Tags are a nice-to-have here; the list still loads without them.
        _healthService.getAllTags().catchError((_) => <String, List<HealthTag>>{}),
      ]);
      final clients = results[0] as List<Client>;
      final tags = results[1] as Map<String, List<HealthTag>>;
      for (final c in clients) {
        c.healthTags = tags[c.email.toLowerCase()] ?? [];
      }
      clients.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _isLoading = false;
        if (_selected != null) {
          final match = clients.where((c) => c.id == _selected!.id);
          _selected = match.isNotEmpty ? match.first : null;
        }
        _selected ??= clients.isNotEmpty ? clients.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load clients: ${describeError(e)}')));
    }
  }

  List<Client> get _filtered {
    final q = _query.toLowerCase();
    if (q.isEmpty) return _clients;
    return _clients.where((c) =>
        c.fullName.toLowerCase().contains(q) ||
        c.email.toLowerCase().contains(q) ||
        c.goal.toLowerCase().contains(q) ||
        c.healthTags.any((t) => t.label.toLowerCase().contains(q)) ||
        c.phoneNumber.contains(_query)).toList();
  }

  List<_ClientTab> get _tabs => [
        _ClientTab.overview,
        _ClientTab.notes,
        if (widget.role.canViewDietPlans) _ClientTab.diet,
        if (widget.role.canViewWorkoutPlans) _ClientTab.workout,
        if (widget.role.canViewProgress) _ClientTab.progress,
        _ClientTab.sessions,
      ];

  void _toggleList() => setState(() => _listHidden = !_listHidden);

  Future<void> _addClient() async {
    await showSideSheet(context, const AddClientScreen());
    _loadClients();
  }

  Future<void> _editClient(Client client) async {
    final updated = await showSideSheet<bool>(context, EditClientScreen(client: client));
    if (updated == true) {
      setState(() => _detailVersion++);
      _loadClients();
    }
  }

  Future<void> _archiveClient(Client client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive client?'),
        content: Text('${client.fullName} will be moved to the archive. You can restore them at any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirm != true || client.id == null) return;
    try {
      await _clientService.archiveClient(client.id!, archive: true);
      setState(() => _selected = null);
      await _loadClients();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${client.fullName} archived')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);
        final sections = _sections;

        return ConfirmExitScope(
          child: Scaffold(
            backgroundColor: AppColors.bg(isDark),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IconRail(
                  isDark: isDark,
                  selectedIndex: sections.indexOf(_section),
                  onSelected: (i) {
                    final leavingArchive = _section == _Section.archived;
                    setState(() => _section = sections[i]);
                    // Restoring from the archive changes the client list.
                    if (leavingArchive) _loadClients();
                  },
                  destinations: [
                    for (final s in sections) _destination(s),
                  ],
                ),
                Expanded(child: _content(isDark)),
              ],
            ),
          ),
        );
      },
    );
  }

  RailDestination _destination(_Section s) {
    switch (s) {
      case _Section.clients:
        return RailDestination(Icons.people_outline_rounded, widget.role.isAdmin ? 'Clients' : 'Assigned clients');
      case _Section.appointments:
        return const RailDestination(Icons.calendar_month_outlined, 'Appointments & sessions');
      case _Section.library:
        return const RailDestination(Icons.menu_book_outlined, 'Educational library');
      case _Section.staff:
        return const RailDestination(Icons.manage_accounts_outlined, 'Staff directory');
      case _Section.archived:
        return const RailDestination(Icons.archive_outlined, 'Archived accounts');
    }
  }

  Widget _content(bool isDark) {
    switch (_section) {
      case _Section.clients:
        return _clientsView(isDark);
      case _Section.appointments:
        return const PaneNavigator(key: ValueKey('appointments'), child: AppointmentsScreen());
      case _Section.library:
        return const PaneNavigator(key: ValueKey('library'), child: EducationalResourcesScreen());
      case _Section.staff:
        return const PaneNavigator(key: ValueKey('staff'), child: StaffManagementScreen());
      case _Section.archived:
        return const PaneNavigator(key: ValueKey('archived'), child: ArchivedClientsScreen());
    }
  }

  // ── Clients: list pane + details pane ─────────────────────────────────────

  Widget _clientsView(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: _listHidden ? 0 : _listWidth,
          decoration: BoxDecoration(
            color: AppColors.surface(isDark),
            border: Border(right: BorderSide(color: AppColors.border(isDark))),
          ),
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: _listWidth,
              maxWidth: _listWidth,
              child: _listPane(isDark),
            ),
          ),
        ),
        Expanded(child: _detailsPane(isDark)),
      ],
    );
  }

  Widget _listPane(bool isDark) {
    final clients = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
          child: Row(children: [
            Text(widget.role.isAdmin ? 'Clients' : 'Assigned clients',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark))),
            const SizedBox(width: 8),
            if (!_isLoading)
              Text('${_clients.length}', style: TextStyle(fontSize: 13, color: AppColors.textMuted(isDark))),
            const Spacer(),
            if (widget.role.canManageClients)
              IconButton(
                tooltip: 'Add client',
                icon: Icon(Icons.person_add_outlined, size: 20, color: AppColors.brand(isDark)),
                onPressed: _addClient,
              ),
            IconButton(
              tooltip: 'Hide client list',
              icon: Icon(Icons.keyboard_double_arrow_left_rounded, size: 20, color: AppColors.textSecondary(isDark)),
              onPressed: _toggleList,
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search name, goal or condition…',
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted(isDark)),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted(isDark)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        Divider(height: 1, color: AppColors.border(isDark)),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : clients.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _query.isEmpty ? 'No active clients yet.' : 'No clients match "$_query".',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, i) => _clientRow(clients[i], isDark),
                    ),
        ),
      ],
    );
  }

  Widget _clientRow(Client client, bool isDark) {
    final selected = _selected?.id == client.id;
    return Material(
      color: selected ? AppColors.brandMuted(isDark) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = client),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: selected ? AppColors.brand(isDark) : Colors.transparent, width: 3),
              bottom: BorderSide(color: AppColors.border(isDark).withValues(alpha: 0.5)),
            ),
          ),
          child: Row(children: [
            _avatar(client, isDark, 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(client.fullName, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
                const SizedBox(height: 1),
                Text(client.goal.isNotEmpty ? client.goal : client.email, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark))),
                if (client.healthTags.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  HealthTagRow(tags: client.healthTags, isDark: isDark, max: 2, small: true),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _avatar(Client client, bool isDark, double radius) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.brandMuted(isDark),
        child: Text(
          _initials(client.fullName),
          style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.w700, color: AppColors.brand(isDark)),
        ),
      );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  Widget _detailsPane(bool isDark) {
    final client = _selected;
    if (client == null) {
      return Column(children: [
        if (_listHidden) _showListBar(isDark),
        Expanded(
          child: Center(
            child: Text(
              _isLoading ? '' : 'Select a client to see their details.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark)),
            ),
          ),
        ),
      ]);
    }

    final tabs = _tabs;
    final tab = tabs.contains(_tab) ? _tab : _ClientTab.overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.surface(isDark),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (_listHidden) ...[
                IconButton(
                  tooltip: 'Show client list',
                  icon: Icon(Icons.keyboard_double_arrow_right_rounded, size: 20, color: AppColors.textSecondary(isDark)),
                  onPressed: _toggleList,
                ),
                const SizedBox(width: 4),
              ],
              _avatar(client, isDark, 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(client.fullName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3,
                          color: AppColors.textPrimary(isDark))),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (client.goal.isNotEmpty) client.goal,
                      if (client.age > 0) '${client.age} yrs',
                      client.email,
                      if (client.phoneNumber.isNotEmpty) client.phoneNumber,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark)),
                  ),
                  if (client.healthTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    HealthTagRow(tags: client.healthTags, isDark: isDark),
                  ],
                ]),
              ),
              const SizedBox(width: 12),
              if (widget.role.canManageClients) ...[
                TextButton.icon(
                  onPressed: () => _archiveClient(client),
                  icon: const Icon(Icons.archive_outlined, size: 16),
                  label: const Text('Archive'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary(isDark)),
                ),
                const SizedBox(width: 6),
              ],
              OutlinedButton.icon(
                onPressed: () => _editClient(client),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit profile'),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [for (final t in tabs) _tabButton(t, t == tab, isDark)]),
          ]),
        ),
        Divider(height: 1, color: AppColors.border(isDark)),
        Expanded(child: _tabContent(client, tab, isDark)),
      ],
    );
  }

  Widget _showListBar(bool isDark) => Container(
        color: AppColors.surface(isDark),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _toggleList,
          icon: const Icon(Icons.keyboard_double_arrow_right_rounded, size: 18),
          label: const Text('Show client list'),
        ),
      );

  String _tabLabel(_ClientTab t) {
    switch (t) {
      case _ClientTab.overview:
        return 'Overview';
      case _ClientTab.notes:
        return 'Consultation notes';
      case _ClientTab.diet:
        return widget.role.canEditDietPlans ? 'Diet plan' : 'Diet plan (view)';
      case _ClientTab.workout:
        return widget.role.canEditWorkoutPlans ? 'Workout plan' : 'Workout plan (view)';
      case _ClientTab.progress:
        return 'Progress';
      case _ClientTab.sessions:
        return 'Sessions';
    }
  }

  Widget _tabButton(_ClientTab t, bool selected, bool isDark) {
    return InkWell(
      onTap: () => setState(() => _tab = t),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? AppColors.brand(isDark) : Colors.transparent, width: 2)),
        ),
        child: Text(
          _tabLabel(t),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.brand(isDark) : AppColors.textSecondary(isDark),
          ),
        ),
      ),
    );
  }

  Widget _tabContent(Client client, _ClientTab tab, bool isDark) {
    final key = ValueKey('${client.id}-${tab.name}-$_detailVersion');
    switch (tab) {
      case _ClientTab.overview:
        return ClientOverview(
          key: key,
          client: client,
          isDark: isDark,
          onOpenProgress: widget.role.canViewProgress ? () => setState(() => _tab = _ClientTab.progress) : null,
          progressActionLabel: widget.role.canEditProgress ? 'Log weight' : 'Open progress',
          onHealthChanged: (tags) => setState(() => client.healthTags = tags),
        );
      case _ClientTab.notes:
        return PaneNavigator(
          key: key,
          child: ConsultationNotesScreen(client: client, authorName: widget.role.label, readOnly: false),
        );
      case _ClientTab.diet:
        return PaneNavigator(key: key, child: DietPlanScreen(client: client, readOnly: !widget.role.canEditDietPlans));
      case _ClientTab.workout:
        return PaneNavigator(
          key: key,
          child: WorkoutPlanScreen(client: client, readOnly: !widget.role.canEditWorkoutPlans),
        );
      case _ClientTab.progress:
        return PaneNavigator(key: key, child: ProgressScreen(client: client, readOnly: !widget.role.canEditProgress));
      case _ClientTab.sessions:
        return PaneNavigator(key: key, child: AppointmentsScreen(client: client));
    }
  }
}
