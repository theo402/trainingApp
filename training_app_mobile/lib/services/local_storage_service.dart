import 'dart:convert';
import '../database/database.dart';
import '../models/exercise.dart' as models;
import '../models/exercise_type.dart' as models;
import '../models/user.dart' as models;

class LocalStorageService {
  final AppDatabase _database;

  LocalStorageService(this._database);

  // User operations
  Future<models.User?> getCurrentUser() async {
    final users = await _database.select(_database.users).get();
    if (users.isEmpty) return null;

    final user = users.first;
    return models.User(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  Future<void> saveUser(models.User user, {bool markForSync = true}) async {
    await _database.into(_database.users).insertOnConflictUpdate(
      UsersCompanion.insert(
        id: user.id,
        email: user.email,
        firstName: Value(user.firstName),
        lastName: Value(user.lastName),
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        syncStatus: markForSync ? const Value(SyncStatus.pendingUpdate) : const Value(SyncStatus.synced),
      ),
    );
  }

  // Exercise Type operations
  Future<List<models.ExerciseType>> getExerciseTypes({String? category}) async {
    var query = _database.select(_database.exerciseTypes);

    if (category != null) {
      query = query..where((et) => et.category.equals(category));
    }

    final exerciseTypes = await query.get();
    return exerciseTypes.map((et) => _exerciseTypeFromDb(et)).toList();
  }

  Future<models.ExerciseType?> getExerciseTypeById(String id) async {
    final exerciseType = await (_database.select(_database.exerciseTypes)
      ..where((et) => et.id.equals(id))).getSingleOrNull();

    if (exerciseType == null) return null;
    return _exerciseTypeFromDb(exerciseType);
  }

  Future<void> saveExerciseType(models.ExerciseType exerciseType, {bool markForSync = true}) async {
    await _database.into(_database.exerciseTypes).insertOnConflictUpdate(
      ExerciseTypesCompanion.insert(
        id: exerciseType.id,
        name: exerciseType.name,
        description: Value(exerciseType.description),
        category: Value(exerciseType.category),
        metadataSchema: jsonEncode(exerciseType.metadataSchema),
        isGlobal: exerciseType.isGlobal,
        userId: Value(exerciseType.isGlobal ? null : 'current-user'), // You'd get this from auth
        createdAt: exerciseType.createdAt,
        updatedAt: exerciseType.updatedAt,
        syncStatus: markForSync ? const Value(SyncStatus.pendingUpdate) : const Value(SyncStatus.synced),
      ),
    );
  }

  Future<void> deleteExerciseType(String id) async {
    await _database.updateSyncStatus('exercise_types', id, SyncStatus.pendingDelete);
  }

  // Exercise operations
  Future<List<models.Exercise>> getExercises({
    String? category,
    String? exerciseTypeId,
    int? limit,
    int? offset,
  }) async {
    var query = _database.select(_database.exercises);

    if (category != null) {
      query = query..where((e) => e.exerciseTypeCategory.equals(category));
    }

    if (exerciseTypeId != null) {
      query = query..where((e) => e.exerciseTypeId.equals(exerciseTypeId));
    }

    // Order by performed date descending (most recent first)
    query = query..orderBy([(e) => OrderingTerm.desc(e.performedAt)]);

    if (limit != null) {
      query = query..limit(limit, offset: offset);
    }

    final exercises = await query.get();
    return exercises.map((e) => _exerciseFromDb(e)).toList();
  }

  Future<models.Exercise?> getExerciseById(String id) async {
    final exercise = await (_database.select(_database.exercises)
      ..where((e) => e.id.equals(id))).getSingleOrNull();

    if (exercise == null) return null;
    return _exerciseFromDb(exercise);
  }

  Future<void> saveExercise(models.Exercise exercise, {bool markForSync = true}) async {
    await _database.into(_database.exercises).insertOnConflictUpdate(
      ExercisesCompanion.insert(
        id: exercise.id,
        userId: exercise.userId,
        exerciseTypeId: exercise.exerciseTypeId,
        exerciseTypeName: exercise.exerciseTypeName,
        exerciseTypeCategory: Value(exercise.exerciseTypeCategory),
        workoutId: Value(exercise.workoutId),
        name: Value(exercise.name),
        notes: Value(exercise.notes),
        metadata: jsonEncode(exercise.metadata),
        performedAt: exercise.performedAt,
        createdAt: exercise.createdAt,
        updatedAt: exercise.updatedAt,
        syncStatus: markForSync ? const Value(SyncStatus.pendingUpdate) : const Value(SyncStatus.synced),
      ),
    );
  }

  Future<void> deleteExercise(String id) async {
    await _database.updateSyncStatus('exercises', id, SyncStatus.pendingDelete);
  }

  // Workout operations (basic implementation)
  Future<List<Workout>> getWorkouts() async {
    return await _database.select(_database.workouts).get();
  }

  Future<void> saveWorkout(Workout workout, {bool markForSync = true}) async {
    await _database.into(_database.workouts).insertOnConflictUpdate(
      WorkoutsCompanion.insert(
        id: workout.id,
        userId: workout.userId,
        name: workout.name,
        description: Value(workout.description),
        status: workout.status,
        plannedAt: Value(workout.plannedAt),
        startedAt: Value(workout.startedAt),
        completedAt: Value(workout.completedAt),
        createdAt: workout.createdAt,
        updatedAt: workout.updatedAt,
        syncStatus: markForSync ? const Value(SyncStatus.pendingUpdate) : const Value(SyncStatus.synced),
      ),
    );
  }

  // Sync-related operations
  Future<bool> hasPendingChanges() async {
    final pendingUsers = await _database.getPendingSyncUsers();
    final pendingTypes = await _database.getPendingSyncExerciseTypes();
    final pendingExercises = await _database.getPendingSyncExercises();
    final pendingWorkouts = await _database.getPendingSyncWorkouts();

    return pendingUsers.isNotEmpty ||
           pendingTypes.isNotEmpty ||
           pendingExercises.isNotEmpty ||
           pendingWorkouts.isNotEmpty;
  }

  Future<void> markAllAsSynced() async {
    // This would be called after a successful sync
    await _database.customUpdate('UPDATE users SET sync_status = ? WHERE sync_status != ?',
      variables: [Variable.withInt(SyncStatus.synced.index), Variable.withInt(SyncStatus.pendingDelete.index)]);
    await _database.customUpdate('UPDATE exercise_types SET sync_status = ? WHERE sync_status != ?',
      variables: [Variable.withInt(SyncStatus.synced.index), Variable.withInt(SyncStatus.pendingDelete.index)]);
    await _database.customUpdate('UPDATE exercises SET sync_status = ? WHERE sync_status != ?',
      variables: [Variable.withInt(SyncStatus.synced.index), Variable.withInt(SyncStatus.pendingDelete.index)]);
    await _database.customUpdate('UPDATE workouts SET sync_status = ? WHERE sync_status != ?',
      variables: [Variable.withInt(SyncStatus.synced.index), Variable.withInt(SyncStatus.pendingDelete.index)]);
  }

  // Helper methods to convert between DB and model objects
  models.ExerciseType _exerciseTypeFromDb(ExerciseType dbType) {
    return models.ExerciseType(
      id: dbType.id,
      name: dbType.name,
      description: dbType.description,
      category: dbType.category,
      metadataSchema: jsonDecode(dbType.metadataSchema) as Map<String, dynamic>,
      isGlobal: dbType.isGlobal,
      createdAt: dbType.createdAt,
      updatedAt: dbType.updatedAt,
    );
  }

  models.Exercise _exerciseFromDb(Exercise dbExercise) {
    return models.Exercise(
      id: dbExercise.id,
      userId: dbExercise.userId,
      exerciseTypeId: dbExercise.exerciseTypeId,
      exerciseTypeName: dbExercise.exerciseTypeName,
      exerciseTypeCategory: dbExercise.exerciseTypeCategory,
      workoutId: dbExercise.workoutId,
      name: dbExercise.name,
      notes: dbExercise.notes,
      metadata: jsonDecode(dbExercise.metadata) as Map<String, dynamic>,
      performedAt: dbExercise.performedAt,
      createdAt: dbExercise.createdAt,
      updatedAt: dbExercise.updatedAt,
    );
  }

  // Clear all local data (for logout)
  Future<void> clearAllData() async {
    await _database.delete(_database.users).go();
    await _database.delete(_database.exerciseTypes).go();
    await _database.delete(_database.exercises).go();
    await _database.delete(_database.workouts).go();
    await _database.delete(_database.syncQueue).go();
  }

  // Generate unique IDs for offline records
  String generateId() {
    return 'local_${DateTime.now().millisecondsSinceEpoch}_${(999999 * 0.999999).toInt()}';
  }
}