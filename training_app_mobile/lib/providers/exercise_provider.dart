import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/exercise_type.dart';
import '../services/exercise_service.dart';
import '../services/exercise_type_service.dart';

class ExerciseProvider extends ChangeNotifier {
  final ExerciseService _exerciseService = ExerciseService();
  final ExerciseTypeService _exerciseTypeService = ExerciseTypeService();

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
      _exercises = await _exerciseService.getExercises(
        category: category,
        exerciseTypeId: exerciseTypeId,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadExerciseTypes({bool refresh = false}) async {
    if (_exerciseTypes.isNotEmpty && !refresh) return;

    try {
      _exerciseTypes = await _exerciseTypeService.getExerciseTypes();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Exercise?> createExercise(CreateExerciseRequest request) async {
    try {
      final exercise = await _exerciseService.createExercise(request);
      _exercises.insert(0, exercise);
      notifyListeners();
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