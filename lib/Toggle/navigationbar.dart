import 'package:flutter/material.dart';
import 'package:practice/Pages/addcategories.dart';
import 'package:practice/Pages/report.dart';
import 'package:practice/Pages/setting.dart';
import 'package:practice/screen/home_page.dart';
import 'package:practice/services/auth_service.dart';

class Navigationbar extends StatefulWidget {
  final String userName;
  final String? userPhotoUrl;
  const Navigationbar({
    super.key,
    required this.userName,
    this.userPhotoUrl,
  });

  @override
  State<Navigationbar> createState() =>
      _NavigationbarState();
}

class _NavigationbarState extends State<Navigationbar> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AuthService.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Sign out failed. Please try again.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final normalizedPhotoUrl =
        (widget.userPhotoUrl?.trim().isNotEmpty ?? false)
            ? widget.userPhotoUrl
            : null;

    _pages = [
      MyHomePage(userName: widget.userName),
      const Addcategories(),
      const ReportPage(),
      Setting(
        userName: widget.userName,
        onLogout: _handleLogout,
        userPhotoUrl: normalizedPhotoUrl,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconSize: 26,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.outline,
          onTap: (index) =>
              setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.category_rounded),
                label: "Categories"),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: "Report"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: "Settings"),
          ],
        ),
      ),
    );
  }
}
