import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/food_item.dart';
import '../models/meal_slot.dart';
import '../services/theme_service.dart';
import '../services/wellness_service.dart';
import '../utils/units.dart';
import '../widgets/desktop_shell.dart';
import '../widgets/motion.dart';
import '../utils/formatters.dart';
import '../theme/app_colors.dart';

/// Weekly diet plan: one row per meal ("Meal 1 · 7:00 am"), days across.
/// Staff can rename a row, change its time, add rows and delete them.
class DietPlanScreen extends StatefulWidget {
  final Client client;
  final bool readOnly;

  const DietPlanScreen({
    super.key,
    required this.client,
    this.readOnly = false,
  });

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  final WellnessService wellnessService = WellnessService();
  bool isLoading = true;
  List<FoodItem> allItems = [];
  List<MealSlot> slots = [];

  static const List<Map<String, String>> _daysOfWeek = [
    {'key': 'mon', 'label': 'Mon'},
    {'key': 'tue', 'label': 'Tue'},
    {'key': 'wed', 'label': 'Wed'},
    {'key': 'thu', 'label': 'Thu'},
    {'key': 'fri', 'label': 'Fri'},
    {'key': 'sat', 'label': 'Sat'},
    {'key': 'sun', 'label': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _getTodayKey() => _daysOfWeek[DateTime.now().weekday - 1]['key']!;

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        wellnessService.getMealSlots(widget.client.email),
        wellnessService.getDietItems(widget.client.email),
      ]);
      if (!mounted) return;
      setState(() {
        slots = (results[0] as List<MealSlot>)..sort(MealSlot.byTime);
        allItems = results[1] as List<FoodItem>;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _snack('Could not load the diet plan: $e', error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? AppColors.error : null),
    );
  }

  List<FoodItem> _itemsFor(String dayKey, MealSlot slot) {
    return allItems.where((item) {
      if ((item.mealType ?? '').toLowerCase() != slot.key) return false;
      final itemDay = item.dayOfWeek.toLowerCase();
      return itemDay == 'all' || itemDay == dayKey;
    }).toList();
  }

  // ── Meal rows ─────────────────────────────────────────────────────────────

  Future<void> _addRow() async {
    final result = await showDialog<_RowResult>(
      context: context,
      builder: (_) => _MealRowDialog(suggestedTitle: 'Meal ${slots.length + 1}'),
    );
    if (result == null || !mounted) return;
    try {
      await wellnessService.createMealSlot(clientEmail: widget.client.email, title: result.title, time: result.time);
      await _load();
    } catch (e) {
      _snack('Could not add the meal row: $e', error: true);
    }
  }

  Future<void> _editRow(MealSlot slot) async {
    final result = await showDialog<_RowResult>(
      context: context,
      builder: (_) => _MealRowDialog(slot: slot, suggestedTitle: slot.title),
    );
    if (result == null || !mounted) return;
    try {
      if (result.delete) {
        await wellnessService.deleteMealSlot(slot.id);
      } else {
        await wellnessService.updateMealSlot(id: slot.id, title: result.title, time: result.time);
      }
      await _load();
    } catch (e) {
      _snack('Could not save the meal row: $e', error: true);
    }
  }

  // ── Food items ────────────────────────────────────────────────────────────

  Future<void> _showFoodDialog(MealSlot slot, {FoodItem? item, String? day}) async {
    final result = await showDialog<FoodItem>(
      context: context,
      builder: (_) => _FoodItemDialog(
        mealType: slot.key,
        mealLabel: slot.label,
        item: item,
        initialDay: item?.dayOfWeek ?? day ?? 'all',
      ),
    );
    if (result == null || !mounted) return;
    try {
      if (item == null) {
        await wellnessService.createDietItem(
          clientEmail: widget.client.email,
          mealType: slot.key,
          name: result.name,
          amount: result.amount,
          unit: result.unit,
          dayOfWeek: result.dayOfWeek,
        );
      } else if (item.id != null) {
        await wellnessService.updateDietItem(
          id: item.id!,
          name: result.name,
          amount: result.amount,
          unit: result.unit,
          dayOfWeek: result.dayOfWeek,
        );
      }
      await _load();
    } catch (e) {
      _snack('Error saving food item: $e', error: true);
    }
  }

