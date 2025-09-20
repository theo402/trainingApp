import '../models/exercise.dart' as models;
import '../models/exercise_type.dart' as models;
import '../models/user.dart' as models;

class SimpleLocalStorageService {
  // In-memory storage for demo purposes
  final List<models.Exercise> _exercises = [];
  final List<models.ExerciseType> _exerciseTypes = [];
  models.User? _currentUser;

  // User operations
  Future<models.User?> getCurrentUser() async {
    return _currentUser;
  }

  Future<void> saveUser(models.User user, {bool markForSync = true}) async {
    _currentUser = user;
  }

  // Exercise Type operations
  Future<List<models.ExerciseType>> getExerciseTypes({String? category}) async {
    if (category != null) {
      return _exerciseTypes.where((et) => et.category == category).toList();
    }
    return List.from(_exerciseTypes);
  }

  Future<models.ExerciseType?> getExerciseTypeById(String id) async {
    try {
      return _exerciseTypes.firstWhere((et) => et.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveExerciseType(models.ExerciseType exerciseType, {bool markForSync = true}) async {
    final index = _exerciseTypes.indexWhere((et) => et.id == exerciseType.id);
    if (index >= 0) {
      _exerciseTypes[index] = exerciseType;
    } else {
      _exerciseTypes.add(exerciseType);
    }
  }

  Future<void> deleteExerciseType(String id) async {
    _exerciseTypes.removeWhere((et) => et.id == id);
  }

  // Exercise operations
  Future<List<models.Exercise>> getExercises({
    String? category,
    String? exerciseTypeId,
    int? limit,
    int? offset,
  }) async {
    var filtered = _exercises.where((e) => true);

    if (category != null) {
      filtered = filtered.where((e) => e.exerciseTypeCategory == category);
    }

    if (exerciseTypeId != null) {
      filtered = filtered.where((e) => e.exerciseTypeId == exerciseTypeId);
    }

    var result = filtered.toList();
    result.sort((a, b) => b.performedAt.compareTo(a.performedAt)); // Most recent first

    if (offset != null) {
      result = result.skip(offset).toList();
    }

    if (limit != null) {
      result = result.take(limit).toList();
    }

    return result;
  }

  Future<models.Exercise?> getExerciseById(String id) async {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveExercise(models.Exercise exercise, {bool markForSync = true}) async {
    final index = _exercises.indexWhere((e) => e.id == exercise.id);
    if (index >= 0) {
      _exercises[index] = exercise;
    } else {
      _exercises.add(exercise);
    }
  }

  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
  }

  // Sync-related operations
  Future<bool> hasPendingChanges() async {
    return false; // For demo purposes
  }

  Future<void> markAllAsSynced() async {
    // For demo purposes
  }

  // Clear all local data (for logout)
  Future<void> clearAllData() async {
    _exercises.clear();
    _exerciseTypes.clear();
    _currentUser = null;
  }

  // Generate unique IDs for offline records
  String generateId() {
    return 'local_${DateTime.now().millisecondsSinceEpoch}_${(999999 * 0.999999).toInt()}';
  }

  // Add some demo data for testing
  Future<void> addDemoData() async {
    // Add demo exercise types
    final pushUpType = models.ExerciseType(
      id: generateId(),
      name: 'Push-ups',
      category: 'Bodyweight',
      metadataSchema: {
        'type': 'object',
        'properties': {
          'reps': {'type': 'integer'},
          'sets': {'type': 'integer'},
        },
        'required': ['reps', 'sets']
      },
      isGlobal: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final squatType = models.ExerciseType(
      id: generateId(),
      name: 'Squats',
      category: 'Bodyweight',
      metadataSchema: {
        'type': 'object',
        'properties': {
          'reps': {'type': 'integer'},
          'sets': {'type': 'integer'},
        },
        'required': ['reps', 'sets']
      },
      isGlobal: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveExerciseType(pushUpType, markForSync: false);
    await saveExerciseType(squatType, markForSync: false);

    // Add demo exercises
    final exercise1 = models.Exercise(
      id: generateId(),
      userId: 'demo-user-id',
      exerciseTypeId: pushUpType.id,
      exerciseTypeName: pushUpType.name,
      exerciseTypeCategory: pushUpType.category,
      workoutId: null,
      name: 'Morning Push-ups',
      notes: 'Good form maintained',
      metadata: {'reps': 20, 'sets': 3},
      performedAt: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final exercise2 = models.Exercise(
      id: generateId(),
      userId: 'demo-user-id',
      exerciseTypeId: squatType.id,
      exerciseTypeName: squatType.name,
      exerciseTypeCategory: squatType.category,
      workoutId: null,
      name: 'Bodyweight Squats',
      notes: 'Deep squats',
      metadata: {'reps': 15, 'sets': 4},
      performedAt: DateTime.now().subtract(const Duration(hours: 1)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveExercise(exercise1, markForSync: false);
    await saveExercise(exercise2, markForSync: false);
  }
}