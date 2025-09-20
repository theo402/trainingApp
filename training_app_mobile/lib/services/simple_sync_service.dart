import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum SyncState {
  idle,
  syncing,
  success,
  error,
}

class SimpleSyncService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  SyncState _syncState = SyncState.idle;
  String? _lastError;
  DateTime? _lastSyncTime;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  SyncState get syncState => _syncState;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  SimpleSyncService() {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      // Auto sync when online for demo purposes
      final hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet
      );

      if (hasConnection && _syncState != SyncState.syncing) {
        _demoSync();
      }
    });
  }

  Future<void> _demoSync() async {
    try {
      await syncAll();
    } catch (e) {
      debugPrint('Demo sync failed: $e');
    }
  }

  Future<void> syncAll() async {
    if (_syncState == SyncState.syncing) return;

    _setSyncState(SyncState.syncing);

    try {
      // Simulate sync process
      await Future.delayed(const Duration(seconds: 2));

      _lastSyncTime = DateTime.now();
      _lastError = null;
      _setSyncState(SyncState.success);

      // Reset to idle after showing success
      Timer(const Duration(seconds: 2), () {
        if (_syncState == SyncState.success) {
          _setSyncState(SyncState.idle);
        }
      });
    } catch (e) {
      _lastError = e.toString();
      _setSyncState(SyncState.error);
      rethrow;
    }
  }

  void _setSyncState(SyncState state) {
    _syncState = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}