  Future<void> _deleteFoodItem(FoodItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove food item?'),
        content: Text('Remove "${item.name}" from the meal plan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || item.id == null) return;
    try {
      await wellnessService.deleteDietItem(item.id!);
      await _load();
    } catch (e) {
      _snack('Error deleting food item: $e', error: true);
    }
  }

  // ── Layout ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);
        final desktop = DesktopPaneScope.of(context);
        final body = isLoading ? const Center(child: CircularProgressIndicator()) : _content(isDark, desktop);

        if (desktop) {
          return Scaffold(backgroundColor: AppColors.bg(isDark), body: body);
        }
        return Scaffold(
          backgroundColor: AppColors.bg(isDark),
          appBar: AppBar(title: Text('${widget.client.fullName} · Diet plan')),
          floatingActionButton: widget.readOnly || isLoading
              ? null
              : FloatingActionButton.extended(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add meal row'),
                ),
          body: body,
        );
      },
    );
  }

  Widget _content(bool isDark, bool desktop) {
    final count = allItems.length;
    final subtitle = viewerIsClient
        ? '$count ${count == 1 ? 'item' : 'items'}, planned by your care team'
        : widget.readOnly
            ? 'View only · ${slots.length} ${slots.length == 1 ? 'meal' : 'meals'} a day'
            : '${slots.length} ${slots.length == 1 ? 'meal' : 'meals'} a day · tap a meal to rename it or change its time';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (desktop)
          PaneToolbar(
            title: viewerIsClient ? 'Your meals this week' : 'Week plan',
            subtitle: subtitle,
            actions: [
              if (!widget.readOnly)
                FilledButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add meal row'),
                ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
          ),
        Expanded(
          child: slots.isEmpty
              ? Center(
                  child: Text(
                    widget.readOnly ? 'No meals planned yet.' : 'No meal rows yet. Add one to start the plan.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark)),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(desktop ? 28 : 12, 0, desktop ? 28 : 12, 96),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final headerWidth = desktop ? 150.0 : 118.0;
                    final minWidth = headerWidth + 7 * 124;
                    final grid = _weekGrid(isDark, headerWidth);
                    if (constraints.maxWidth >= minWidth) return grid;
                    // Narrow windows and phones scroll the week sideways.
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: minWidth, child: grid),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _weekGrid(bool isDark, double headerWidth) {
    final todayKey = _getTodayKey();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          SizedBox(width: headerWidth),
          for (final day in _daysOfWeek)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(children: [
                  Text(
                    day['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: day['key'] == todayKey ? AppColors.brand(isDark) : AppColors.textPrimary(isDark),
                    ),
                  ),
                  if (day['key'] == todayKey) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.leafTint, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Today',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.leafInk)),
                    ),
                  ],
                ]),
              ),
            ),
        ]),
        for (var i = 0; i < slots.length; i++)
          FadeSlideIn(
            index: i,
            // Every cell in a meal row grows to the tallest one.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: headerWidth, child: _rowHeader(slots[i], isDark)),
                  for (final day in _daysOfWeek)
                    Expanded(child: _weekCell(day['key']!, slots[i], day['key'] == todayKey, isDark)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _rowHeader(MealSlot slot, bool isDark) {
    final canEdit = !widget.readOnly;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(slot.title.isEmpty ? 'Meal' : slot.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary(isDark))),
            ),
            if (canEdit) Icon(Icons.edit_outlined, size: 14, color: AppColors.diet.ink),
          ]),
          const SizedBox(height: 6),
          if (slot.displayTime.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.schedule_rounded, size: 13, color: AppColors.diet.ink),
                const SizedBox(width: 4),
                Text(slot.displayTime,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.diet.ink)),
              ]),
            )
          else if (canEdit)
            Text('Set a time', style: TextStyle(fontSize: 12, color: AppColors.textMuted(isDark))),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 6, 4),
      decoration: BoxDecoration(
        color: AppColors.diet.tint,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.diet.color.withValues(alpha: 0.25)),
      ),
      child: canEdit
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                onTap: () => _editRow(slot),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _weekCell(String dayKey, MealSlot slot, bool isToday, bool isDark) {
    final items = _itemsFor(dayKey, slot);
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      constraints: const BoxConstraints(minHeight: 76),
      decoration: BoxDecoration(
        color: isToday ? AppColors.brandMuted(isDark) : AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.lightBorderSubtle),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            _GridFoodItem(
              item: item,
              isDark: isDark,
              onEdit: widget.readOnly ? null : () => _showFoodDialog(slot, item: item),
              onDelete: widget.readOnly ? null : () => _deleteFoodItem(item),
            ),
          if (items.isEmpty && widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text('—', style: TextStyle(color: AppColors.textMuted(isDark))),
            ),
          if (!widget.readOnly)
            _CellAddButton(
              isDark: isDark,
              onPressed: () => _showFoodDialog(slot, day: dayKey),
            ),
        ],
      ),
    );
  }
}

// ── Add / Edit meal row ──────────────────────────────────────────────────────
class _RowResult {
  final String title;
  final String time;
  final bool delete;
  const _RowResult(this.title, this.time, {this.delete = false});
}

class _MealRowDialog extends StatefulWidget {
  final MealSlot? slot;
  final String suggestedTitle;
  const _MealRowDialog({this.slot, required this.suggestedTitle});

  @override
  State<_MealRowDialog> createState() => _MealRowDialogState();
}

