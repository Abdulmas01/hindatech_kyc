import 'package:flutter/material.dart';

import '../features/selfie_capture/presentation/widgets/selfie_capture_overlay.dart';

/// Visual customization for the selfie capture experience.
class SelfieCaptureTheme {
  const SelfieCaptureTheme({
    this.primaryColor = const Color(0xFF176B3A),
    this.onPrimaryColor = Colors.white,
    this.surfaceColor = const Color(0xFF101411),
    this.onSurfaceColor = Colors.white,
    this.errorColor = const Color(0xFFFFB4AB),
    this.guidanceSurfaceColor = const Color(0xD91A1F1B),
    this.onGuidanceSurfaceColor = Colors.white,
    this.spacing = 16,
    this.controlRadius = 20,
    this.guidanceRadius = 18,
    this.transitionDuration = const Duration(milliseconds: 280),
    this.overlayStyle = const SelfieCaptureOverlayStyle(),
  });

  final Color primaryColor;
  final Color onPrimaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color errorColor;
  final Color guidanceSurfaceColor;
  final Color onGuidanceSurfaceColor;
  final double spacing;
  final double controlRadius;
  final double guidanceRadius;
  final Duration transitionDuration;
  final SelfieCaptureOverlayStyle overlayStyle;

  ThemeData applyTo(ThemeData base) {
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        error: errorColor,
      ),
    );
  }
}
