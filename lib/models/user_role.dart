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
  // Coaches and dieticians can view each other's plans, but only edit their own.
  bool get canViewDietPlans => true;
  bool get canViewWorkoutPlans => true;
  bool get canEditDietPlans =>
      this == UserRole.admin || this == UserRole.dietician;
  bool get canEditWorkoutPlans =>
      this == UserRole.admin || this == UserRole.coach;
  bool get canViewProgress =>
      this == UserRole.admin ||
      this == UserRole.coach ||
      this == UserRole.client;
  bool get isClient => this == UserRole.client;
  bool get isAdmin => this == UserRole.admin;
  bool get isCoach => this == UserRole.coach;
  bool get isDietician => this == UserRole.dietician;
}
