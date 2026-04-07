import 'package:flutter/material.dart';
import 'package:practice/Pages/addcategories.dart';
import 'package:practice/Pages/setting.dart';
import 'package:practice/screen/home_page.dart';
import 'package:practice/widgets/wrapper.dart';
import 'package:practice/Pages/report.dart';

class Navigationbar extends StatefulWidget {
  final String userName;
  final String? userPhotoUrl;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  const Navigationbar({
    super.key,
    required this.userName,
    this.userPhotoUrl,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<Navigationbar> createState() => _NavigationbarState();
}

class _NavigationbarState extends State<Navigationbar> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  void _handleLogout() async {
    await signOut();
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      MyHomePage(userEmail: widget.userName),
      const Addcategories(),
      const ReportPage(),
      Setting(
        userEmail: widget.userName,
        onLogout: _handleLogout,
        userPhotoUrl: widget.userPhotoUrl,
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
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
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.outline,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.category_rounded), label: "Categories"),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded), label: "Report"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded), label: "Settings"),
          ],
        ),
      ),
    );
  }
}
