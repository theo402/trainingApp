import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/user.dart' as models;
import '../models/exercise.dart' as models;
import '../models/exercise_type.dart' as models;
import 'api_client.dart';

enum SyncState {
  idle,
  syncing,
  success,
  error,
}

class SyncService extends ChangeNotifier {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  final AppDatabase _database;
  final ApiClient _apiClient;
  final Connectivity _connectivity = Connectivity();

  SyncState _syncState = SyncState.idle;
  String? _lastError;
  DateTime? _lastSyncTime;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  SyncState get syncState => _syncState;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  SyncService(this._database, this._apiClient) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      // Check if we have any internet connection
      final hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet
      );

      if (hasConnection && _syncState != SyncState.syncing) {
        // Auto-sync when connection is restored
        _autoSync();
      }
    });
  }

  Future<void> _autoSync() async {
    try {
      await syncAll();
    } catch (e) {
      // Silent auto-sync failures - user can manually retry
      debugPrint('Auto-sync failed: $e');
    }
  }

  Future<bool> _hasInternetConnection() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    return connectivityResults.any((result) =>
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet
    );
  }

  Future<void> syncAll() async {
    if (_syncState == SyncState.syncing) return;

    _setSyncState(SyncState.syncing);

    try {
      if (!await _hasInternetConnection()) {
        throw Exception('No internet connection');
      }

      // Sync in order: Users -> ExerciseTypes -> Exercises -> Workouts
      await _syncUsers();
      await _syncExerciseTypes();
      await _syncExercises();
      await _syncWorkouts();

      // Process sync queue
      await _processSyncQueue();

      _lastSyncTime = DateTime.now();
      _lastError = null;
      _setSyncState(SyncState.success);

      // Reset to idle after showing success for a moment
      Timer(const Duration(seconds: 2), () {
        if (_syncState == SyncState.success) {
          _setSyncState(SyncState.idle);
        }
      });
    } catch (e) {
      _lastError = e.toString();
      _setSyncState(SyncState.error);
      debugPrint('Sync failed: $e');
      rethrow;
    }
  }

  void _setSyncState(SyncState state) {
    _syncState = state;
    notifyListeners();
  }

  Future<void> _syncUsers() async {
    final pendingUsers = await _database.getPendingSyncUsers();

    for (final user in pendingUsers) {
      await _syncUserRecord(user);
    }
  }

  Future<void> _syncUserRecord(User user) async {
    try {
      switch (user.syncStatus) {
        case SyncStatus.pendingCreate:
          // Create on server
          final response = await _apiClient.post('/users', data: _userToJson(user));
          final serverUser = models.User.fromJson(response.data['user']);
          await _updateLocalUserFromServer(user.id, serverUser);
          break;

        case SyncStatus.pendingUpdate:
          // Update on server (last-write-wins)
          final response = await _apiClient.put('/users/${user.id}', data: _userToJson(user));
          final serverUser = models.User.fromJson(response.data['user']);
          await _updateLocalUserFromServer(user.id, serverUser);
          break;

        case SyncStatus.pendingDelete:
          // Delete on server
          await _apiClient.delete('/users/${user.id}');
          await (_database.delete(_database.users)..where((u) => u.id.equals(user.id))).go();
          break;

        case SyncStatus.synced:
          // Already synced, skip
          break;

        case SyncStatus.failed:
          // Retry failed records
          await _retryFailedSync('users', user.id, () => _syncUserRecord(user));
          break;
      }
    } catch (e) {
      await _handleSyncError('users', user.id, e);
      rethrow;
    }
  }

  Future<void> _syncExerciseTypes() async {
    final pendingTypes = await _database.getPendingSyncExerciseTypes();

    for (final exerciseType in pendingTypes) {
      await _syncExerciseTypeRecord(exerciseType);
    }
  }

  Future<void> _syncExerciseTypeRecord(ExerciseType exerciseType) async {
    try {
      switch (exerciseType.syncStatus) {
        case SyncStatus.pendingCreate:
          final response = await _apiClient.post('/exercise-types', data: _exerciseTypeToJson(exerciseType));
          final serverType = models.ExerciseType.fromJson(response.data['exercise_type']);
          await _updateLocalExerciseTypeFromServer(exerciseType.id, serverType);
          break;

        case SyncStatus.pendingUpdate:
          final response = await _apiClient.put('/exercise-types/${exerciseType.id}', data: _exerciseTypeToJson(exerciseType));
          final serverType = models.ExerciseType.fromJson(response.data['exercise_type']);
          await _updateLocalExerciseTypeFromServer(exerciseType.id, serverType);
          break;

        case SyncStatus.pendingDelete:
          await _apiClient.delete('/exercise-types/${exerciseType.id}');
          await (_database.delete(_database.exerciseTypes)..where((et) => et.id.equals(exerciseType.id))).go();
          break;

        case SyncStatus.synced:
          break;

        case SyncStatus.failed:
          await _retryFailedSync('exercise_types', exerciseType.id, () => _syncExerciseTypeRecord(exerciseType));
          break;
      }
    } catch (e) {
      await _handleSyncError('exercise_types', exerciseType.id, e);
      rethrow;
    }
  }

  Future<void> _syncExercises() async {
    final pendingExercises = await _database.getPendingSyncExercises();

    for (final exercise in pendingExercises) {
      await _syncExerciseRecord(exercise);
    }
  }

  Future<void> _syncExerciseRecord(Exercise exercise) async {
    try {
      switch (exercise.syncStatus) {
        case SyncStatus.pendingCreate:
          final response = await _apiClient.post('/exercises', data: _exerciseToJson(exercise));
          final serverExercise = models.Exercise.fromJson(response.data['exercise']);
          await _updateLocalExerciseFromServer(exercise.id, serverExercise);
          break;

        case SyncStatus.pendingUpdate:
          final response = await _apiClient.put('/exercises/${exercise.id}', data: _exerciseToJson(exercise));
          final serverExercise = models.Exercise.fromJson(response.data['exercise']);
          await _updateLocalExerciseFromServer(exercise.id, serverExercise);
          break;

        case SyncStatus.pendingDelete:
          await _apiClient.delete('/exercises/${exercise.id}');
          await (_database.delete(_database.exercises)..where((e) => e.id.equals(exercise.id))).go();
          break;

        case SyncStatus.synced:
          break;

        case SyncStatus.failed:
          await _retryFailedSync('exercises', exercise.id, () => _syncExerciseRecord(exercise));
          break;
      }
    } catch (e) {
      await _handleSyncError('exercises', exercise.id, e);
      rethrow;
    }
  }

  Future<void> _syncWorkouts() async {
    final pendingWorkouts = await _database.getPendingSyncWorkouts();

    for (final workout in pendingWorkouts) {
      await _syncWorkoutRecord(workout);
    }
  }

  Future<void> _syncWorkoutRecord(Workout workout) async {
    try {
      switch (workout.syncStatus) {
        case SyncStatus.pendingCreate:
          final response = await _apiClient.post('/workouts', data: _workoutToJson(workout));
          // Note: You'll need to create a Workout model similar to others
          await _database.updateSyncStatus('workouts', workout.id, SyncStatus.synced);
          break;

        case SyncStatus.pendingUpdate:
          final response = await _apiClient.put('/workouts/${workout.id}', data: _workoutToJson(workout));
          await _database.updateSyncStatus('workouts', workout.id, SyncStatus.synced);
          break;

        case SyncStatus.pendingDelete:
          await _apiClient.delete('/workouts/${workout.id}');
          await (_database.delete(_database.workouts)..where((w) => w.id.equals(workout.id))).go();
          break;

        case SyncStatus.synced:
          break;

        case SyncStatus.failed:
          await _retryFailedSync('workouts', workout.id, () => _syncWorkoutRecord(workout));
          break;
      }
    } catch (e) {
      await _handleSyncError('workouts', workout.id, e);
      rethrow;
    }
  }

  Future<void> _retryFailedSync(String tableName, String recordId, Future<void> Function() syncFunction) async {
    final retryCount = await _getRetryCount(tableName, recordId);

    if (retryCount < maxRetries) {
      await _database.incrementSyncRetryCount(tableName, recordId);
      await Future.delayed(retryDelay);
      await syncFunction();
    } else {
      // Add to sync queue for manual retry
      await _addToSyncQueue(tableName, recordId, 'RETRY');
    }
  }

  Future<int> _getRetryCount(String tableName, String recordId) async {
    // This would need to be implemented based on your table structure
    // For now, return 0
    return 0;
  }

  Future<void> _handleSyncError(String tableName, String recordId, dynamic error) async {
    await _database.updateSyncStatus(tableName, recordId, SyncStatus.failed);
    await _database.incrementSyncRetryCount(tableName, recordId);
  }

  Future<void> _processSyncQueue() async {
    final queueItems = await _database.select(_database.syncQueue).get();

    for (final item in queueItems) {
      try {
        // Process queued sync operations
        await _processQueueItem(item);
        await (_database.delete(_database.syncQueue)..where((sq) => sq.id.equals(item.id))).go();
      } catch (e) {
        // Update retry count and error
        await (_database.update(_database.syncQueue)..where((sq) => sq.id.equals(item.id))).write(
          SyncQueueCompanion(
            retryCount: Value(item.retryCount + 1),
            error: Value(e.toString()),
            lastAttemptAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  Future<void> _processQueueItem(SyncQueueData item) async {
    // Implementation for processing individual queue items
    // This would call the appropriate sync method based on operation and table
  }

  Future<void> _addToSyncQueue(String tableName, String recordId, String operation) async {
    await _database.into(_database.syncQueue).insert(
      SyncQueueCompanion.insert(
        operation: operation,
        tableName: tableName,
        recordId: recordId,
        createdAt: DateTime.now(),
      ),
    );
  }

  // Helper methods for updating local records from server responses
  Future<void> _updateLocalUserFromServer(String localId, models.User serverUser) async {
    await (_database.update(_database.users)..where((u) => u.id.equals(localId))).write(
      UsersCompanion(
        id: Value(serverUser.id),
        email: Value(serverUser.email),
        firstName: Value(serverUser.firstName),
        lastName: Value(serverUser.lastName),
        updatedAt: Value(serverUser.updatedAt),
        syncStatus: const Value(SyncStatus.synced),
        lastSyncAt: Value(DateTime.now()),
        syncRetryCount: const Value(0),
      ),
    );
  }

  Future<void> _updateLocalExerciseTypeFromServer(String localId, models.ExerciseType serverType) async {
    await (_database.update(_database.exerciseTypes)..where((et) => et.id.equals(localId))).write(
      ExerciseTypesCompanion(
        id: Value(serverType.id),
        name: Value(serverType.name),
        description: Value(serverType.description),
        category: Value(serverType.category),
        metadataSchema: Value(jsonEncode(serverType.metadataSchema)),
        isGlobal: Value(serverType.isGlobal),
        updatedAt: Value(serverType.updatedAt),
        syncStatus: const Value(SyncStatus.synced),
        lastSyncAt: Value(DateTime.now()),
        syncRetryCount: const Value(0),
      ),
    );
  }

  Future<void> _updateLocalExerciseFromServer(String localId, models.Exercise serverExercise) async {
    await (_database.update(_database.exercises)..where((e) => e.id.equals(localId))).write(
      ExercisesCompanion(
        id: Value(serverExercise.id),
        userId: Value(serverExercise.userId),
        exerciseTypeId: Value(serverExercise.exerciseTypeId),
        exerciseTypeName: Value(serverExercise.exerciseTypeName),
        exerciseTypeCategory: Value(serverExercise.exerciseTypeCategory),
        workoutId: Value(serverExercise.workoutId),
        name: Value(serverExercise.name),
        notes: Value(serverExercise.notes),
        metadata: Value(jsonEncode(serverExercise.metadata)),
        performedAt: Value(serverExercise.performedAt),
        updatedAt: Value(serverExercise.updatedAt),
        syncStatus: const Value(SyncStatus.synced),
        lastSyncAt: Value(DateTime.now()),
        syncRetryCount: const Value(0),
      ),
    );
  }

  // Helper methods for converting local records to JSON for API
  Map<String, dynamic> _userToJson(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'first_name': user.firstName,
      'last_name': user.lastName,
      'created_at': user.createdAt.toIso8601String(),
      'updated_at': user.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _exerciseTypeToJson(ExerciseType exerciseType) {
    return {
      'id': exerciseType.id,
      'name': exerciseType.name,
      'description': exerciseType.description,
      'category': exerciseType.category,
      'metadata_schema': jsonDecode(exerciseType.metadataSchema),
      'is_global': exerciseType.isGlobal,
      'created_at': exerciseType.createdAt.toIso8601String(),
      'updated_at': exerciseType.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _exerciseToJson(Exercise exercise) {
    return {
      'id': exercise.id,
      'user_id': exercise.userId,
      'exercise_type_id': exercise.exerciseTypeId,
      'workout_id': exercise.workoutId,
      'name': exercise.name,
      'notes': exercise.notes,
      'metadata': jsonDecode(exercise.metadata),
      'performed_at': exercise.performedAt.toIso8601String(),
      'created_at': exercise.createdAt.toIso8601String(),
      'updated_at': exercise.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _workoutToJson(Workout workout) {
    return {
      'id': workout.id,
      'user_id': workout.userId,
      'name': workout.name,
      'description': workout.description,
      'status': workout.status,
      'planned_at': workout.plannedAt?.toIso8601String(),
      'started_at': workout.startedAt?.toIso8601String(),
      'completed_at': workout.completedAt?.toIso8601String(),
      'created_at': workout.createdAt.toIso8601String(),
      'updated_at': workout.updatedAt.toIso8601String(),
    };
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}