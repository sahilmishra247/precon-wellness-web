import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/exercise.dart';
import '../services/theme_service.dart';
import '../services/wellness_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/desktop_shell.dart';
import '../theme/app_colors.dart';
import '../utils/error_messages.dart';

class WorkoutPlanScreen extends StatefulWidget {
  final Client client;
  final bool readOnly;

  const WorkoutPlanScreen({
    super.key,
    required this.client,
    this.readOnly = false,
  });

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  final WellnessService wellnessService = WellnessService();
  List<Exercise> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final remoteExercises = await wellnessService.getExercises(widget.client.email);
      if (mounted) {
        setState(() {
          exercises = remoteExercises;
          widget.client.exercises = remoteExercises;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          exercises = widget.client.exercises;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _showExerciseDialog({Exercise? exercise}) async {
    final result = await showDialog<Exercise>(
      context: context,
      builder: (_) => _ExerciseDialog(exercise: exercise),
    );

    if (result != null && mounted) {
      try {
        if (exercise == null) {
          await wellnessService.createExercise(
            clientEmail: widget.client.email,
            name: result.name,
            sets: result.sets,
            reps: result.reps,
          );
        } else if (exercise.id != null) {
          await wellnessService.updateExercise(
            id: exercise.id!,
            name: result.name,
            sets: result.sets,
            reps: result.reps,
          );
        }
        await _loadExercises();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving exercise: ${describeError(e)}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: Text('Remove "${exercise.name}" from workout plan?'),
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
        if (exercise.id != null) {
          await wellnessService.deleteExercise(exercise.id!);
          await _loadExercises();
        } else {
          setState(() => exercises.remove(exercise));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting exercise: ${describeError(e)}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
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
                  title: viewerIsClient ? 'Your workout' : 'Workout plan',
                  subtitle: widget.readOnly && !viewerIsClient
                      ? 'View only · ${exercises.length} exercises'
                      : '${exercises.length} exercises',
                  actions: [
                    if (!widget.readOnly)
                      FilledButton.icon(
                        onPressed: () => _showExerciseDialog(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add exercise'),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: PaneTable(
                    columns: const ['Exercise', 'Sets', 'Reps'],
                    flex: const [6, 2, 2],
                    emptyText: 'No exercises added yet',
                    rows: [
                      for (final e in exercises)
                        PaneTableRow(
                          onTap: widget.readOnly ? null : () => _showExerciseDialog(exercise: e),
                          cells: [
                            Text(e.name, style: paneCellStyle(isDark, strong: true)),
                            Text('${e.sets}', style: paneCellStyle(isDark)),
                            Text('${e.reps}', style: paneCellStyle(isDark)),
                          ],
                          actions: widget.readOnly
                              ? const []
                              : [
                                  RowAction(
                                    icon: Icons.edit_outlined,
                                    tooltip: 'Edit',
                                    onPressed: () => _showExerciseDialog(exercise: e),
                                  ),
                                  RowAction(
                                    icon: Icons.delete_outline_rounded,
                                    tooltip: 'Remove',
                                    color: AppColors.error,
                                    onPressed: () => _deleteExercise(e),
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
              '${widget.client.fullName} Workout Plan',
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
          floatingActionButton: widget.readOnly
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showExerciseDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add exercise'),
                ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: exercises.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fitness_center_outlined,
                                    size: 48,
                                    color: AppColors.textMuted(isDark),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No exercises added yet',
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
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: exercises.length,
                            separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border(isDark)),
                            itemBuilder: (context, index) {
                              final exercise = exercises[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandMuted(isDark),
                                        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                                      ),
                                      child: Icon(
                                        Icons.fitness_center_rounded,
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
                                            exercise.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: AppColors.textPrimary(isDark),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.brandMuted(isDark),
                                                  borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                                                ),
                                                child: Text(
                                                  '${exercise.sets} sets',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.brand(isDark),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.border(isDark),
                                                  borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                                                ),
                                                child: Text(
                                                  '${exercise.reps} reps',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textSecondary(isDark),
                                                  ),
                                                ),
                                              ),
                                            ],
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
                                            _showExerciseDialog(exercise: exercise);
                                          } else if (action == 'delete') {
                                            _deleteExercise(exercise);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit')),
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
                ),
        );
      },
    );
  }
}

class _ExerciseDialog extends StatefulWidget {
  final Exercise? exercise;

  const _ExerciseDialog({this.exercise});

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late final TextEditingController nameController;
  late final TextEditingController setsController;
  late final TextEditingController repsController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.exercise?.name);
    setsController = TextEditingController(
      text: widget.exercise?.sets.toString() ?? '3',
    );
    repsController = TextEditingController(
      text: widget.exercise?.reps.toString() ?? '10',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    setsController.dispose();
    repsController.dispose();
    super.dispose();
  }

  void save() {
    final sets = int.tryParse(setsController.text.trim());
    final reps = int.tryParse(repsController.text.trim());
    if (nameController.text.trim().isEmpty ||
        sets == null ||
        sets <= 0 ||
        reps == null ||
        reps <= 0) {
      return;
    }

    Navigator.pop(
      context,
      Exercise(
        id: widget.exercise?.id,
        name: nameController.text.trim(),
        sets: sets,
        reps: reps,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exercise == null ? 'Add exercise' : 'Edit exercise'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise name (e.g. Bench Press, Squat)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of sets',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps per set',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
