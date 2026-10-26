import '../../domain/models/document_quality_assessment.dart';

enum DocumentCapturePhase {
  initializing,
  ready,
  detecting,
  captured,
  permissionDenied,
  permissionPermanentlyDenied,
  cameraUnavailable,
  failed,
}

class DocumentCaptureState {
  static const Object _unset = Object();

  const DocumentCaptureState({
    this.phase = DocumentCapturePhase.initializing,
    this.documentDetected = false,
    this.qualitySignal = DocumentQualitySignal.unknown,
    this.isQualityStable = false,
    this.suggestsCaptureReady = false,
    this.qualityConfidence = 0,
    this.isAutoCapturing = false,
    this.capturedPreviewPath,
    this.error,
  });

  final DocumentCapturePhase phase;
  final bool documentDetected;
  final DocumentQualitySignal qualitySignal;
  final bool isQualityStable;
  final bool suggestsCaptureReady;
  final double qualityConfidence;
  final bool isAutoCapturing;
  final String? capturedPreviewPath;
  final Object? error;

  bool get canCapture =>
      phase == DocumentCapturePhase.ready ||
      phase == DocumentCapturePhase.detecting;

  DocumentCaptureState copyWith({
    DocumentCapturePhase? phase,
    bool? documentDetected,
    DocumentQualitySignal? qualitySignal,
    bool? isQualityStable,
    bool? suggestsCaptureReady,
    double? qualityConfidence,
    bool? isAutoCapturing,
    Object? capturedPreviewPath = _unset,
    Object? error = _unset,
  }) {
    return DocumentCaptureState(
      phase: phase ?? this.phase,
      documentDetected: documentDetected ?? this.documentDetected,
      qualitySignal: qualitySignal ?? this.qualitySignal,
      isQualityStable: isQualityStable ?? this.isQualityStable,
      suggestsCaptureReady: suggestsCaptureReady ?? this.suggestsCaptureReady,
      qualityConfidence: qualityConfidence ?? this.qualityConfidence,
      isAutoCapturing: isAutoCapturing ?? this.isAutoCapturing,
      capturedPreviewPath: identical(capturedPreviewPath, _unset)
          ? this.capturedPreviewPath
          : capturedPreviewPath as String?,
      error: identical(error, _unset) ? this.error : error,
    );
  }
}
