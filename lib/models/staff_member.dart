class StaffMember {
  final int id;
  final String name;
  final String email;
  final String role; // 'coach' | 'dietician'
  final String phoneNumber;
  final String specialty; // stored in goal
  final bool isArchived;
  final bool isEmailVerified;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber = '',
    this.specialty = '',
    this.isArchived = false,
    this.isEmailVerified = true,
  });

  bool get isCoach => role.toLowerCase() == 'coach';
  bool get isDietician => role.toLowerCase() == 'dietician';
  String get roleLabel => isCoach ? 'Fitness Coach' : (isDietician ? 'Dietician' : role);

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'coach',
      phoneNumber: json['phone_number'] as String? ?? '',
      specialty: (json['specialty'] ?? json['goal'] ?? '') as String,
      isArchived: json['is_archived'] as bool? ?? false,
      isEmailVerified: json['is_email_verified'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone_number': phoneNumber,
      'goal': specialty,
      'specialty': specialty,
      'is_archived': isArchived,
      'is_email_verified': isEmailVerified,
    };
  }
}
