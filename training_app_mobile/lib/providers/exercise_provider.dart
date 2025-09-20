import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/exercise_type.dart';
import '../services/exercise_service.dart';
import '../services/exercise_type_service.dart';
import '../services/simple_local_storage_service.dart';
import '../services/simple_sync_service.dart';

class ExerciseProvider extends ChangeNotifier {
  final ExerciseService _exerciseService = ExerciseService();
  final ExerciseTypeService _exerciseTypeService = ExerciseTypeService();

  SimpleLocalStorageService? _localStorageService;
  SimpleSyncService? _syncService;

  List<Exercise> _exercises = [];
  List<ExerciseType> _exerciseTypes = [];
  bool _isLoading = false;
  String? _error;

  List<Exercise> get exercises => _exercises;
  List<ExerciseType> get exerciseTypes => _exerciseTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter state
  String? _selectedCategory;
  String? _selectedExerciseTypeId;

  String? get selectedCategory => _selectedCategory;
  String? get selectedExerciseTypeId => _selectedExerciseTypeId;

  // Initialize with local storage and sync service
  void initialize(SimpleLocalStorageService localStorageService, SimpleSyncService syncService) {
    _localStorageService = localStorageService;
    _syncService = syncService;
  }

  Future<void> loadExercises({
    String? category,
    String? exerciseTypeId,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Always load from local storage first (offline-first approach)
      if (_localStorageService != null) {
        _exercises = await _localStorageService!.getExercises(
          category: category,
          exerciseTypeId: exerciseTypeId,
        );
        _isLoading = false;
        notifyListeners();
      }

      // Try to sync in background if online
      if (_syncService != null && !refresh) {
        _syncService!.syncAll().catchError((e) {
          // Silent background sync failure
          debugPrint('Background sync failed: $e');
        });
      }

      // If refresh requested or no local data, try API
      if (refresh || _exercises.isEmpty) {
        try {
          final apiExercises = await _exerciseService.getExercises(
            category: category,
            exerciseTypeId: exerciseTypeId,
          );

          // Save to local storage
          if (_localStorageService != null) {
            for (final exercise in apiExercises) {
              await _localStorageService!.saveExercise(exercise, markForSync: false);
            }
          }

          _exercises = apiExercises;
        } catch (e) {
          // If API fails but we have local data, that's okay
          if (_exercises.isEmpty) {
            _error = e.toString();
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadExerciseTypes({bool refresh = false}) async {
    if (_exerciseTypes.isNotEmpty && !refresh) return;

    try {
      // Load from local storage first
      if (_localStorageService != null) {
        _exerciseTypes = await _localStorageService!.getExerciseTypes();
        notifyListeners();
      }

      // If refresh requested or no local data, try API
      if (refresh || _exerciseTypes.isEmpty) {
        try {
          final apiTypes = await _exerciseTypeService.getExerciseTypes();

          // Save to local storage
          if (_localStorageService != null) {
            for (final exerciseType in apiTypes) {
              await _localStorageService!.saveExerciseType(exerciseType, markForSync: false);
            }
          }

          _exerciseTypes = apiTypes;
          notifyListeners();
        } catch (e) {
          // If API fails but we have local data, that's okay
          if (_exerciseTypes.isEmpty) {
            _error = e.toString();
            notifyListeners();
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Exercise?> createExercise(CreateExerciseRequest request) async {
    try {
      // Create locally first with generated ID
      final exercise = Exercise(
        id: _localStorageService?.generateId() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current-user', // You'd get this from auth
        exerciseTypeId: request.exerciseTypeId,
        exerciseTypeName: 'Unknown', // You'd fetch this
        exerciseTypeCategory: null,
        workoutId: request.workoutId,
        name: request.name,
        notes: request.notes,
        metadata: request.metadata ?? {},
        performedAt: request.performedAt ?? DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to local storage
      if (_localStorageService != null) {
        await _localStorageService!.saveExercise(exercise, markForSync: true);
      }

      // Add to local list
      _exercises.insert(0, exercise);
      notifyListeners();

      // Try to sync in background
      if (_syncService != null) {
        _syncService!.syncAll().catchError((e) {
          debugPrint('Background sync after create failed: $e');
        });
      }

      return exercise;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Exercise?> updateExercise(String id, UpdateExerciseRequest request) async {
    try {
      final updatedExercise = await _exerciseService.updateExercise(id, request);
      final index = _exercises.indexWhere((e) => e.id == id);
      if (index != -1) {
        _exercises[index] = updatedExercise;
        notifyListeners();
      }
      return updatedExercise;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteExercise(String id) async {
    try {
      await _exerciseService.deleteExercise(id);
      _exercises.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<ExerciseType?> createExerciseType(CreateExerciseTypeRequest request) async {
    try {
      final exerciseType = await _exerciseTypeService.createExerciseType(request);
      _exerciseTypes.add(exerciseType);
      notifyListeners();
      return exerciseType;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<ExerciseType?> updateExerciseType(String id, CreateExerciseTypeRequest request) async {
    try {
      final updatedExerciseType = await _exerciseTypeService.updateExerciseType(id, request);
      final index = _exerciseTypes.indexWhere((et) => et.id == id);
      if (index != -1) {
        _exerciseTypes[index] = updatedExerciseType;
        notifyListeners();
      }
      return updatedExerciseType;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteExerciseType(String id) async {
    try {
      await _exerciseTypeService.deleteExerciseType(id);
      _exerciseTypes.removeWhere((et) => et.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setFilter({String? category, String? exerciseTypeId}) {
    _selectedCategory = category;
    _selectedExerciseTypeId = exerciseTypeId;
    loadExercises(
      category: category,
      exerciseTypeId: exerciseTypeId,
      refresh: true,
    );
  }

  void clearFilter() {
    _selectedCategory = null;
    _selectedExerciseTypeId = null;
    loadExercises(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<String> get categories {
    final categories = _exerciseTypes
        .where((et) => et.category != null)
        .map((et) => et.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  List<ExerciseType> getExerciseTypesByCategory(String? category) {
    if (category == null) return _exerciseTypes;
    return _exerciseTypes.where((et) => et.category == category).toList();
  }
}