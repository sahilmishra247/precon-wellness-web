import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';
import '../widgets/desktop_shell.dart';

class ArchivedClientsScreen extends StatefulWidget {
  const ArchivedClientsScreen({super.key});

  @override
  State<ArchivedClientsScreen> createState() => _ArchivedClientsScreenState();
}

class _ArchivedClientsScreenState extends State<ArchivedClientsScreen> {
  final ClientService clientService = ClientService();
  List<Client> archivedClients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedClients();
  }

  Future<void> _loadArchivedClients() async {
    try {
      final clients = await clientService.getClients(isArchived: true);
      if (mounted) setState(() { archivedClients = clients; isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load archived clients: $e')));
      }
    }
  }

  // expose for backward-compat
  Future<void> loadArchivedClients() => _loadArchivedClients();

  Future<void> _restoreClient(Client client) async {
    if (client.id == null) return;
    try {
      await clientService.archiveClient(client.id!, archive: false);
      await _loadArchivedClients();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${client.fullName} restored')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildDesktop(bool isDark) {
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                PaneToolbar(
                  title: 'Archived accounts',
                  subtitle: '${archivedClients.length} archived · restore to move a client back to the list',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: PaneTable(
                    columns: const ['Name', 'Email', 'Goal', ''],
                    flex: const [3, 4, 3, 2],
                    emptyText: 'No archived accounts',
                    rows: [
                      for (final c in archivedClients)
                        PaneTableRow(cells: [
                          Text(c.fullName, style: paneCellStyle(isDark, strong: true)),
                          Text(c.email, style: paneCellStyle(isDark, muted: true), overflow: TextOverflow.ellipsis),
                          Text(c.goal.isEmpty ? '—' : c.goal, style: paneCellStyle(isDark)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.restore_rounded, size: 15),
                              label: const Text('Restore'),
                              onPressed: () => _restoreClient(c),
                            ),
                          ),
                        ]),
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
            title: Text('Archived accounts', style: TextStyle(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : archivedClients.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.archive_outlined, size: 40, color: AppColors.textMuted(isDark)),
                              const SizedBox(height: 12),
                              Text('No archived accounts.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark))),
                            ]),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          itemCount: archivedClients.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border(isDark)),
                          itemBuilder: (context, index) {
                            final client = archivedClients[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.border(isDark),
                                    child: Text(
                                      client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : 'C',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textSecondary(isDark)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(client.fullName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary(isDark))),
                                    const SizedBox(height: 2),
                                    Text('${client.email}${client.goal.isNotEmpty ? ' · ${client.goal}' : ''}',
                                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark)), overflow: TextOverflow.ellipsis),
                                  ])),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.restore_rounded, size: 15),
                                    label: const Text('Restore'),
                                    onPressed: () => _restoreClient(client),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        );
      },
    );
  }
}
