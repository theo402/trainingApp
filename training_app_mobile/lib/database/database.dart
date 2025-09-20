import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

// Conditional imports for web vs mobile
import 'database_connection.dart';

// Tables
part 'database.g.dart';

// Sync Status enum for tracking sync state
enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  failed
}

// Users table
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // Sync metadata
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(0))(); // 0 = synced
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  IntColumn get syncRetryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// Exercise Types table
class ExerciseTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get metadataSchema => text()(); // JSON string
  BoolColumn get isGlobal => boolean()();
  TextColumn get userId => text().nullable()(); // null for global types
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // Sync metadata
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(0))(); // 0 = synced
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  IntColumn get syncRetryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// Exercises table
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get exerciseTypeId => text()();
  TextColumn get exerciseTypeName => text()();
  TextColumn get exerciseTypeCategory => text().nullable()();
  TextColumn get workoutId => text().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get metadata => text()(); // JSON string
  DateTimeColumn get performedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // Sync metadata
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(0))(); // 0 = synced
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  IntColumn get syncRetryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// Workouts table
class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text()(); // planned, in_progress, completed, cancelled
  DateTimeColumn get plannedAt => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // Sync metadata
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(0))(); // 0 = synced
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  IntColumn get syncRetryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// Sync Queue table for failed operations
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()(); // CREATE, UPDATE, DELETE
  TextColumn get table => text()(); // Changed from tableName to avoid conflict
  TextColumn get recordId => text()();
  TextColumn get data => text().nullable()(); // JSON string of the data
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();
}

@DriftDatabase(tables: [Users, ExerciseTypes, Exercises, Workouts, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will go here
      },
    );
  }

  // Sync-related queries
  Future<List<User>> getPendingSyncUsers() async {
    return (select(users)..where((u) => u.syncStatus.isNotValue(SyncStatus.synced.index))).get();
  }

  Future<List<ExerciseType>> getPendingSyncExerciseTypes() async {
    return (select(exerciseTypes)..where((et) => et.syncStatus.isNotValue(SyncStatus.synced.index))).get();
  }

  Future<List<Exercise>> getPendingSyncExercises() async {
    return (select(exercises)..where((e) => e.syncStatus.isNotValue(SyncStatus.synced.index))).get();
  }

  Future<List<Workout>> getPendingSyncWorkouts() async {
    return (select(workouts)..where((w) => w.syncStatus.isNotValue(SyncStatus.synced.index))).get();
  }

  // Update sync status
  Future<void> updateSyncStatus(String tableName, String recordId, SyncStatus status, {DateTime? lastSyncAt}) async {
    final now = DateTime.now();

    switch (tableName) {
      case 'users':
        await (update(users)..where((u) => u.id.equals(recordId))).write(
          UsersCompanion(
            syncStatus: Value(status),
            lastSyncAt: Value(lastSyncAt ?? now),
          ),
        );
        break;
      case 'exercise_types':
        await (update(exerciseTypes)..where((et) => et.id.equals(recordId))).write(
          ExerciseTypesCompanion(
            syncStatus: Value(status),
            lastSyncAt: Value(lastSyncAt ?? now),
          ),
        );
        break;
      case 'exercises':
        await (update(exercises)..where((e) => e.id.equals(recordId))).write(
          ExercisesCompanion(
            syncStatus: Value(status),
            lastSyncAt: Value(lastSyncAt ?? now),
          ),
        );
        break;
      case 'workouts':
        await (update(workouts)..where((w) => w.id.equals(recordId))).write(
          WorkoutsCompanion(
            syncStatus: Value(status),
            lastSyncAt: Value(lastSyncAt ?? now),
          ),
        );
        break;
    }
  }

  // Reset sync retry count
  Future<void> resetSyncRetryCount(String tableName, String recordId) async {
    switch (tableName) {
      case 'users':
        await (update(users)..where((u) => u.id.equals(recordId))).write(
          const UsersCompanion(syncRetryCount: Value(0)),
        );
        break;
      case 'exercise_types':
        await (update(exerciseTypes)..where((et) => et.id.equals(recordId))).write(
          const ExerciseTypesCompanion(syncRetryCount: Value(0)),
        );
        break;
      case 'exercises':
        await (update(exercises)..where((e) => e.id.equals(recordId))).write(
          const ExercisesCompanion(syncRetryCount: Value(0)),
        );
        break;
      case 'workouts':
        await (update(workouts)..where((w) => w.id.equals(recordId))).write(
          const WorkoutsCompanion(syncRetryCount: Value(0)),
        );
        break;
    }
  }

  // Increment sync retry count
  Future<void> incrementSyncRetryCount(String tableName, String recordId) async {
    switch (tableName) {
      case 'users':
        await customUpdate(
          'UPDATE users SET sync_retry_count = sync_retry_count + 1 WHERE id = ?',
          variables: [Variable.withString(recordId)],
        );
        break;
      case 'exercise_types':
        await customUpdate(
          'UPDATE exercise_types SET sync_retry_count = sync_retry_count + 1 WHERE id = ?',
          variables: [Variable.withString(recordId)],
        );
        break;
      case 'exercises':
        await customUpdate(
          'UPDATE exercises SET sync_retry_count = sync_retry_count + 1 WHERE id = ?',
          variables: [Variable.withString(recordId)],
        );
        break;
      case 'workouts':
        await customUpdate(
          'UPDATE workouts SET sync_retry_count = sync_retry_count + 1 WHERE id = ?',
          variables: [Variable.withString(recordId)],
        );
        break;
    }
  }
}

