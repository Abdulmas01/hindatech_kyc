import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/document_quality_assessment.dart';
import '../../domain/services/document_quality_guidance_service.dart';
import '../models/document_capture_state.dart';

class DocumentCaptureNotifier
    extends AutoDisposeNotifier<DocumentCaptureState> {
  @override
  DocumentCaptureState build() => const DocumentCaptureState();

  void setReady() {
    state = state.copyWith(
      phase: DocumentCapturePhase.ready,
      error: null,
    );
  }

  void setDetecting(bool value) {
    state = state.copyWith(
      phase:
          value ? DocumentCapturePhase.detecting : DocumentCapturePhase.ready,
    );
  }

  void setPermissionDenied({required bool permanentlyDenied}) {
    state = state.copyWith(
      phase: permanentlyDenied
          ? DocumentCapturePhase.permissionPermanentlyDenied
          : DocumentCapturePhase.permissionDenied,
      documentDetected: false,
      isAutoCapturing: false,
      capturedPreviewPath: null,
      error: null,
    );
  }

  void setCameraUnavailable(Object error) {
    state = state.copyWith(
      phase: DocumentCapturePhase.cameraUnavailable,
      isAutoCapturing: false,
      error: error,
    );
  }

  void setDocumentDetected(bool value) {
    state = state.copyWith(
      documentDetected: value,
      capturedPreviewPath: value ? state.capturedPreviewPath : null,
    );
  }

  void setCaptured(String previewPath) {
    state = state.copyWith(
      phase: DocumentCapturePhase.captured,
      documentDetected: true,
      capturedPreviewPath: previewPath,
      isAutoCapturing: false,
      error: null,
    );
  }

  void clearCaptured() {
    state = state.copyWith(
      phase: DocumentCapturePhase.ready,
      documentDetected: false,
      qualitySignal: DocumentQualitySignal.unknown,
      qualityConfidence: 0,
      isQualityStable: false,
      suggestsCaptureReady: false,
      capturedPreviewPath: null,
    );
  }

  void setAutoCapturing(bool value) {
    state = state.copyWith(isAutoCapturing: value);
  }

  void updateQuality(DocumentQualityGuidance guidance) {
    state = state.copyWith(
      qualitySignal: guidance.signal,
      qualityConfidence: guidance.confidence,
      isQualityStable: guidance.isStable,
      suggestsCaptureReady: guidance.suggestsCaptureReady,
      error: null,
    );
  }

  void clearQualityGuidance() {
    state = state.copyWith(
      qualitySignal: DocumentQualitySignal.unknown,
      qualityConfidence: 0,
      isQualityStable: false,
      suggestsCaptureReady: false,
      isAutoCapturing: false,
    );
  }

  void setFailure(Object error) {
    state = state.copyWith(
      phase: DocumentCapturePhase.failed,
      isAutoCapturing: false,
      error: error,
    );
  }

  void reset() {
    state = const DocumentCaptureState();
  }
}

final documentCaptureProvider =
    AutoDisposeNotifierProvider<DocumentCaptureNotifier, DocumentCaptureState>(
  DocumentCaptureNotifier.new,
);
