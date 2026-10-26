/// A local observation used to improve the document capture experience.
enum DocumentQualitySignal {
  good,
  blurry,
  glare,
  dark,
  noDocument,
  unknown,
}

/// Identifies how a local quality observation was produced.
enum DocumentQualitySource {
  onDeviceInference,
  heuristic,
}

/// An advisory, device-local assessment of one camera frame.
///
/// This value may guide framing or auto-capture behavior, but it is not an
/// identity-verification result and must not be used as an authoritative
/// accept or reject decision.
class DocumentQualityAssessment {
  const DocumentQualityAssessment({
    required this.signal,
    required this.confidence,
    required this.source,
  }) : assert(confidence >= 0 && confidence <= 1);

  final DocumentQualitySignal signal;

  /// Relative confidence reported by the local assessor, from zero to one.
  ///
  /// The value is not a calibrated verification probability.
  final double confidence;
  final DocumentQualitySource source;

  bool get suggestsCaptureReady => signal == DocumentQualitySignal.good;
}
