class ProgressEntry {
  final int? id;
  final String? clientEmail;
  final double weight;
  final DateTime date;

  ProgressEntry({
    this.id,
    this.clientEmail,
    required this.weight,
    required this.date,
  });

  factory ProgressEntry.fromJson(Map<String, dynamic> json) {
    return ProgressEntry(
      id: json['id'] as int?,
      clientEmail: json['client_email'],
      weight: ((json['weight'] ?? 0) as num).toDouble(),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (clientEmail != null) 'client_email': clientEmail,
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }
}

