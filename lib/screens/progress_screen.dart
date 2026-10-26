import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/progress_entry.dart';
import '../services/theme_service.dart';
import '../services/wellness_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/desktop_shell.dart';
import '../utils/formatters.dart';
import '../widgets/weight_chart.dart';
import '../theme/app_colors.dart';

class ProgressScreen extends StatefulWidget {
  final Client client;
  final bool readOnly;

  const ProgressScreen({
    super.key,
    required this.client,
    this.readOnly = false,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final weightController = TextEditingController();
  final WellnessService wellnessService = WellnessService();
  List<ProgressEntry> entries = [];
  bool isLoading = true;
  bool isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final remoteEntries = await wellnessService.getProgressEntries(widget.client.email);
      if (mounted) {
        // Newest first. client.weight stays the starting weight from the profile.
        remoteEntries.sort((a, b) => b.date.compareTo(a.date));
        setState(() {
          entries = remoteEntries;
          widget.client.progressEntries = remoteEntries;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          entries = widget.client.progressEntries;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _addEntry() async {
    final weight = double.tryParse(weightController.text.trim());
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight in kg')),
      );
      return;
    }

    setState(() => isAdding = true);
    try {
      await wellnessService.createProgressEntry(
        clientEmail: widget.client.email,
        weight: weight,
      );
      weightController.clear();
      await _loadProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Weight log recorded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving weight entry: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isAdding = false);
      }
    }
  }

  Future<void> _deleteEntry(ProgressEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Delete logged weight of ${entry.weight} kg?'),
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
        if (entry.id != null) {
          await wellnessService.deleteProgressEntry(entry.id!);
          await _loadProgress();
        } else {
          setState(() => entries.remove(entry));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting entry: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  static String _fmtKg(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Widget _buildSummary(bool isDark) {
    final current = entries.first.weight;
    final start = widget.client.weight > 0 ? widget.client.weight : entries.last.weight;
    final change = current - start;
    final changeText = change.abs() < 0.05
        ? 'No change'
        : '${change > 0 ? '+' : '−'}${_fmtKg(double.parse(change.abs().toStringAsFixed(1)))} kg';

    Widget tile(String label, String value, String? sub) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              borderRadius: BorderRadius.circular(AppColors.radiusLarge),
              border: Border.all(color: AppColors.border(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark), letterSpacing: -0.3)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted(isDark), fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        );

    final d = entries.first.date;
    return Row(
      children: [
        tile('Starting', '${_fmtKg(start)} kg', null),
        const SizedBox(width: 10),
        tile('Current', '${_fmtKg(current)} kg',
            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'),
        const SizedBox(width: 10),
        tile('Change', changeText, '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}'),
      ],
    );
  }

  // Chart on the left, history on the right, logging in the toolbar.
  Widget _buildDesktop(bool isDark) {
    final start = widget.client.weight > 0 ? widget.client.weight : null;
    final current = entries.isNotEmpty ? entries.first.weight : null;
    final change = start != null && current != null ? current - start : null;

    Widget stat(String label, String value, String? note) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              borderRadius: BorderRadius.circular(AppColors.radiusLarge),
              border: Border.all(color: AppColors.border(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary(isDark))),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
                if (note != null)
                  Text(note, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark))),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                PaneToolbar(
                  title: viewerIsClient ? 'Your progress' : 'Progress',
                  subtitle: widget.readOnly && !viewerIsClient ? 'View only · ${entries.length} entries' : '${entries.length} entries',
                  actions: [
                    if (!widget.readOnly) ...[
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onSubmitted: (_) => _addEntry(),
                          decoration: const InputDecoration(hintText: 'Weight (kg)', isDense: true),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: isAdding ? null : _addEntry,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Log weight'),
                      ),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        stat('Starting', start != null ? fmtKg(start) : '—', 'From profile'),
                        const SizedBox(width: 12),
                        stat('Current', current != null ? fmtKg(current) : '—',
                            entries.isNotEmpty ? 'Logged ${fmtDay(entries.first.date)}' : null),
                        const SizedBox(width: 12),
                        stat('Change', change != null ? '${change > 0 ? '+' : change < 0 ? '−' : ''}${fmtKg(change.abs())}' : '—',
                            'Since start'),
                      ]),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface(isDark),
                                borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                                border: Border.all(color: AppColors.border(isDark)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Weight over time (kg)',
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
                                  const SizedBox(height: 12),
                                  WeightChart(entries: entries, baseline: start, isDark: isDark),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 340,
                            child: PaneTable(
                              columns: const ['Date', 'Weight'],
                              flex: const [3, 2],
                              emptyText: 'No weights logged yet',
                              rows: [
                                for (final e in entries)
                                  PaneTableRow(
                                    cells: [
                                      Text(fmtDay(e.date), style: paneCellStyle(isDark)),
                                      Text(fmtKg(e.weight), style: paneCellStyle(isDark, strong: true)),
                                    ],
                                    actions: widget.readOnly
                                        ? const []
                                        : [
                                            RowAction(
                                              icon: Icons.delete_outline_rounded,
                                              tooltip: 'Delete entry',
                                              color: AppColors.error,
                                              onPressed: () => _deleteEntry(e),
                                            ),
                                          ],
                                  ),
                              ],
                            ),
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
            title: Text(
              '${widget.client.fullName} Progress',
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
                child: ListView(
                  children: [
                    if (!widget.readOnly) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface(isDark),
                          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                          border: Border.all(color: AppColors.border(isDark)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 450;
                            final textField = TextField(
                              controller: weightController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: TextStyle(color: AppColors.textPrimary(isDark)),
                              decoration: const InputDecoration(
                                labelText: 'Current weight (kg)',
                                hintText: 'e.g. 75.5',
                                prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20),
                              ),
                            );

                            final logButton = ElevatedButton.icon(
                              onPressed: isAdding ? null : _addEntry,
                              icon: isAdding
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Log weight'),
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  textField,
                                  const SizedBox(height: 12),
                                  SizedBox(height: 44, child: logButton),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: textField),
                                const SizedBox(width: 12),
                                SizedBox(height: 44, child: logButton),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.show_chart_rounded, size: 48, color: AppColors.textMuted(isDark)),
                            const SizedBox(height: 12),
                            Text(
                              'No weight history recorded yet',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDark),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.client.weight > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Starting weight: ${_fmtKg(widget.client.weight)} kg',
                                style: TextStyle(color: AppColors.textMuted(isDark), fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      )
                    else ...[
                      _buildSummary(isDark),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface(isDark),
                          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
                          border: Border.all(color: AppColors.border(isDark)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'Weight over time (kg)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary(isDark),
                                ),
                              ),
                            ),
                            WeightChart(
                              entries: entries,
                              baseline: widget.client.weight > 0 ? widget.client.weight : null,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'History',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (var index = 0; index < entries.length; index++) ...[
                        if (index > 0) Divider(height: 1, color: AppColors.border(isDark)),
                        Builder(builder: (context) {
                                    final entry = entries[index];
                                    final isLatest = index == 0;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isLatest
                                                  ? AppColors.brandMuted(isDark)
                                                  : AppColors.surface(isDark),
                                              borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                                              border: Border.all(
                                                color: isLatest ? AppColors.brand(isDark) : AppColors.border(isDark),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.show_chart_rounded,
                                              color: isLatest ? AppColors.brand(isDark) : AppColors.textSecondary(isDark),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${_fmtKg(entry.weight)} kg',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                        color: AppColors.textPrimary(isDark),
                                                      ),
                                                    ),
                                                    if (isLatest) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.brandMuted(isDark),
                                                          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                                                        ),
                                                        child: Text(
                                                          'Latest',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: AppColors.brand(isDark),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Logged on ${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}/${entry.date.year}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary(isDark),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!widget.readOnly)
                                            IconButton(
                                              icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                              tooltip: 'Delete Log',
                                              onPressed: () => _deleteEntry(entry),
                                            ),
                                        ],
                                      ),
                                    );
                        }),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
