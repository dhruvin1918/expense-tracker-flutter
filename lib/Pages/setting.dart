import 'package:flutter/material.dart';
import 'package:practice/services/reset_service.dart';

class Setting extends StatelessWidget {
  final VoidCallback onLogout;
  final String userEmail;
  final String? userPhotoUrl;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const Setting({
    super.key,
    required this.userEmail,
    required this.onLogout,
    this.userPhotoUrl,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  void _confirmReset(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Reset All Data'),
      content: const Text(
        'This will permanently delete all income, expenses and reset wallets.\n\nThis action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () async {
            Navigator.pop(context);

            await ResetService.resetUserData();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Database reset successfully')),
            );
          },
          child: const Text('Reset'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔹 PROFILE CARD
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: userPhotoUrl != null
                          ? NetworkImage(userPhotoUrl!)
                          : const AssetImage(
                                  'assets/images/logo.png')
                              as ImageProvider,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userEmail.split('@')[0],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 APPEARANCE
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Appearance",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: const Text("Dark Mode"),
                subtitle: const Text("Enable dark theme"),
                value: isDarkMode,
                onChanged: onThemeChanged,
                secondary: Icon(
                  isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 ACCOUNT
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Account",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.logout, color: colorScheme.error),
                title: const Text("Logout"),
                subtitle: const Text("Sign out from this account"),
                onTap: onLogout,
              ),
            ),

            const SizedBox(height: 10),
            
            // 🔹 RESET DATA
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.refresh, color: colorScheme.error),
                title: const Text("Reset Data"),
                subtitle: const Text("Delete all income, expenses and reset wallets"),
                onTap: () => _confirmReset(context),
              ),
            ),

            const SizedBox(height: 40),
            // 🔹 RESET DATA

            // 🔹 FOOTER
            Text(
              "Expense Tracker",
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            Text(
              "Version 1.0.0",
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
