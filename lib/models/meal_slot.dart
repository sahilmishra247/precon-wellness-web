/// One row of a client's weekly diet grid, e.g. "Meal 1" at 7:00 am.
/// Food items belong to a row through `FoodItem.mealType == key`.
class MealSlot {
  final int id;
  final String title;

  /// 24-hour "HH:MM", or empty when no time is set.
  final String time;
  final int position;

  const MealSlot({required this.id, required this.title, this.time = '', this.position = 0});

  String get key => 'slot:$id';

  /// Rows with a time come first, earliest first; rows without one keep their order after them.
  static int byTime(MealSlot a, MealSlot b) {
    if (a.time.isEmpty != b.time.isEmpty) return a.time.isEmpty ? 1 : -1;
    final t = a.time.compareTo(b.time);
    return t != 0 ? t : a.position.compareTo(b.position);
  }

  /// "7:00 am", or '' when no time is set.
  String get displayTime {
    final parts = time.split(':');
    if (parts.length != 2) return '';
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return '';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} ${h < 12 ? 'am' : 'pm'}';
  }

  /// "Meal 1 · 7:00 am"
  String get label => displayTime.isEmpty ? title : '$title · $displayTime';

  factory MealSlot.fromJson(Map<String, dynamic> json) => MealSlot(
        id: json['id'] as int,
        title: (json['title'] ?? '').toString(),
        time: (json['time'] ?? '').toString(),
        position: (json['position'] ?? 0) as int,
      );
}
