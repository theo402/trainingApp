import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise_type.dart';

class CreateExerciseTypeScreen extends StatefulWidget {
  final ExerciseType? exerciseType;

  const CreateExerciseTypeScreen({super.key, this.exerciseType});

  @override
  State<CreateExerciseTypeScreen> createState() => _CreateExerciseTypeScreenState();
}

class _CreateExerciseTypeScreenState extends State<CreateExerciseTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  final List<MetadataField> _metadataFields = [];

  bool get _isEditing => widget.exerciseType != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.exerciseType!.name;
      _descriptionController.text = widget.exerciseType!.description ?? '';
      _categoryController.text = widget.exerciseType!.category ?? '';

      // Load existing metadata fields
      final properties = widget.exerciseType!.getProperties();
      final required = widget.exerciseType!.getRequiredFields();

      for (final property in properties.entries) {
        _metadataFields.add(MetadataField(
          key: property.key,
          type: _getFieldTypeFromSchema(property.value),
          required: required.contains(property.key),
          description: property.value['description'] as String? ?? '',
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String _getFieldTypeFromSchema(Map<String, dynamic> schema) {
    final type = schema['type'] as String?;
    switch (type) {
      case 'integer':
      case 'number':
        return 'number';
      case 'boolean':
        return 'boolean';
      case 'string':
      default:
        return 'text';
    }
  }

  Map<String, dynamic> _buildMetadataSchema() {
    if (_metadataFields.isEmpty) {
      return {};
    }

    final properties = <String, dynamic>{};
    final required = <String>[];

    for (final field in _metadataFields) {
      if (field.key.trim().isEmpty) continue;

      properties[field.key] = {
        'type': field.type == 'number' ? 'number' :
                field.type == 'boolean' ? 'boolean' : 'string',
        if (field.description.isNotEmpty) 'description': field.description,
      };

      if (field.required) {
        required.add(field.key);
      }
    }

    if (properties.isEmpty) return {};

    return {
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    };
  }

  Future<void> _saveExerciseType() async {
    if (!_formKey.currentState!.validate()) return;

    final exerciseProvider = Provider.of<ExerciseProvider>(context, listen: false);

    final request = CreateExerciseTypeRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      metadataSchema: _buildMetadataSchema(),
    );

    ExerciseType? result;
    if (_isEditing) {
      result = await exerciseProvider.updateExerciseType(widget.exerciseType!.id, request);
    } else {
      result = await exerciseProvider.createExerciseType(request);
    }

    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exerciseProvider.error ?? 'Failed to save exercise type'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Exercise Type' : 'Create Exercise Type'),
        actions: [
          Consumer<ExerciseProvider>(
            builder: (context, exerciseProvider, child) {
              return TextButton(
                onPressed: exerciseProvider.isLoading ? null : _saveExerciseType,
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
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Strength, Cardio, Flexibility',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Metadata Fields
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Metadata Fields',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _metadataFields.add(MetadataField(
                                key: '',
                                type: 'text',
                                required: false,
                                description: '',
                              ));
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Field'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Define custom fields that exercises of this type can have',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_metadataFields.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.playlist_add,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No metadata fields yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_metadataFields.length, (index) {
                        return _MetadataFieldEditor(
                          field: _metadataFields[index],
                          onChanged: (updatedField) {
                            setState(() {
                              _metadataFields[index] = updatedField;
                            });
                          },
                          onRemove: () {
                            setState(() {
                              _metadataFields.removeAt(index);
                            });
                          },
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetadataField {
  String key;
  String type;
  bool required;
  String description;

  MetadataField({
    required this.key,
    required this.type,
    required this.required,
    required this.description,
  });
}

class _MetadataFieldEditor extends StatelessWidget {
  final MetadataField field;
  final Function(MetadataField) onChanged;
  final VoidCallback onRemove;

  const _MetadataFieldEditor({
    required this.field,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: field.key,
                    decoration: const InputDecoration(
                      labelText: 'Field Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      onChanged(MetadataField(
                        key: value,
                        type: field.type,
                        required: field.required,
                        description: field.description,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: field.type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('Text')),
                      DropdownMenuItem(value: 'number', child: Text('Number')),
                      DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(MetadataField(
                          key: field.key,
                          type: value,
                          required: field.required,
                          description: field.description,
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: field.description,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      onChanged(MetadataField(
                        key: field.key,
                        type: field.type,
                        required: field.required,
                        description: value,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Checkbox(
                      value: field.required,
                      onChanged: (value) {
                        onChanged(MetadataField(
                          key: field.key,
                          type: field.type,
                          required: value ?? false,
                          description: field.description,
                        ));
                      },
                    ),
                    const Text('Required'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}