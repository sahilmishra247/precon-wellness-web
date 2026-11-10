import 'api_config.dart';
import '../models/health_tag.dart';

/// Client health tags (conditions and allergies) and the picker presets.
class HealthService {
  Future<List<HealthPreset>> getPresets() async {
    final response = await ApiConfig.dio.get('/health/presets');
    final List<dynamic> data = response.data;
    return data.map((json) => HealthPreset.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Staff only: adds a condition or allergy to everyone's picker.
  Future<HealthPreset> createPreset({
    required HealthKind kind,
    required String label,
    required HealthSeverity severity,
  }) async {
    final response = await ApiConfig.dio.post(
      '/health/presets',
      data: {'kind': kind.name, 'label': label.trim(), 'severity': severity.name},
    );
    return HealthPreset.fromJson(response.data as Map<String, dynamic>);
  }

  /// Staff only: every client's tags, grouped by client email.
  Future<Map<String, List<HealthTag>>> getAllTags() async {
    final response = await ApiConfig.dio.get('/health');
    final List<dynamic> data = response.data;
    final byClient = <String, List<HealthTag>>{};
    for (final json in data) {
      final tag = HealthTag.fromJson(json as Map<String, dynamic>);
      byClient.putIfAbsent(tag.clientEmail.toLowerCase(), () => []).add(tag);
    }
    return byClient;
  }

  Future<List<HealthTag>> getTags(String clientEmail) async {
    final response = await ApiConfig.dio.get('/health/${clientEmail.trim().toLowerCase()}');
    final List<dynamic> data = response.data;
    return data.map((json) => HealthTag.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// [severity] is only sent by staff; clients get the preset's level.
  Future<HealthTag> addTag({
    required String clientEmail,
    required HealthKind kind,
    required String label,
    String preset = '',
    HealthSeverity? severity,
    String note = '',
    bool consent = false,
  }) async {
    final response = await ApiConfig.dio.post(
      '/health',
      data: {
        'client_email': clientEmail.trim().toLowerCase(),
        'kind': kind.name,
        'label': label.trim(),
        'preset': preset,
        if (severity != null) 'severity': severity.name,
        'note': note.trim(),
        'consent': consent,
      },
    );
    return HealthTag.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HealthTag> updateTag({required int id, String? note, HealthSeverity? severity}) async {
    final response = await ApiConfig.dio.put(
      '/health/$id',
      data: {
        if (note != null) 'note': note.trim(),
        if (severity != null) 'severity': severity.name,
      },
    );
    return HealthTag.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeTag(int id) async {
    await ApiConfig.dio.delete('/health/$id');
  }
}
