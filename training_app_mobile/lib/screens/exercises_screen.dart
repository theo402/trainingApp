import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise.dart';
import '../models/exercise_type.dart';
import 'create_exercise_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String? _selectedCategory;
  String? _selectedExerciseTypeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ExerciseProvider>(
        builder: (context, exerciseProvider, child) {
          if (exerciseProvider.isLoading && exerciseProvider.exercises.isEmpty) {
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
                    'Error loading exercises',
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
                      exerciseProvider.loadExercises(refresh: true);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filters
              _buildFilters(exerciseProvider),

              // Exercises List
              Expanded(
                child: exerciseProvider.exercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No exercises found',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _hasActiveFilters()
                                  ? 'Try adjusting your filters'
                                  : 'Create your first exercise to get started',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_hasActiveFilters()) ...[
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = null;
                                    _selectedExerciseTypeId = null;
                                  });
                                  exerciseProvider.clearFilter();
                                },
                                child: const Text('Clear Filters'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => exerciseProvider.loadExercises(
                          category: _selectedCategory,
                          exerciseTypeId: _selectedExerciseTypeId,
                          refresh: true,
                        ),
                        child: ListView.builder(
                          itemCount: exerciseProvider.exercises.length,
                          itemBuilder: (context, index) {
                            final exercise = exerciseProvider.exercises[index];
                            return _ExerciseCard(exercise: exercise);
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
              builder: (context) => const CreateExerciseScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters(ExerciseProvider exerciseProvider) {
    final categories = exerciseProvider.categories;
    final exerciseTypes = exerciseProvider.exerciseTypes;

    if (categories.isEmpty && exerciseTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Filter
          if (categories.isNotEmpty) ...[
            Text(
              'Category',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = null;
                        _selectedExerciseTypeId = null;
                      });
                      exerciseProvider.setFilter(
                        category: null,
                        exerciseTypeId: null,
                      );
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
                          _selectedExerciseTypeId = null;
                        });
                        exerciseProvider.setFilter(
                          category: _selectedCategory,
                          exerciseTypeId: null,
                        );
                      },
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Exercise Type Filter
          if (exerciseTypes.isNotEmpty) ...[
            Text(
              'Exercise Type',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedExerciseTypeId == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedExerciseTypeId = null;
                      });
                      exerciseProvider.setFilter(
                        category: _selectedCategory,
                        exerciseTypeId: null,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ...exerciseProvider.getExerciseTypesByCategory(_selectedCategory).map((exerciseType) =>
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(exerciseType.name),
                        selected: _selectedExerciseTypeId == exerciseType.id,
                        onSelected: (_) {
                          setState(() {
                            _selectedExerciseTypeId =
                                _selectedExerciseTypeId == exerciseType.id ? null : exerciseType.id;
                          });
                          exerciseProvider.setFilter(
                            category: _selectedCategory,
                            exerciseTypeId: _selectedExerciseTypeId,
                          );
                        },
                      ),
                    )
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null || _selectedExerciseTypeId != null;
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.fitness_center,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          exercise.name ?? exercise.exerciseTypeName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  exercise.exerciseTypeName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (exercise.metadata.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${exercise.metadata.length} fields',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Created ${_formatDate(exercise.createdAt)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateExerciseScreen(exercise: exercise),
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
        isThreeLine: true,
        onTap: () {
          _showExerciseDetails(context);
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showExerciseDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  exercise.name ?? exercise.exerciseTypeName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Exercise Type
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      exercise.exerciseTypeName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),


                // Metadata
                if (exercise.metadata.isNotEmpty) ...[
                  Text(
                    'Exercise Data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: exercise.metadata.entries.map((entry) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(entry.value.toString()),
                            dense: true,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No additional exercise data',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
          'Are you sure you want to delete "${exercise.name}"? This action cannot be undone.',
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
              final success = await exerciseProvider.deleteExercise(exercise.id);

              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(exerciseProvider.error ?? 'Failed to delete exercise'),
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