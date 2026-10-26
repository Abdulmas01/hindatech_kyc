import '../models/document_quality_assessment.dart';

class DocumentQualityGuidance {
  const DocumentQualityGuidance({
    required this.signal,
    required this.confidence,
    required this.isStable,
    required this.suggestsCaptureReady,
  });

  final DocumentQualitySignal signal;
  final double confidence;
  final bool isStable;

  /// Whether local guidance suggests that auto-capture may begin its hold.
  ///
  /// This is a capture UX signal only, not a verification decision.
  final bool suggestsCaptureReady;
}

/// Stabilizes local frame assessments so capture guidance does not flicker.
class DocumentQualityGuidanceService {
  DocumentQualitySignal _activeSignal = DocumentQualitySignal.unknown;
  DocumentQualitySignal? _pendingSignal;
  int _pendingCount = 0;

  DocumentQualitySignal get activeSignal => _activeSignal;

  void reset() {
    _activeSignal = DocumentQualitySignal.unknown;
    _pendingSignal = null;
    _pendingCount = 0;
  }

  DocumentQualityGuidance evaluate({
    required DocumentQualityAssessment assessment,
    required int stabilityFrames,
  }) {
    if (stabilityFrames <= 0) {
      throw ArgumentError.value(
        stabilityFrames,
        'stabilityFrames',
        'Must be greater than zero.',
      );
    }

    if (assessment.signal == _activeSignal) {
      _pendingSignal = null;
      _pendingCount = 0;
      return _guidance(assessment, isStable: true);
    }

    if (_pendingSignal != assessment.signal) {
      _pendingSignal = assessment.signal;
      _pendingCount = 1;
    } else {
      _pendingCount++;
    }

    if (_pendingCount >= stabilityFrames) {
      _activeSignal = assessment.signal;
      _pendingSignal = null;
      _pendingCount = 0;
      return _guidance(assessment, isStable: true);
    }

    return DocumentQualityGuidance(
      signal: _activeSignal,
      confidence: assessment.confidence,
      isStable: false,
      suggestsCaptureReady: false,
    );
  }

  DocumentQualityGuidance _guidance(
    DocumentQualityAssessment assessment, {
    required bool isStable,
  }) {
    return DocumentQualityGuidance(
      signal: _activeSignal,
      confidence: assessment.confidence,
      isStable: isStable,
      suggestsCaptureReady:
          isStable && assessment.signal == DocumentQualitySignal.good,
    );
  }
}
