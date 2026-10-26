import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../services/appointment_service.dart';
import '../services/client_service.dart';
import '../services/session_manager.dart';
import '../services/theme_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/desktop_shell.dart';
import '../utils/formatters.dart';
import '../utils/url_helper.dart';
import '../theme/app_colors.dart';
import '../utils/error_messages.dart';

class AppointmentsScreen extends StatefulWidget {
  final Client? client;
  final bool readOnly;

  const AppointmentsScreen({super.key, this.client, this.readOnly = false});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final ClientService clientService = ClientService();
  final AppointmentService appointmentService = AppointmentService();

  List<Client> activeClients = [];
  List<Appointment> appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // The client list (GET /users) is staff-only and only feeds the add/edit dialog,
      // so a read-only view (a client looking at their own sessions) skips it.
      final clientsList = widget.readOnly ? <Client>[] : await clientService.getClients(isArchived: false);
      final appointmentsList = await appointmentService.getAppointments(clientEmail: widget.client?.email);
      if (mounted) {
        setState(() { activeClients = clientsList; appointments = appointmentsList; isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load appointments: ${describeError(e)}')));
      }
    }
  }

  String _getClientDisplayName(String email) {
    final client = activeClients.firstWhere(
      (c) => c.email.toLowerCase() == email.toLowerCase(),
      orElse: () => Client(fullName: email, age: 0, gender: '', height: 0, weight: 0, goal: '', phoneNumber: '', email: email),
    );
    return client.fullName;
  }

  Future<void> _showAppointmentDialog({Appointment? appointment}) async {
    if (activeClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add an active client first')));
      return;
    }

    final result = await showDialog<Appointment>(
      context: context,
      builder: (_) => _AppointmentDialog(
        activeClients: activeClients,
        appointment: appointment,
        preselectedClient: widget.client,
      ),
    );

    if (result != null && mounted) {
      try {
        if (appointment == null) {
          await appointmentService.createAppointment(
            clientEmail: result.clientName,
            coachEmail: SessionManager.email ?? 'coach@precon.com',
            appointmentDate: result.appointmentDate,
            meetingLink: result.meetingLink,
            notes: result.notes,
          );
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment scheduled')));
        } else {
          if (appointment.id != null) {
            await appointmentService.updateAppointment(
              id: appointment.id!, appointmentDate: result.appointmentDate,
              meetingLink: result.meetingLink, notes: result.notes,
            );
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment updated')));
          }
        }
        await _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e)), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _deleteAppointment(Appointment appointment) async {
    if (appointment.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete appointment?'),
        content: const Text('This appointment will be cancelled and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await appointmentService.deleteAppointment(appointment.id!);
        await _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e))));
      }
    }
  }

  String _formatDateTime(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} $hour:$minute';
  }

  // Upcoming and past sessions as two tables; Schedule sits in the toolbar.
  Widget _buildDesktop(bool isDark) {
    final now = DateTime.now();
    final upcoming = appointments.where((a) => !a.appointmentDate.isBefore(now)).toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    final past = appointments.where((a) => a.appointmentDate.isBefore(now)).toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    final showClient = widget.client == null;

    Widget table(List<Appointment> list, String empty) => PaneTable(
          columns: [ 'When', if (showClient) 'Client', 'Notes', 'Call'],
          flex: [3, if (showClient) 3, 4, 2],
          emptyText: empty,
          rows: [
            for (final apt in list)
              PaneTableRow(
                onTap: widget.readOnly ? null : () => _showAppointmentDialog(appointment: apt),
                cells: [
                  Text(fmtDayTime(apt.appointmentDate), style: paneCellStyle(isDark, strong: true)),
                  if (showClient) Text(_getClientDisplayName(apt.clientName), style: paneCellStyle(isDark)),
                  Text(apt.notes.isEmpty ? '—' : apt.notes,
                      style: paneCellStyle(isDark, muted: true), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: apt.meetingLink.isEmpty
                        ? Text('—', style: paneCellStyle(isDark, muted: true))
                        : TextButton.icon(
                            onPressed: () => UrlHelper.openUrl(context, apt.meetingLink),
                            icon: const Icon(Icons.videocam_outlined, size: 16),
                            label: const Text('Join'),
                          ),
                  ),
                ],
                actions: widget.readOnly
                    ? const []
                    : [
                        RowAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          onPressed: () => _showAppointmentDialog(appointment: apt),
                        ),
                        RowAction(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Delete',
                          color: AppColors.error,
                          onPressed: () => _deleteAppointment(apt),
                        ),
                      ],
              ),
          ],
        );

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
          child: Text(text,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
        );

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                PaneToolbar(
                  title: viewerIsClient ? 'Your sessions' : showClient ? 'Appointments' : 'Sessions',
                  subtitle: '${upcoming.length} upcoming · ${past.length} past',
                  actions: [
                    if (!widget.readOnly)
                      FilledButton.icon(
                        onPressed: () => _showAppointmentDialog(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Schedule'),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading('Upcoming'),
                      table(upcoming, 'Nothing scheduled'),
                      const SizedBox(height: 20),
                      heading('Past'),
                      table(past, 'No past sessions'),
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
            title: Text(widget.client == null ? 'Appointments' : 'My appointments',
                style: TextStyle(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w600, fontSize: 16)),
            actions: [ThemeToggleButton(color: AppColors.textSecondary(isDark))],
          ),
          floatingActionButton: widget.readOnly ? null : FloatingActionButton.extended(
            onPressed: () => _showAppointmentDialog(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Schedule'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : appointments.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.calendar_month_outlined, size: 40, color: AppColors.textMuted(isDark)),
                              const SizedBox(height: 12),
                              Text('No appointments scheduled yet.',
                                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark))),
                            ]),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: appointments.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border(isDark)),
                          itemBuilder: (context, index) {
                            final apt = appointments[index];
                            final clientName = _getClientDisplayName(apt.clientName);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(clientName,
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary(isDark))),
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted(isDark)),
                                        const SizedBox(width: 4),
                                        Text(_formatDateTime(apt.appointmentDate),
                                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
                                      ]),
                                       if (apt.meetingLink.isNotEmpty) ...[
                                         const SizedBox(height: 6),
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
                                                 const SizedBox(width: 5),
                                                 Flexible(
                                                   child: Text(
                                                     apt.meetingLink,
                                                     style: TextStyle(
                                                       fontSize: 12,
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
                                      if (apt.notes.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(apt.notes, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark))),
                                      ],
                                    ]),
                                  ),
                                  if (!widget.readOnly)
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted(isDark)),
                                      onSelected: (action) {
                                        if (action == 'edit') _showAppointmentDialog(appointment: apt);
                                        if (action == 'delete') _deleteAppointment(apt);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                                      ],
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

