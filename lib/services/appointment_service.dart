import 'api_config.dart';
import '../models/appointment.dart';

class AppointmentService {
  Future<List<Appointment>> getAppointments({String? clientEmail}) async {
    final response = await ApiConfig.dio.get(
      '/appointments',
      queryParameters: clientEmail != null ? {'client_email': clientEmail} : null,
    );
    final List<dynamic> data = response.data;
    return data.map((json) => Appointment.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Appointment> createAppointment({
    required String clientEmail,
    required String coachEmail,
    required DateTime appointmentDate,
    required String meetingLink,
    required String notes,
  }) async {
    final response = await ApiConfig.dio.post(
      '/appointments',
      data: {
        'client_email': clientEmail.trim().toLowerCase(),
        'coach_email': coachEmail.trim().toLowerCase(),
        'appointment_date': appointmentDate.toIso8601String(),
        'meeting_link': meetingLink.trim(),
        'notes': notes.trim(),
      },
    );
    return Appointment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Appointment> updateAppointment({
    required int id,
    DateTime? appointmentDate,
    String? meetingLink,
    String? notes,
  }) async {
    final Map<String, dynamic> data = {};
    if (appointmentDate != null) {
      data['appointment_date'] = appointmentDate.toIso8601String();
    }
    if (meetingLink != null) data['meeting_link'] = meetingLink.trim();
    if (notes != null) data['notes'] = notes.trim();

    final response = await ApiConfig.dio.put(
      '/appointments/$id',
      data: data,
    );
    return Appointment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAppointment(int id) async {
    await ApiConfig.dio.delete('/appointments/$id');
  }
}