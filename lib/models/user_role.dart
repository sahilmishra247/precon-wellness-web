enum UserRole {
  admin,
  coach,
  dietician,
  client;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.coach:
        return 'Coach';
      case UserRole.dietician:
        return 'Dietician';
      case UserRole.client:
        return 'Client';
    }
  }

  bool get canManageClients => this == UserRole.admin || true;
  bool get canViewDietPlans =>
      this == UserRole.admin ||
      this == UserRole.dietician ||
      this == UserRole.client;
  bool get canViewWorkoutPlans =>
      this == UserRole.admin ||
      this == UserRole.coach ||
      this == UserRole.client;
  bool get canViewProgress =>
      this == UserRole.admin ||
      this == UserRole.coach ||
      this == UserRole.client;
  bool get isClient => this == UserRole.client;
  bool get isAdmin => this == UserRole.admin;
  bool get isCoach => this == UserRole.coach;
  bool get isDietician => this == UserRole.dietician;
}
