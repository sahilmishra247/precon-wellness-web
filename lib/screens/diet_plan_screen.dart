import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/food_item.dart';
import '../services/theme_service.dart';
import '../services/wellness_service.dart';
import '../utils/units.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_colors.dart';

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

  // Day filter: 'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun', or 'week' for full week
  late String selectedDay;

  static const List<Map<String, String>> _daysOfWeek = [
    {'key': 'mon', 'label': 'Mon', 'fullName': 'Monday'},
    {'key': 'tue', 'label': 'Tue', 'fullName': 'Tuesday'},
    {'key': 'wed', 'label': 'Wed', 'fullName': 'Wednesday'},
    {'key': 'thu', 'label': 'Thu', 'fullName': 'Thursday'},
    {'key': 'fri', 'label': 'Fri', 'fullName': 'Friday'},
    {'key': 'sat', 'label': 'Sat', 'fullName': 'Saturday'},
    {'key': 'sun', 'label': 'Sun', 'fullName': 'Sunday'},
  ];

  static const List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];

  @override
  void initState() {
    super.initState();
    selectedDay = _getTodayKey();
    _loadDietItems();
  }

  String _getTodayKey() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      case DateTime.sunday:
        return 'sun';
      default:
        return 'mon';
    }
  }

  Future<void> _loadDietItems() async {
    try {
      final items = await wellnessService.getDietItems(widget.client.email);
      if (mounted) {
        setState(() {
          allItems = items;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          allItems = [
            ...widget.client.breakfastItems,
            ...widget.client.lunchItems,
            ...widget.client.dinnerItems,
            ...widget.client.snacksItems,
          ];
          isLoading = false;
        });
      }
    }
  }

  List<FoodItem> _getItemsForDayAndMeal(String dayKey, String mealType) {
    return allItems.where((item) {
      final matchesMeal =
          (item.mealType ?? '').toLowerCase() == mealType.toLowerCase();
      if (!matchesMeal) return false;

      final itemDay = item.dayOfWeek.toLowerCase();
      // 'all' items apply to every day
      return itemDay == 'all' || itemDay == dayKey.toLowerCase();
    }).toList();
  }

  int _countItemsForDay(String dayKey) {
    return allItems.where((item) {
      final itemDay = item.dayOfWeek.toLowerCase();
      return itemDay == 'all' || itemDay == dayKey.toLowerCase();
    }).length;
  }

  Future<void> _showFoodDialog(String mealType, {FoodItem? item}) async {
    final defaultDay = selectedDay == 'week' ? 'all' : selectedDay;
    final result = await showDialog<FoodItem>(
      context: context,
      builder: (_) => _FoodItemDialog(
        mealType: mealType,
        item: item,
        initialDay: item?.dayOfWeek ?? defaultDay,
      ),
    );

    if (result != null && mounted) {
      try {
        if (item == null) {
          await wellnessService.createDietItem(
            clientEmail: widget.client.email,
            mealType: mealType,
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
        await _loadDietItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving food item: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteFoodItem(FoodItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove food item?'),
        content: Text('Remove "${item.name}" from meal plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (item.id != null) {
          await wellnessService.deleteDietItem(item.id!);
          await _loadDietItems();
        } else {
          setState(() => allItems.remove(item));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting food item: $e'),
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
              '${widget.client.fullName} Diet Plan',
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
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Day Selector / Weekly Bar ────────────────────────
                        _buildDaySelectorBar(isDark),
                        Divider(height: 1, color: AppColors.border(isDark)),

                        // ── Main Content: Single Day or Full Week View ───────
                        Expanded(
                          child: selectedDay == 'week'
                              ? _buildFullWeekView(isDark)
                              : _buildSingleDayView(selectedDay, isDark),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  // ── Day Selector Bar ───────────────────────────────────────────────────────
  Widget _buildDaySelectorBar(bool isDark) {
    final todayKey = _getTodayKey();

    return Container(
      color: AppColors.surface(isDark),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Days of the week (Mon–Sun)
            for (final day in _daysOfWeek) ...[
              _dayChip(
                key: day['key']!,
                label: day['label']!,
                isToday: day['key'] == todayKey,
                isSelected: selectedDay == day['key'],
                count: _countItemsForDay(day['key']!),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
            ],

            Container(
              height: 24,
              width: 1,
              color: AppColors.border(isDark),
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(width: 4),

            // Full Week button
            InkWell(
              onTap: () => setState(() => selectedDay = 'week'),
              borderRadius: BorderRadius.circular(AppColors.radiusMedium),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selectedDay == 'week'
                      ? AppColors.brand(isDark)
                      : AppColors.brandMuted(isDark),
                  borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                  border: Border.all(
                    color: selectedDay == 'week'
                        ? AppColors.brand(isDark)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.view_week_outlined,
                      size: 16,
                      color: selectedDay == 'week'
                          ? Colors.white
                          : AppColors.brand(isDark),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Full Week',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedDay == 'week'
                            ? Colors.white
                            : AppColors.brand(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayChip({
    required String key,
    required String label,
    required bool isToday,
    required bool isSelected,
    required int count,
    required bool isDark,
  }) {
    final bg = isSelected
        ? AppColors.brand(isDark)
        : AppColors.surface(isDark);
    final textColor = isSelected
        ? Colors.white
        : AppColors.textPrimary(isDark);
    final borderColor = isSelected
        ? AppColors.brand(isDark)
        : (isToday ? AppColors.brand(isDark) : AppColors.border(isDark));

    return InkWell(
      onTap: () => setState(() => selectedDay = key),
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      child: Container(
        constraints: const BoxConstraints(minWidth: 46),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
          border: Border.all(
            color: borderColor,
            width: isToday && !isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            if (isToday)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.brand(isDark),
                  shape: BoxShape.circle,
                ),
              )
            else
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textMuted(isDark),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Single Day View ────────────────────────────────────────────────────────
  Widget _buildSingleDayView(String dayKey, bool isDark) {
    final dayInfo = _daysOfWeek.firstWhere((d) => d['key'] == dayKey);
    final isToday = dayKey == _getTodayKey();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Day Banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brandMuted(isDark),
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            border: Border.all(color: AppColors.brand(isDark).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.brand(isDark)),
              const SizedBox(width: 8),
              Text(
                dayInfo['fullName']!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.brand(isDark),
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand(isDark),
                    borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${_countItemsForDay(dayKey)} total items',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark)),
              ),
            ],
          ),
        ),

        // Meal Sections
        _mealSection('Breakfast', Icons.wb_sunny_outlined, dayKey, isDark),
        _mealSection('Lunch', Icons.restaurant_outlined, dayKey, isDark),
        _mealSection('Dinner', Icons.nights_stay_outlined, dayKey, isDark),
        _mealSection('Snacks', Icons.apple_outlined, dayKey, isDark),
      ],
    );
  }

  // ── Full Week Overview ─────────────────────────────────────────────────────
  Widget _buildFullWeekView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Complete Weekly Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(isDark),
              letterSpacing: -0.3,
            ),
          ),
        ),
        for (final day in _daysOfWeek) ...[
          _buildDayWeekCard(day['key']!, day['fullName']!, isDark),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDayWeekCard(String dayKey, String dayName, bool isDark) {
    final isToday = dayKey == _getTodayKey();
    final dayItems = allItems.where((item) {
      final itemDay = item.dayOfWeek.toLowerCase();
      return itemDay == 'all' || itemDay == dayKey.toLowerCase();
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(
          color: isToday ? AppColors.brand(isDark) : AppColors.border(isDark),
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isToday,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.brandMuted(isDark)
                  : AppColors.surface(isDark),
              borderRadius: BorderRadius.circular(AppColors.radiusMedium),
              border: Border.all(
                color: isToday
                    ? AppColors.brand(isDark)
                    : AppColors.border(isDark),
              ),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: isToday
                  ? AppColors.brand(isDark)
                  : AppColors.textSecondary(isDark),
            ),
          ),
          title: Row(
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand(isDark),
                    borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Text(
            '${dayItems.length} items',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          children: [
            Divider(height: 1, color: AppColors.border(isDark)),
            if (dayItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No meals scheduled for $dayName.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    for (final meal in _mealTypes) ...[
                      _buildMiniMealRow(dayKey, meal, isDark),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMealRow(String dayKey, String mealType, bool isDark) {
    final items = _getItemsForDayAndMeal(dayKey, mealType);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealType,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.brand(isDark),
            ),
          ),
          const SizedBox(height: 4),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 3),
              child: Row(
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDark),
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.name} (${item.amount} ${item.unit})',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                  ),
                  if (item.isDaily)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.border(isDark),
                        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                      ),
                      child: Text(
                        'Daily',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Meal Section (Accordion) ───────────────────────────────────────────────
  Widget _mealSection(String title, IconData icon, String dayKey, bool isDark) {
    final items = _getItemsForDayAndMeal(dayKey, title);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: title == 'Breakfast',
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandMuted(isDark),
              borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            ),
            child: Icon(icon, size: 18, color: AppColors.brand(isDark)),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandMuted(isDark),
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
            child: Text(
              '${items.length} ${items.length == 1 ? 'item' : 'items'}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.brand(isDark),
              ),
            ),
          ),
          children: [
            Divider(height: 1, color: AppColors.border(isDark)),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No food items added for this meal.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
              ),
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  indent: 52,
                  color: AppColors.border(isDark),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brandMuted(isDark),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  items[index].name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (items[index].isDaily) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandMuted(isDark),
                                    borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                                  ),
                                  child: Text(
                                    'Daily',
                                    style: TextStyle(
                                      fontSize: 10,
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
                            '${items[index].amount} ${items[index].unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(isDark),
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
                            _showFoodDialog(title, item: items[index]);
                          } else if (action == 'delete') {
                            _deleteFoodItem(items[index]);
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
              ),
            ],
            if (!widget.readOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _showFoodDialog(title),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Add $title item'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit Food Dialog ───────────────────────────────────────────────────
class _FoodItemDialog extends StatefulWidget {
  final String mealType;
  final FoodItem? item;
  final String initialDay;

  const _FoodItemDialog({
    required this.mealType,
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
          ? 'Add ${widget.mealType} item'
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
