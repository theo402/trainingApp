import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise_type.dart';
import 'create_exercise_type_screen.dart';

class ExerciseTypesScreen extends StatefulWidget {
  const ExerciseTypesScreen({super.key});

  @override
  State<ExerciseTypesScreen> createState() => _ExerciseTypesScreenState();
}

class _ExerciseTypesScreenState extends State<ExerciseTypesScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ExerciseProvider>(
        builder: (context, exerciseProvider, child) {
          if (exerciseProvider.isLoading && exerciseProvider.exerciseTypes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (exerciseProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading exercise types',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exerciseProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      exerciseProvider.clearError();
                      exerciseProvider.loadExerciseTypes(refresh: true);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final categories = exerciseProvider.categories;
          final filteredExerciseTypes = _selectedCategory == null
              ? exerciseProvider.exerciseTypes
              : exerciseProvider.getExerciseTypesByCategory(_selectedCategory);

          return Column(
            children: [
              // Category Filter
              if (categories.isNotEmpty)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...categories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = _selectedCategory == category ? null : category;
                            });
                          },
                        ),
                      )),
                    ],
                  ),
                ),

              // Exercise Types List
              Expanded(
                child: filteredExerciseTypes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No exercise types found',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedCategory == null
                                  ? 'Create your first exercise type to get started'
                                  : 'No exercise types in this category',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => exerciseProvider.loadExerciseTypes(refresh: true),
                        child: ListView.builder(
                          itemCount: filteredExerciseTypes.length,
                          itemBuilder: (context, index) {
                            final exerciseType = filteredExerciseTypes[index];
                            return _ExerciseTypeCard(exerciseType: exerciseType);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateExerciseTypeScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExerciseTypeCard extends StatelessWidget {
  final ExerciseType exerciseType;

  const _ExerciseTypeCard({required this.exerciseType});

  @override
  Widget build(BuildContext context) {
    final requiredFields = exerciseType.getRequiredFields();
    final properties = exerciseType.getProperties();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.category,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          exerciseType.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exerciseType.description != null) ...[
              const SizedBox(height: 4),
              Text(
                exerciseType.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (exerciseType.category != null) ...[
              const SizedBox(height: 4),
              Chip(
                label: Text(
                  exerciseType.category!,
                  style: const TextStyle(fontSize: 12),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
            if (requiredFields.isNotEmpty || properties.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: [
                  if (requiredFields.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${requiredFields.length} required',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  if (properties.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${properties.length} fields',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateExerciseTypeScreen(
                    exerciseType: exerciseType,
                  ),
                ),
              );
            } else if (value == 'delete') {
              _showDeleteDialog(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (!exerciseType.isGlobal)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
        isThreeLine: exerciseType.description != null || exerciseType.category != null,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise Type'),
        content: Text(
          'Are you sure you want to delete "${exerciseType.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final exerciseProvider = Provider.of<ExerciseProvider>(context, listen: false);
              final success = await exerciseProvider.deleteExerciseType(exerciseType.id);

              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(exerciseProvider.error ?? 'Failed to delete exercise type'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}