/// How careful staff need to be about a health tag. Only staff can change it.
enum HealthSeverity {
  critical,
  care,
  info;

  static HealthSeverity parse(String? value) {
    switch (value) {
      case 'critical':
        return HealthSeverity.critical;
      case 'info':
        return HealthSeverity.info;
      default:
        return HealthSeverity.care;
    }
  }

  String get label {
    switch (this) {
      case HealthSeverity.critical:
        return 'Must avoid';
      case HealthSeverity.care:
        return 'Take care';
      case HealthSeverity.info:
        return 'For info';
    }
  }
}

/// Phase 1 covers medical conditions and allergies/intolerances.
enum HealthKind {
  condition,
  allergy;

  static HealthKind parse(String? value) => value == 'allergy' ? HealthKind.allergy : HealthKind.condition;

  String get pluralLabel => this == HealthKind.allergy ? 'Allergies and intolerances' : 'Conditions';
}

/// A medical condition or allergy on a client's profile, shown to staff as a tag.
class HealthTag {
  final int id;
  final String clientEmail;
  final HealthKind kind;
  final String label;
  final String preset;
  final HealthSeverity severity;
  final String note;
  final String addedByName;
  final String addedByRole;
  final DateTime createdAt;

  HealthTag({
    required this.id,
    required this.clientEmail,
    required this.kind,
    required this.label,
    this.preset = '',
    this.severity = HealthSeverity.care,
    this.note = '',
    this.addedByName = '',
    this.addedByRole = '',
    required this.createdAt,
  });

  bool get addedByClient => addedByRole == 'client';

  factory HealthTag.fromJson(Map<String, dynamic> json) {
    return HealthTag(
      id: json['id'] as int,
      clientEmail: json['client_email'] ?? '',
      kind: HealthKind.parse(json['kind'] as String?),
      label: json['label'] ?? '',
      preset: json['preset'] ?? '',
      severity: HealthSeverity.parse(json['severity'] as String?),
      note: json['note'] ?? '',
      addedByName: json['added_by_name'] ?? '',
      addedByRole: json['added_by_role'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// An entry in the add-health-info picker: built in, or added by staff.
class HealthPreset {
  final String key;
  final HealthKind kind;
  final String label;
  final HealthSeverity severity;
  final bool isCustom;

  HealthPreset({
    required this.key,
    required this.kind,
    required this.label,
    required this.severity,
    this.isCustom = false,
  });

  factory HealthPreset.fromJson(Map<String, dynamic> json) {
    return HealthPreset(
      key: json['key'] ?? '',
      kind: HealthKind.parse(json['kind'] as String?),
      label: json['label'] ?? '',
      severity: HealthSeverity.parse(json['severity'] as String?),
      isCustom: json['is_custom'] ?? false,
    );
  }
}
