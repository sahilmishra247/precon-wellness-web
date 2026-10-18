class Appointment {
  int? id;
  String clientName;
  String coachEmail;
  DateTime appointmentDate;
  String meetingLink;
  String notes;

  Appointment({
    this.id,
    required this.clientName,
    this.coachEmail = '',
    required this.appointmentDate,
    required this.meetingLink,
    required this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int?,
      clientName: json['client_email'] ?? '',
      coachEmail: json['coach_email'] ?? '',
      appointmentDate: DateTime.parse(json['appointment_date']),
      meetingLink: json['meeting_link'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'client_email': clientName,
      'coach_email': coachEmail,
      'appointment_date': appointmentDate.toIso8601String(),
      'meeting_link': meetingLink,
      'notes': notes,
    };
  }
}

