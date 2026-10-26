import 'note.dart';
import 'progress_entry.dart';
import 'exercise.dart';
import 'food_item.dart';
import 'appointment.dart';
import 'health_tag.dart';


class Client {
  int? id;
  String fullName;
  int age;
  String gender;
  double height;
  double weight;
  String goal;
  String phoneNumber;
  String email;
  bool isArchived;
  DateTime? healthConsentAt;

  List<Note> notes = [];
  List<ProgressEntry> progressEntries = [];
  List<Exercise> exercises = [];
  List<FoodItem> breakfastItems = [];
  List<FoodItem> lunchItems = [];
  List<FoodItem> dinnerItems = [];
  List<FoodItem> snacksItems = [];
  List<Appointment> appointments = [];
  List<HealthTag> healthTags = [];

  Client({
    this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.goal,
    required this.phoneNumber,
    required this.email,
    this.isArchived = false,
    this.healthConsentAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int?,
      fullName: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      height: ((json['height'] ?? 0) as num).toDouble(),
      weight: ((json['weight'] ?? 0) as num).toDouble(),
      goal: json['goal'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      isArchived: json['is_archived'] ?? false,
      healthConsentAt: DateTime.tryParse(json['health_consent_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': fullName,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'goal': goal,
      'phone_number': phoneNumber,
      'email': email,
      'is_archived': isArchived,
      if (healthConsentAt != null) 'health_consent_at': healthConsentAt!.toIso8601String(),
    };
  }
}

