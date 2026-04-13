import 'package:flutter/material.dart';

class WelcomeButton extends StatelessWidget {
  const WelcomeButton({
    super.key,
    required this.buttonText,
    required this.onTap,
    this.color = Colors.white,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 30,
      vertical: 20,
    ),
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(50),
      bottomRight: Radius.circular(20),
    ),
  });

  final String buttonText;
  final VoidCallback onTap;
  final Color color;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final isTransparent = color.a == 0;

    final resolvedTextColor = textColor ??
        (isTransparent
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onPrimary);

    return Semantics(
      button: true,
      label: buttonText,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            boxShadow: [
              if (!isTransparent)
                BoxShadow(
                  color: Theme.of(context)
                      .shadowColor
                      .withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            mouseCursor: SystemMouseCursors.click,
            child: Padding(
              padding: padding,
              child: Text(
                buttonText,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      color: resolvedTextColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
