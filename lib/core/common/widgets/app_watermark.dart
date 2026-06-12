import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// ويدجت العلامة المائية للبرنامج (App Watermark)
/// ──────────────────────────────────────────────────────────────────────────────
/// تعرض اسم التطبيق ورقمه في تذييل الصفحات بنسبة شفافية خفيفة.
class AppWatermark extends StatelessWidget {
  const AppWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: 0.35,
      child: Text(
        'Sparta Gym v1.0.0',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
