import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({
    super.key,
    required this.child,
    this.showAppBar = true,
  });

  final Widget child;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              iconTheme: IconThemeData(
                  color: colorScheme.onSurface),
              backgroundColor: Colors.transparent,
            )
          : null,
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Image.asset(
            'assets/images/login_background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: colorScheme.surface),
          ),
          if (Theme.of(context).brightness ==
              Brightness.dark)
            Container(
                color:
                    Colors.black.withValues(alpha: 0.45)),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
