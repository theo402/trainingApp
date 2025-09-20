import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simple_sync_service.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleSyncService>(
      builder: (context, syncService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSyncIcon(syncService.syncState),
              const SizedBox(width: 4),
              _buildSyncText(syncService.syncState, syncService.lastError),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyncIcon(SyncState state) {
    switch (state) {
      case SyncState.idle:
        return const Icon(
          Icons.cloud_done,
          size: 16,
          color: Colors.grey,
        );
      case SyncState.syncing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case SyncState.success:
        return const Icon(
          Icons.check_circle,
          size: 16,
          color: Colors.green,
        );
      case SyncState.error:
        return const Icon(
          Icons.error_outline,
          size: 16,
          color: Colors.red,
        );
    }
  }

  Widget _buildSyncText(SyncState state, String? lastError) {
    String text;
    Color color;

    switch (state) {
      case SyncState.idle:
        text = 'Synced';
        color = Colors.grey;
        break;
      case SyncState.syncing:
        text = 'Syncing...';
        color = Colors.blue;
        break;
      case SyncState.success:
        text = 'Synced';
        color = Colors.green;
        break;
      case SyncState.error:
        text = 'Sync failed';
        color = Colors.red;
        break;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class SyncStatusFloatingIndicator extends StatelessWidget {
  const SyncStatusFloatingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleSyncService>(
      builder: (context, syncService, child) {
        // Only show floating indicator when syncing or there's an error
        if (syncService.syncState == SyncState.idle || syncService.syncState == SyncState.success) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 60, // Below app bar
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(syncService.syncState),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (syncService.syncState == SyncState.syncing) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Syncing...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else if (syncService.syncState == SyncState.error) ...[
                      const Icon(
                        Icons.sync_problem,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sync failed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showSyncErrorDialog(context, syncService),
                        child: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(SyncState state) {
    switch (state) {
      case SyncState.syncing:
        return Colors.blue;
      case SyncState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSyncErrorDialog(BuildContext context, SimpleSyncService syncService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(syncService.lastError ?? 'Unknown error occurred'),
            const SizedBox(height: 16),
            const Text(
              'Your data is saved locally and will sync when the connection is restored.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              syncService.syncAll();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class ManualSyncButton extends StatelessWidget {
  const ManualSyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleSyncService>(
      builder: (context, syncService, child) {
        return IconButton(
          onPressed: syncService.syncState == SyncState.syncing
            ? null
            : () => _performManualSync(context, syncService),
          icon: syncService.syncState == SyncState.syncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.sync,
                color: syncService.syncState == SyncState.error
                  ? Colors.red
                  : null,
              ),
          tooltip: _getSyncTooltip(syncService.syncState),
        );
      },
    );
  }

  String _getSyncTooltip(SyncState state) {
    switch (state) {
      case SyncState.idle:
        return 'Sync data';
      case SyncState.syncing:
        return 'Syncing...';
      case SyncState.success:
        return 'Sync successful';
      case SyncState.error:
        return 'Sync failed - tap to retry';
    }
  }

  Future<void> _performManualSync(BuildContext context, SimpleSyncService syncService) async {
    try {
      await syncService.syncAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _performManualSync(context, syncService),
            ),
          ),
        );
      }
    }
  }
}