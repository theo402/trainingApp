import '../models/exercise.dart';
import 'api_client.dart';

class ExerciseService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Exercise>> getExercises({
    String? exerciseTypeId,
    String? workoutId,
    String? category,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (exerciseTypeId != null) queryParams['exercise_type_id'] = exerciseTypeId;
      if (workoutId != null) queryParams['workout_id'] = workoutId;
      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _apiClient.get('/exercises',
          queryParameters: queryParams);

      final List<dynamic> exercisesJson = response.data['exercises'];
      return exercisesJson.map((json) => Exercise.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load exercises', null);
    }
  }

  Future<Exercise> getExercise(String id) async {
    try {
      final response = await _apiClient.get('/exercises/$id');
      return Exercise.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load exercise', null);
    }
  }

  Future<Exercise> createExercise(CreateExerciseRequest request) async {
    try {
      final response = await _apiClient.post('/exercises',
          data: request.toJson());
      return Exercise.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to create exercise', null);
    }
  }

  Future<Exercise> updateExercise(String id, UpdateExerciseRequest request) async {
    try {
      final response = await _apiClient.patch('/exercises/$id',
          data: request.toJson());
      return Exercise.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update exercise', null);
    }
  }

  Future<void> deleteExercise(String id) async {
    try {
      await _apiClient.delete('/exercises/$id');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to delete exercise', null);
    }
  }
}