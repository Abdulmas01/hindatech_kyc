import 'package:flutter/material.dart';

import '../../../../presentation/document_capture_strings.dart';
import '../../../../presentation/document_capture_theme.dart';
import '../../domain/models/document_quality_assessment.dart';

/// Displays a customer-customizable advisory camera-quality message.
class DocumentQualityGuidanceBanner extends StatelessWidget {
  const DocumentQualityGuidanceBanner({
    required this.signal,
    required this.isStable,
    required this.strings,
    required this.captureTheme,
    super.key,
  });

  final DocumentQualitySignal signal;
  final bool isStable;
  final DocumentCaptureStrings strings;
  final DocumentCaptureTheme captureTheme;

  @override
  Widget build(BuildContext context) {
    final isReady = isStable && signal == DocumentQualitySignal.good;
    final message = _message;
    final color = isReady
        ? captureTheme.qualityReadyColor
        : captureTheme.qualityGuidanceColor;

    return Semantics(
      liveRegion: true,
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(captureTheme.controlRadius),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: captureTheme.spacing,
            vertical: captureTheme.spacing / 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isReady ? Icons.check_circle_outline : Icons.info_outline,
                color: captureTheme.onQualityGuidanceColor,
              ),
              SizedBox(width: captureTheme.spacing / 2),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                    color: captureTheme.onQualityGuidanceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _message {
    if (!isStable) return strings.qualityEvaluatingMessage;
    return switch (signal) {
      DocumentQualitySignal.good => strings.qualityReadyMessage,
      DocumentQualitySignal.blurry => strings.qualityBlurryMessage,
      DocumentQualitySignal.glare => strings.qualityGlareMessage,
      DocumentQualitySignal.dark => strings.qualityDarkMessage,
      DocumentQualitySignal.noDocument => strings.qualityNoDocumentMessage,
      DocumentQualitySignal.unknown => strings.qualityEvaluatingMessage,
    };
  }
}
