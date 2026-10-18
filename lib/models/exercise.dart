class Exercise {
  int? id;
  String? clientEmail;
  String name;
  int sets;
  int reps;

  Exercise({
    this.id,
    this.clientEmail,
    required this.name,
    required this.sets,
    required this.reps,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as int?,
      clientEmail: json['client_email'],
      name: json['name'] ?? '',
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (clientEmail != null) 'client_email': clientEmail,
      'name': name,
      'sets': sets,
      'reps': reps,
    };
  }
}

