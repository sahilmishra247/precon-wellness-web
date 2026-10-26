import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/user_role.dart';
import '../services/client_service.dart';
import '../services/theme_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_colors.dart';
import 'add_client_screen.dart';
import 'archived_clients_screen.dart';
import 'client_details_screen.dart';
import '../utils/error_messages.dart';

class ClientsScreen extends StatefulWidget {
  final UserRole role;
  const ClientsScreen({super.key, required this.role});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchController = TextEditingController();
  final ClientService _clientService = ClientService();

  List<Client> _allClients = [];
  bool _isLoading = true;
  String _query = '';

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
      final clients = await _clientService.getClients(isArchived: false);
      if (mounted) setState(() { _allClients = clients; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load clients: ${describeError(e)}')));
      }
    }
  }

  List<Client> get _filtered {
    final q = _query.toLowerCase();
    return _allClients.where((c) {
      if (c.isArchived) return false;
      return c.fullName.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.phoneNumber.contains(_query);
    }).toList();
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

    if (confirm == true && client.id != null) {
      try {
        await _clientService.archiveClient(client.id!, archive: true);
        await _loadClients();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${client.fullName} archived')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);
        final clients = _filtered;

        return Scaffold(
          backgroundColor: AppColors.bg(isDark),
          appBar: AppBar(
            title: Text('Clients', style: TextStyle(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w600, fontSize: 16)),
            actions: [
              ThemeToggleButton(color: AppColors.textSecondary(isDark)),
              if (widget.role.canManageClients)
                IconButton(
                  tooltip: 'Archived clients',
                  icon: Icon(Icons.archive_outlined, size: 20, color: AppColors.textSecondary(isDark)),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedClientsScreen()));
                    _loadClients();
                  },
                ),
            ],
          ),
          floatingActionButton: widget.role.canManageClients
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddClientScreen()));
                    _loadClients();
                  },
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Add client'),
                )
              : null,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search clients…',
                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted(isDark)),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted(isDark)),
                                onPressed: () { _searchController.clear(); setState(() => _query = ''); },
                              )
                            : null,
                      ),
                    ),
                  ),
                  // List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : clients.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    _query.isEmpty ? 'No active clients registered yet.' : 'No clients match "$_query".',
                                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                                itemCount: clients.length,
                                separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border(isDark)),
                                itemBuilder: (context, index) {
                                  final client = clients[index];
                                  return InkWell(
                                    onTap: () async {
                                      await Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => ClientDetailsScreen(client: client, role: widget.role)));
                                      _loadClients();
                                    },
                                    onLongPress: widget.role.canManageClients ? () => _archiveClient(client) : null,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: AppColors.brandMuted(isDark),
                                            child: Text(
                                              client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : 'C',
                                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.brand(isDark)),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(child: Text(client.fullName,
                                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary(isDark)),
                                                        overflow: TextOverflow.ellipsis)),
                                                    if (client.goal.isNotEmpty) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.brandMuted(isDark),
                                                          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                                                        ),
                                                        child: Text(client.goal, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brand(isDark))),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(client.email, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
                                                if (client.phoneNumber.isNotEmpty)
                                                  Text(client.phoneNumber, style: TextStyle(fontSize: 12, color: AppColors.textMuted(isDark))),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted(isDark)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // expose for backward compatibility
  Future<void> loadClients() => _loadClients();
}
