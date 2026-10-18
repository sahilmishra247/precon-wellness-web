import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/progress_entry.dart';
import '../services/theme_service.dart';
import '../services/wellness_service.dart';
import '../widgets/theme_toggle_button.dart';
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
        setState(() {
          entries = remoteEntries;
          widget.client.progressEntries = remoteEntries;
          if (remoteEntries.isNotEmpty) {
            widget.client.weight = remoteEntries.first.weight;
          }
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);

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
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : entries.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.show_chart_rounded,
                                          size: 48,
                                          color: AppColors.textMuted(isDark),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No weight history recorded yet',
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
                                  itemCount: entries.length,
                                  separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border(isDark)),
                                  itemBuilder: (context, index) {
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
                                                      '${entry.weight} kg',
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
}