class _AppointmentDialog extends StatefulWidget {
  final List<Client> activeClients;
  final Appointment? appointment;
  final Client? preselectedClient;

  const _AppointmentDialog({required this.activeClients, this.appointment, this.preselectedClient});

  @override
  State<_AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<_AppointmentDialog> {
  late String selectedClientEmail;
  late DateTime selectedDate;
  late final TextEditingController linkController;
  late final TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      selectedClientEmail = widget.appointment!.clientName;
    } else if (widget.preselectedClient != null) {
      selectedClientEmail = widget.preselectedClient!.email;
    } else {
      selectedClientEmail = widget.activeClients.first.email;
    }
    selectedDate = widget.appointment?.appointmentDate ?? DateTime.now().add(const Duration(hours: 1));
    linkController = TextEditingController(text: widget.appointment?.meetingLink);
    notesController = TextEditingController(text: widget.appointment?.notes);
  }

  @override
  void dispose() {
    linkController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context, initialDate: selectedDate,
      firstDate: DateTime(2020), lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() => selectedDate = DateTime(date.year, date.month, date.day, selectedDate.hour, selectedDate.minute));
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedDate));
    if (time != null && mounted) {
      setState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, time.hour, time.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appointment != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit appointment' : 'Schedule appointment'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEditing && widget.preselectedClient == null)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedClientEmail,
                  decoration: const InputDecoration(labelText: 'Client'),
                  items: widget.activeClients
                      .map((c) => DropdownMenuItem(
                            value: c.email,
                            child: Text(
                              '${c.fullName} (${c.email})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => selectedClientEmail = v);
                  },
                ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.date_range_outlined),
            title: const Text('Date'),
            subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Text('Change'),
            onTap: _selectDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_rounded),
            title: const Text('Time'),
            subtitle: Text(TimeOfDay.fromDateTime(selectedDate).format(context),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Text('Change'),
            onTap: _selectTime,
          ),
          TextField(
            controller: linkController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Meeting link (Google Meet / Zoom)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Agenda / notes'),
          ),
        ],
      ),
    ),
  ),
  actions: [
    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, Appointment(
            id: widget.appointment?.id,
            clientName: selectedClientEmail,
            appointmentDate: selectedDate,
            meetingLink: linkController.text.trim(),
            notes: notesController.text.trim(),
          )),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
