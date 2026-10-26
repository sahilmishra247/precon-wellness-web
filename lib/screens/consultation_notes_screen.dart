import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/note.dart';
import '../services/theme_service.dart';
import '../services/wellness_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/desktop_shell.dart';
import '../utils/formatters.dart';
import '../theme/app_colors.dart';

class ConsultationNotesScreen extends StatefulWidget {
  final Client client;
  final String authorName;
  final bool readOnly;

  const ConsultationNotesScreen({
    super.key,
    required this.client,
    required this.authorName,
    this.readOnly = false,
  });

  @override
  State<ConsultationNotesScreen> createState() =>
      _ConsultationNotesScreenState();
}

class _ConsultationNotesScreenState extends State<ConsultationNotesScreen> {
  final noteController = TextEditingController();
  final WellnessService wellnessService = WellnessService();
  List<Note> notes = [];
  bool isLoading = true;
  bool isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final remoteNotes = await wellnessService.getNotes(widget.client.email);
      if (mounted) {
        setState(() {
          notes = remoteNotes;
          widget.client.notes = remoteNotes;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          notes = widget.client.notes;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _addNote() async {
    final text = noteController.text.trim();
    if (text.isEmpty) return;

    setState(() => isAdding = true);
    try {
      await wellnessService.createNote(
        clientEmail: widget.client.email,
        authorName: widget.authorName,
        text: text,
      );
      noteController.clear();
      await _loadNotes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }

  Future<void> _editNote(Note note) async {
    final updatedText = await showDialog<String>(
      context: context,
      builder: (_) => _EditNoteDialog(initialText: note.text),
    );

    if (updatedText != null && updatedText.trim().isNotEmpty && mounted) {
      try {
        if (note.id != null) {
          await wellnessService.updateNote(
            id: note.id!,
            text: updatedText.trim(),
          );
          await _loadNotes();
        } else {
          setState(() => note.text = updatedText.trim());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating note: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('Are you sure you want to delete this consultation note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (note.id != null) {
          await wellnessService.deleteNote(note.id!);
          await _loadNotes();
        } else {
          setState(() => notes.remove(note));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting note: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // Notes newest first, with the new-note box beside them.
  Widget _buildDesktop(bool isDark) {
    final sorted = [...notes]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final timeline = isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(32, 0, 16, 32),
            children: [
              if (sorted.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('No consultation notes yet',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark))),
                ),
              for (final note in sorted) ...[
                _desktopNoteCard(note, isDark),
                const SizedBox(height: 12),
              ],
            ],
          );
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaneToolbar(
            title: viewerIsClient ? 'Notes from your care team' : 'Consultation notes',
            subtitle: '${notes.length} notes · newest first',
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: timeline),
                if (!widget.readOnly)
                  Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: SizedBox(width: 340, child: _desktopComposer(isDark)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopComposer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New note',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 10),
          TextField(
            controller: noteController,
            minLines: 6,
            maxLines: 12,
            style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Observations, client feedback, recommendations...',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isAdding ? null : _addNote,
            icon: isAdding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add note'),
          ),
        ],
      ),
    );
  }

  Widget _desktopNoteCard(Note note, bool isDark) {
    final d = note.createdAt;
    // Notes saved without a time come back as midnight; show only the day then.
    final when = d.hour == 0 && d.minute == 0 ? fmtDay(d) : fmtDayTime(d);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${note.authorName ?? 'Coach'} · $when',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary(isDark)),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  note.text,
                  style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary(isDark)),
                ),
              ],
            ),
          ),
          if (!widget.readOnly) ...[
            RowAction(icon: Icons.edit_outlined, tooltip: 'Edit', onPressed: () => _editNote(note)),
            RowAction(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete',
              color: AppColors.error,
              onPressed: () => _deleteNote(note),
            ),
          ],
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
            title: Text(
              '${widget.client.fullName} Notes',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            actions: [
              ThemeToggleButton(color: AppColors.textSecondary(isDark)),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    if (!widget.readOnly) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface(isDark),
                          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                          border: Border.all(color: AppColors.border(isDark)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: noteController,
                              maxLines: 3,
                              style: TextStyle(color: AppColors.textPrimary(isDark)),
                              decoration: const InputDecoration(
                                labelText: 'New consultation note',
                                hintText: 'Record observations, client feedback, and recommendations...',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: isAdding ? null : _addNote,
                                icon: isAdding
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Note'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : notes.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.note_alt_outlined,
                                          size: 48,
                                          color: AppColors.textMuted(isDark),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No consultation notes yet',
                                          style: TextStyle(
                                            color: AppColors.textSecondary(isDark),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: notes.length,
                                  separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border(isDark)),
                                  itemBuilder: (context, index) {
                                    final note = notes[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(top: 2),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandMuted(isDark),
                                              borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                                            ),
                                            child: Icon(
                                              Icons.note_alt_outlined,
                                              color: AppColors.brand(isDark),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  note.text,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1.45,
                                                    color: AppColors.textPrimary(isDark),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${note.authorName ?? 'Coach'} • ${_formatDateTime(note.createdAt)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textMuted(isDark),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!widget.readOnly)
                                            PopupMenuButton<String>(
                                              icon: Icon(
                                                Icons.more_vert_rounded,
                                                size: 18,
                                                color: AppColors.textMuted(isDark),
                                              ),
                                              onSelected: (action) {
                                                if (action == 'edit') {
                                                  _editNote(note);
                                                } else if (action == 'delete') {
                                                  _deleteNote(note);
                                                }
                                              },
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Edit'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Delete', style: TextStyle(color: AppColors.error)),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    );
                                  },
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

  String _formatDateTime(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} $hour:$minute';
  }
}

class _EditNoteDialog extends StatefulWidget {
  final String initialText;

  const _EditNoteDialog({required this.initialText});

  @override
  State<_EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<_EditNoteDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit note'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Enter note...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
