import 'package:flutter/material.dart';

import '../features/document_capture/presentation/widgets/document_capture_overlay.dart';

class HindatechKycTheme {
  const HindatechKycTheme({
    this.primaryColor = const Color(0xFF176B3A),
    this.onPrimaryColor = Colors.white,
    this.surfaceColor = Colors.white,
    this.onSurfaceColor = const Color(0xFF1A1C1A),
    this.errorColor = const Color(0xFFBA1A1A),
    this.spacing = 16,
    this.controlRadius = 12,
    this.overlayStyle = const DocumentCaptureOverlayStyle(),
  });

  final Color primaryColor;
  final Color onPrimaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color errorColor;
  final double spacing;
  final double controlRadius;
  final DocumentCaptureOverlayStyle overlayStyle;

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
