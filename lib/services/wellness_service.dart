import 'api_config.dart';
import '../models/note.dart';
import '../models/food_item.dart';
import '../models/exercise.dart';
import '../models/progress_entry.dart';

class WellnessService {
  // ===========================================================================
  // CONSULTATION NOTES
  // ===========================================================================
  Future<List<Note>> getNotes(String clientEmail) async {
    final response = await ApiConfig.dio.get('/notes/$clientEmail');
    final List<dynamic> data = response.data;
    return data.map((json) => Note.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Note> createNote({
    required String clientEmail,
    required String text,
    String authorName = '',
  }) async {
    final response = await ApiConfig.dio.post(
      '/notes',
      data: {
        'client_email': clientEmail.trim().toLowerCase(),
        'author_name': authorName,
        'text': text.trim(),
      },
    );
    return Note.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Note> updateNote({
    required int id,
    required String text,
  }) async {
    final response = await ApiConfig.dio.put(
      '/notes/$id',
      data: {'text': text.trim()},
    );
    return Note.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteNote(int id) async {
    await ApiConfig.dio.delete('/notes/$id');
  }

  // ===========================================================================
  // DIET PLAN
  // ===========================================================================
  Future<List<FoodItem>> getDietItems(String clientEmail) async {
    final response = await ApiConfig.dio.get('/diet/$clientEmail');
    final List<dynamic> data = response.data;
    return data.map((json) => FoodItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<FoodItem> createDietItem({
    required String clientEmail,
    required String mealType,
    required String name,
    required double amount,
    required String unit,
    String dayOfWeek = 'all',
  }) async {
    final response = await ApiConfig.dio.post(
      '/diet',
      data: {
        'client_email': clientEmail.trim().toLowerCase(),
        'meal_type': mealType.trim().toLowerCase(),
        'name': name.trim(),
        'amount': amount,
        'unit': unit.trim(),
        'day_of_week': dayOfWeek.trim().toLowerCase(),
      },
    );
    return FoodItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FoodItem> updateDietItem({
    required int id,
    String? mealType,
    String? name,
    double? amount,
    String? unit,
    String? dayOfWeek,
  }) async {
    final Map<String, dynamic> data = {};
    if (mealType != null) data['meal_type'] = mealType.trim().toLowerCase();
    if (name != null) data['name'] = name.trim();
    if (amount != null) data['amount'] = amount;
    if (unit != null) data['unit'] = unit.trim();
    if (dayOfWeek != null) data['day_of_week'] = dayOfWeek.trim().toLowerCase();

    final response = await ApiConfig.dio.put('/diet/$id', data: data);
    return FoodItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDietItem(int id) async {
    await ApiConfig.dio.delete('/diet/$id');
  }

  // ===========================================================================
  // WORKOUT / EXERCISES
  // ===========================================================================
  Future<List<Exercise>> getExercises(String clientEmail) async {
    final response = await ApiConfig.dio.get('/exercises/$clientEmail');
    final List<dynamic> data = response.data;
    return data.map((json) => Exercise.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Exercise> createExercise({
    required String clientEmail,
    required String name,
    required int sets,
    required int reps,
  }) async {
    final response = await ApiConfig.dio.post(
      '/exercises',
      data: {
        'client_email': clientEmail.trim().toLowerCase(),
        'name': name.trim(),
        'sets': sets,
        'reps': reps,
      },
    );
    return Exercise.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Exercise> updateExercise({
    required int id,
    String? name,
    int? sets,
    int? reps,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name.trim();
    if (sets != null) data['sets'] = sets;
    if (reps != null) data['reps'] = reps;

    final response = await ApiConfig.dio.put('/exercises/$id', data: data);
    return Exercise.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteExercise(int id) async {
    await ApiConfig.dio.delete('/exercises/$id');
  }

  // ===========================================================================
  // PROGRESS TRACKING
  // ===========================================================================
  Future<List<ProgressEntry>> getProgressEntries(String clientEmail) async {
    final response = await ApiConfig.dio.get('/progress/$clientEmail');
    final List<dynamic> data = response.data;
    return data.map((json) => ProgressEntry.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ProgressEntry> createProgressEntry({
    required String clientEmail,
    required double weight,
    DateTime? date,
  }) async {
    final response = await ApiConfig.dio.post(
      '/progress',
      data: {
        'client_email': clientEmail.trim().toLowerCase(),
        'weight': weight,
        if (date != null) 'date': date.toIso8601String(),
      },
    );
    return ProgressEntry.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProgressEntry(int id) async {
    await ApiConfig.dio.delete('/progress/$id');
  }
}
