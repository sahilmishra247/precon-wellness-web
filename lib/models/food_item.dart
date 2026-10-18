class FoodItem {
  int? id;
  String? clientEmail;
  String? mealType;
  String name;
  double amount;
  String unit;
  String dayOfWeek; // 'all', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'

  FoodItem({
    this.id,
    this.clientEmail,
    this.mealType,
    required this.name,
    required this.amount,
    required this.unit,
    this.dayOfWeek = 'all',
  });

  bool get isDaily => dayOfWeek == 'all';

  String get dayLabel {
    switch (dayOfWeek.toLowerCase()) {
      case 'mon':
        return 'Monday';
      case 'tue':
        return 'Tuesday';
      case 'wed':
        return 'Wednesday';
      case 'thu':
        return 'Thursday';
      case 'fri':
        return 'Friday';
      case 'sat':
        return 'Saturday';
      case 'sun':
        return 'Sunday';
      default:
        return 'Every day';
    }
  }

  String get shortDayLabel {
    switch (dayOfWeek.toLowerCase()) {
      case 'mon':
        return 'Mon';
      case 'tue':
        return 'Tue';
      case 'wed':
        return 'Wed';
      case 'thu':
        return 'Thu';
      case 'fri':
        return 'Fri';
      case 'sat':
        return 'Sat';
      case 'sun':
        return 'Sun';
      default:
        return 'Daily';
    }
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as int?,
      clientEmail: json['client_email'],
      mealType: json['meal_type'],
      name: json['name'] ?? '',
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      unit: json['unit'] ?? '',
      dayOfWeek: (json['day_of_week'] ?? 'all').toString().toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (clientEmail != null) 'client_email': clientEmail,
      if (mealType != null) 'meal_type': mealType,
      'name': name,
      'amount': amount,
      'unit': unit,
      'day_of_week': dayOfWeek,
    };
  }
}