class _MealRowDialogState extends State<_MealRowDialog> {
  late final TextEditingController _title = TextEditingController(text: widget.suggestedTitle);
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    final parts = (widget.slot?.time ?? '').split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) _time = TimeOfDay(hour: h, minute: m);
    }
    _time ??= widget.slot == null ? const TimeOfDay(hour: 7, minute: 0) : null;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String get _timeValue =>
      _time == null ? '' : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';

  String get _timeLabel => _time == null
      ? 'No time set'
      : MealSlot(id: 0, title: '', time: _timeValue).displayTime;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 7, minute: 0));
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this meal row?'),
        content: const Text('The row and every food item in it are removed from all seven days.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context, const _RowResult('', '', delete: true));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.slot == null ? 'Add meal row' : 'Edit meal row'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'Meal 1'),
              onSubmitted: (_) => Navigator.pop(context, _RowResult(_title.text.trim(), _timeValue)),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: Icon(Icons.schedule_rounded, size: 18, color: AppColors.diet.ink),
                  label: Text(_timeLabel),
                ),
              ),
              if (_time != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear time',
                  onPressed: () => setState(() => _time = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ]),
          ],
        ),
      ),
      actions: [
        if (widget.slot != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: _confirmDelete,
            child: const Text('Delete row'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _RowResult(_title.text.trim(), _timeValue)),
          child: Text(widget.slot == null ? 'Add row' : 'Save'),
        ),
      ],
    );
  }
}

// ── Add / Edit Food Dialog ───────────────────────────────────────────────────
class _FoodItemDialog extends StatefulWidget {
  final String mealType;
  final String mealLabel;
  final FoodItem? item;
  final String initialDay;

  const _FoodItemDialog({
    required this.mealType,
    required this.mealLabel,
    this.item,
    required this.initialDay,
  });

  @override
  State<_FoodItemDialog> createState() => _FoodItemDialogState();
}

class _FoodItemDialogState extends State<_FoodItemDialog> {
  late final TextEditingController nameController;
  late final TextEditingController amountController;
  late String selectedUnit;
  late String selectedDay;

  static const List<Map<String, String>> _dayOptions = [
    {'key': 'all', 'label': 'Every day (Daily routine)'},
    {'key': 'mon', 'label': 'Monday'},
    {'key': 'tue', 'label': 'Tuesday'},
    {'key': 'wed', 'label': 'Wednesday'},
    {'key': 'thu', 'label': 'Thursday'},
    {'key': 'fri', 'label': 'Friday'},
    {'key': 'sat', 'label': 'Saturday'},
    {'key': 'sun', 'label': 'Sunday'},
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item?.name);
    amountController = TextEditingController(
      text: widget.item?.amount.toString() ?? '1',
    );
    selectedUnit = widget.item?.unit ?? units.first;
    selectedDay = widget.item?.dayOfWeek ?? widget.initialDay;
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void save() {
    final amount = double.tryParse(amountController.text.trim());
    if (nameController.text.trim().isEmpty || amount == null || amount <= 0) {
      return;
    }

    Navigator.pop(
      context,
      FoodItem(
        id: widget.item?.id,
        mealType: widget.mealType,
        name: nameController.text.trim(),
        amount: amount,
        unit: selectedUnit,
        dayOfWeek: selectedDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null
          ? 'Add to ${widget.mealLabel}'
          : 'Edit food item'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Food name (e.g. Oatmeal, Chicken)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit of measure',
                ),
                items: units
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedUnit = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Day of week',
                ),
                items: _dayOptions
                    .map((opt) => DropdownMenuItem(
                          value: opt['key']!,
                          child: Text(
                            opt['label']!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedDay = val);
                },
              ),
            ],
          ),
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

/// One food in the desktop week grid. Click to edit; a remove button shows
/// on hover.
class _GridFoodItem extends StatefulWidget {
  final FoodItem item;
  final bool isDark;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _GridFoodItem({required this.item, required this.isDark, this.onEdit, this.onDelete});

  @override
  State<_GridFoodItem> createState() => _GridFoodItemState();
}

class _GridFoodItemState extends State<_GridFoodItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onEdit,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 5, 2, 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary(isDark))),
                    Text('${fmtAmount(item.amount)} ${item.unit}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark))),
                  ],
                ),
              ),
              if (widget.onDelete != null)
                Opacity(
                  opacity: _hover ? 1 : 0,
                  child: IconButton(
                    tooltip: 'Remove',
                    onPressed: widget.onDelete,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                    padding: EdgeInsets.zero,
                    iconSize: 15,
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted(isDark)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


/// "+" in every week-grid cell. Shows only a muted icon until the pointer is
/// over it, so a mostly empty week doesn't repeat "Add" 28 times.
class _CellAddButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onPressed;
  const _CellAddButton({required this.isDark, required this.onPressed});

  @override
  State<_CellAddButton> createState() => _CellAddButtonState();
}

class _CellAddButtonState extends State<_CellAddButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? AppColors.brand(widget.isDark) : AppColors.textMuted(widget.isDark);
    return Align(
      alignment: Alignment.centerLeft,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Tooltip(
          message: 'Add',
          child: TextButton(
            onPressed: widget.onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(32, 32),
              foregroundColor: color,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, size: 16, color: color),
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: _hover
                    ? const Padding(padding: EdgeInsets.only(left: 4), child: Text('Add'))
                    : const SizedBox.shrink(),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
