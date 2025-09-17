import '../models/exercise_type.dart';
import 'api_client.dart';

class ExerciseTypeService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ExerciseType>> getExerciseTypes({
    String? category,
    bool? globalOnly,
    bool? userOnly,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (globalOnly != null) queryParams['global_only'] = globalOnly;
      if (userOnly != null) queryParams['user_only'] = userOnly;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _apiClient.get('/exercise-types',
          queryParameters: queryParams);

      final List<dynamic> exerciseTypesJson = response.data['exercise_types'];
      return exerciseTypesJson
          .map((json) => ExerciseType.fromJson(json))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load exercise types', null);
    }
  }

  Future<ExerciseType> getExerciseType(String id) async {
    try {
      final response = await _apiClient.get('/exercise-types/$id');
      return ExerciseType.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load exercise type', null);
    }
  }

  Future<ExerciseType> createExerciseType(CreateExerciseTypeRequest request) async {
    try {
      final response = await _apiClient.post('/exercise-types',
          data: request.toJson());
      return ExerciseType.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to create exercise type', null);
    }
  }

  Future<ExerciseType> updateExerciseType(String id, CreateExerciseTypeRequest request) async {
    try {
      final response = await _apiClient.patch('/exercise-types/$id',
          data: request.toJson());
      return ExerciseType.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update exercise type', null);
    }
  }

  Future<void> deleteExerciseType(String id) async {
    try {
      await _apiClient.delete('/exercise-types/$id');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to delete exercise type', null);
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final exerciseTypes = await getExerciseTypes();
      final categories = exerciseTypes
          .where((et) => et.category != null)
          .map((et) => et.category!)
          .toSet()
          .toList();
      categories.sort();
      return categories;
    } catch (e) {
      return [];
    }
  }
}