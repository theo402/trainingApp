class ExerciseType {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final Map<String, dynamic> metadataSchema;
  final bool isGlobal;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExerciseType({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.metadataSchema,
    required this.isGlobal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExerciseType.fromJson(Map<String, dynamic> json) {
    return ExerciseType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      metadataSchema: json['metadata_schema'] ?? {},
      isGlobal: json['is_global'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'metadata_schema': metadataSchema,
      'is_global': isGlobal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get required fields from schema
  List<String> get requiredFields {
    final required = metadataSchema['required'];
    if (required is List) {
      return required.cast<String>();
    }
    return [];
  }

  // Helper method to get properties from schema
  Map<String, dynamic> get properties {
    final props = metadataSchema['properties'];
    if (props is Map<String, dynamic>) {
      return props;
    }
    return {};
  }
}

class CreateExerciseTypeRequest {
  final String name;
  final String? description;
  final String? category;
  final Map<String, dynamic>? metadataSchema;

  CreateExerciseTypeRequest({
    required this.name,
    this.description,
    this.category,
    this.metadataSchema,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'metadata_schema': metadataSchema,
    };
  }
}