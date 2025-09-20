import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/exercise_provider.dart';
import '../widgets/sync_status_indicator.dart';
import '../services/simple_local_storage_service.dart';
import '../services/simple_sync_service.dart';
import 'exercises_screen.dart';
import 'exercise_types_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ExercisesScreen(),
    const ExerciseTypesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exerciseProvider = Provider.of<ExerciseProvider>(context, listen: false);
      final localStorageService = Provider.of<SimpleLocalStorageService>(context, listen: false);
      final syncService = Provider.of<SimpleSyncService>(context, listen: false);

      // Initialize provider with services
      exerciseProvider.initialize(localStorageService, syncService);

      // Load data (offline-first)
      exerciseProvider.loadExercises();
      exerciseProvider.loadExerciseTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training App'),
        centerTitle: true,
        actions: [
          // Manual sync button
          const ManualSyncButton(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await Provider.of<AuthProvider>(context, listen: false).logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Text(authProvider.user?.displayName ?? 'Profile');
                      },
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          _screens[_selectedIndex],
          // Sync status indicator positioned at top center
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: const SyncStatusIndicator(),
            ),
          ),
          // Floating sync status for errors and syncing states
          const SyncStatusFloatingIndicator(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Exercise Types',
          ),
        ],
      ),
    );
  }
}