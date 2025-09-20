import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise.dart';
import '../models/exercise_type.dart';

class CreateExerciseScreen extends StatefulWidget {
  final Exercise? exercise;

  const CreateExerciseScreen({super.key, this.exercise});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  ExerciseType? _selectedExerciseType;
  final Map<String, dynamic> _metadata = {};
  final Map<String, TextEditingController> _metadataControllers = {};

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.exercise!.name ?? '';
      _metadata.addAll(widget.exercise!.metadata);

      // Find the exercise type
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final exerciseProvider = Provider.of<ExerciseProvider>(context, listen: false);
        _selectedExerciseType = exerciseProvider.exerciseTypes
            .where((et) => et.id == widget.exercise!.exerciseTypeId)
            .firstOrNull;

        if (_selectedExerciseType != null) {
          _initializeMetadataControllers();
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _metadataControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeMetadataControllers() {
    if (_selectedExerciseType == null) return;

    final properties = _selectedExerciseType!.properties;

    // Clear existing controllers
    for (final controller in _metadataControllers.values) {
      controller.dispose();
    }
    _metadataControllers.clear();

    // Create controllers for each property
    for (final property in properties.keys) {
      final controller = TextEditingController();
      if (_metadata.containsKey(property)) {
        controller.text = _metadata[property].toString();
      }
      _metadataControllers[property] = controller;
    }
  }

  void _onExerciseTypeChanged(ExerciseType? exerciseType) {
    setState(() {
      _selectedExerciseType = exerciseType;
      _metadata.clear();
    });
    _initializeMetadataControllers();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedExerciseType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an exercise type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate and collect metadata
    final metadata = <String, dynamic>{};
    final properties = _selectedExerciseType!.properties;
    final required = _selectedExerciseType!.requiredFields;

    for (final property in properties.entries) {
      final key = property.key;
      final schema = property.value;
      final controller = _metadataControllers[key];
      final value = controller?.text.trim() ?? '';

      // Check required fields
      if (required.contains(key) && value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$key is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Convert value based on type
      if (value.isNotEmpty) {
        try {
          final type = schema['type'] as String?;
          switch (type) {
            case 'number':
            case 'integer':
              metadata[key] = double.tryParse(value) ?? int.tryParse(value);
              break;
            case 'boolean':
              metadata[key] = value.toLowerCase() == 'true';
              break;
            default:
              metadata[key] = value;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid value for $key'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    final exerciseProvider = Provider.of<ExerciseProvider>(context, listen: false);

    Exercise? result;
    if (_isEditing) {
      final request = UpdateExerciseRequest(
        name: _nameController.text.trim(),
        exerciseTypeId: _selectedExerciseType!.id,
        metadata: metadata,
      );
      result = await exerciseProvider.updateExercise(widget.exercise!.id, request);
    } else {
      final request = CreateExerciseRequest(
        name: _nameController.text.trim(),
        exerciseTypeId: _selectedExerciseType!.id,
        metadata: metadata,
      );
      result = await exerciseProvider.createExercise(request);
    }

    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exerciseProvider.error ?? 'Failed to save exercise'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Exercise' : 'Create Exercise'),
        actions: [
          Consumer<ExerciseProvider>(
            builder: (context, exerciseProvider, child) {
              return TextButton(
                onPressed: exerciseProvider.isLoading ? null : _saveExercise,
                child: exerciseProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Update' : 'Create'),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Exercise Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an exercise name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<ExerciseProvider>(
                      builder: (context, exerciseProvider, child) {
                        if (exerciseProvider.exerciseTypes.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.category_outlined, size: 48),
                                  SizedBox(height: 8),
                                  Text('No exercise types available'),
                                  Text(
                                    'Create an exercise type first',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<ExerciseType>(
                          value: _selectedExerciseType,
                          decoration: const InputDecoration(
                            labelText: 'Exercise Type *',
                            border: OutlineInputBorder(),
                          ),
                          items: exerciseProvider.exerciseTypes.map((exerciseType) {
                            return DropdownMenuItem(
                              value: exerciseType,
                              child: SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      exerciseType.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    if (exerciseType.category != null)
                                      Text(
                                        exerciseType.category!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _onExerciseTypeChanged,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an exercise type';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Metadata Fields
            if (_selectedExerciseType != null) _buildMetadataFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataFields() {
    final properties = _selectedExerciseType!.properties;
    final required = _selectedExerciseType!.requiredFields;

    if (properties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercise Data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the specific details for this exercise',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ...properties.entries.map((property) {
              final key = property.key;
              final schema = property.value;
              final isRequired = required.contains(key);
              final type = schema['type'] as String? ?? 'string';
              final description = schema['description'] as String?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMetadataField(
                  key: key,
                  type: type,
                  required: isRequired,
                  description: description,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataField({
    required String key,
    required String type,
    required bool required,
    String? description,
  }) {
    final controller = _metadataControllers[key]!;

    Widget field;
    switch (type) {
      case 'boolean':
        field = SwitchListTile(
          title: Text('$key${required ? ' *' : ''}'),
          subtitle: description != null ? Text(description) : null,
          value: controller.text.toLowerCase() == 'true',
          onChanged: (value) {
            controller.text = value.toString();
          },
        );
        break;
      case 'number':
      case 'integer':
        field = TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '$key${required ? ' *' : ''}',
            border: const OutlineInputBorder(),
            helperText: description,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: required ? (value) {
            if (value == null || value.trim().isEmpty) {
              return '$key is required';
            }
            if (double.tryParse(value) == null && int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          } : null,
        );
        break;
      default:
        field = TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '$key${required ? ' *' : ''}',
            border: const OutlineInputBorder(),
            helperText: description,
          ),
          validator: required ? (value) {
            if (value == null || value.trim().isEmpty) {
              return '$key is required';
            }
            return null;
          } : null,
        );
    }

    return field;
  }
}