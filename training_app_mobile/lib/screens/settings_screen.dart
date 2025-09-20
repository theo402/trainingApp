import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          const SizedBox(height: 8),
          _buildAppearanceSettings(context),

          const SizedBox(height: 32),

          // Account Section
          _buildSectionHeader(context, 'Account'),
          const SizedBox(height: 8),
          _buildAccountSettings(context),

          const SizedBox(height: 32),

          // About Section
          _buildSectionHeader(context, 'About'),
          const SizedBox(height: 8),
          _buildAboutSettings(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildAppearanceSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme'),
                subtitle: Text('Current: ${settingsProvider.themeModeDisplayName}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, settingsProvider),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                subtitle: Text(authProvider.user?.displayName ?? 'Not logged in'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile settings coming soon!')),
                  );
                },
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Settings'),
            subtitle: const Text('Manage data synchronization'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to sync settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync settings coming soon!')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Training App',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.fitness_center, size: 48),
                children: [
                  const Text('Track your exercises and workouts with this offline-first training app.'),
                ],
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon!')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(_getThemeModeDisplayName(mode)),
              subtitle: Text(_getThemeModeDescription(mode)),
              value: mode,
              groupValue: settingsProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout? Your offline data will remain on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getThemeModeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System Default';
    }
  }

  String _getThemeModeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow system theme';
    }
  }
}