import 'package:flutter/material.dart';

/// Pluggable interface for the splash scene so a Rive (.riv) state machine
/// can be swapped in later without modifying callers.
abstract class SplashScene {
  Widget buildScene({
    required BuildContext context,
    required double progress, // 0.0 to 1.0
    required bool isDark,
    required VoidCallback onSkip,
  });
}
