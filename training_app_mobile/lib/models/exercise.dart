class Exercise {
  final String id;
  final String userId;
  final String exerciseTypeId;
  final String exerciseTypeName;
  final String? exerciseTypeCategory;
  final String? workoutId;
  final String? name;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime performedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    required this.id,
    required this.userId,
    required this.exerciseTypeId,
    required this.exerciseTypeName,
    this.exerciseTypeCategory,
    this.workoutId,
    this.name,
    this.notes,
    required this.metadata,
    required this.performedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      userId: json['user_id'],
      exerciseTypeId: json['exercise_type_id'],
      exerciseTypeName: json['exercise_type_name'],
      exerciseTypeCategory: json['exercise_type_category'],
      workoutId: json['workout_id'],
      name: json['name'],
      notes: json['notes'],
      metadata: json['metadata'] ?? {},
      performedAt: DateTime.parse(json['performed_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exercise_type_id': exerciseTypeId,
      'exercise_type_name': exerciseTypeName,
      'exercise_type_category': exerciseTypeCategory,
      'workout_id': workoutId,
      'name': name,
      'notes': notes,
      'metadata': metadata,
      'performed_at': performedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName {
    return name ?? exerciseTypeName;
  }
}

class CreateExerciseRequest {
  final String exerciseTypeId;
  final String? workoutId;
  final String? name;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime? performedAt;

  CreateExerciseRequest({
    required this.exerciseTypeId,
    this.workoutId,
    this.name,
    this.notes,
    this.metadata,
    this.performedAt,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'exercise_type_id': exerciseTypeId,
    };

    if (workoutId != null) json['workout_id'] = workoutId;
    if (name != null) json['name'] = name;
    if (notes != null) json['notes'] = notes;
    if (metadata != null) json['metadata'] = metadata;
    if (performedAt != null) json['performed_at'] = performedAt!.toIso8601String();

    return json;
  }
}

class UpdateExerciseRequest {
  final String? exerciseTypeId;
  final String? workoutId;
  final String? name;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime? performedAt;

  UpdateExerciseRequest({
    this.exerciseTypeId,
    this.workoutId,
    this.name,
    this.notes,
    this.metadata,
    this.performedAt,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (exerciseTypeId != null) json['exercise_type_id'] = exerciseTypeId;
    if (workoutId != null) json['workout_id'] = workoutId;
    if (name != null) json['name'] = name;
    if (notes != null) json['notes'] = notes;
    if (metadata != null) json['metadata'] = metadata;
    if (performedAt != null) json['performed_at'] = performedAt!.toIso8601String();

    return json;
  }
}