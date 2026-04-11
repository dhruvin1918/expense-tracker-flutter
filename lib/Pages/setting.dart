import 'package:flutter/material.dart';
import 'package:practice/providers/theme_provider.dart';
import 'package:practice/services/reset_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Setting extends StatefulWidget {
  final VoidCallback onLogout;
  final String userName;
  final String? userPhotoUrl;

  const Setting({
    super.key,
    required this.userName,
    required this.onLogout,
    this.userPhotoUrl,
  });

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool _isResetting = false;
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://app-privacy-policy-generator.firebaseapp.com/',
  );

  Future<void> _openPrivacyPolicy() async {
    final launched = await launchUrl(
      _privacyPolicyUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Unable to open privacy policy link.'),
        ),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    if (_isResetting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete all income, expenses and reset wallets.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isResetting = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await ResetService.resetUserData();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Data reset successfully')),
      );
    } catch (e) {
      debugPrint('Reset error: $e');
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Reset failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isResetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

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
                      backgroundImage: (widget
                                      .userPhotoUrl !=
                                  null &&
                              widget.userPhotoUrl!
                                  .trim()
                                  .isNotEmpty)
                          ? NetworkImage(
                              widget.userPhotoUrl!)
                          : const AssetImage(
                                  'assets/images/logo.png')
                              as ImageProvider,
                      onBackgroundImageError: (_, __) {},
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.userName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Signed in user',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
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
                style:
                    theme.textTheme.titleMedium?.copyWith(
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
                onChanged: (value) {
                  themeProvider.setDarkMode(value);
                },
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
                style:
                    theme.textTheme.titleMedium?.copyWith(
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
                leading: Icon(Icons.logout,
                    color: colorScheme.error),
                title: const Text("Logout"),
                subtitle: const Text(
                    "Sign out from this account"),
                onTap: widget.onLogout,
              ),
            ),

            const SizedBox(height: 10),

            // 🔹 RESET DATA
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.delete_forever,
                    color: colorScheme.error),
                title: const Text("Reset Data"),
                subtitle: const Text(
                    "Delete all income, expenses and reset wallets"),
                trailing: _isResetting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : null,
                onTap: _isResetting
                    ? null
                    : () => _confirmReset(context),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.privacy_tip_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text('Privacy Policy'),
                trailing:
                    const Icon(Icons.open_in_new, size: 16),
                onTap: _openPrivacyPolicy,
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
              // TODO: Replace with PackageInfo.fromPlatform() via package_info_plus.
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
