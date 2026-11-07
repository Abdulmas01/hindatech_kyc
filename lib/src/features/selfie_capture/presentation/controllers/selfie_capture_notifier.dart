import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/active_guidance.dart';
import '../models/selfie_capture_state.dart';

class SelfieCaptureNotifier extends AutoDisposeNotifier<SelfieCaptureState> {
  @override
  SelfieCaptureState build() => const SelfieCaptureState();

  void beginInitialization(SelfieCameraStartupStage stage) {
    state = SelfieCaptureState(
      phase: SelfieCapturePhase.initializing,
      startupStage: stage,
      guidance: state.guidance,
    );
  }

  void setStartupStage(SelfieCameraStartupStage stage) {
    if (state.phase != SelfieCapturePhase.initializing) return;
    state = state.copyWith(startupStage: stage);
  }

  void markSlowStartup() {
    if (state.phase != SelfieCapturePhase.initializing) return;
    state = state.copyWith(isSlowStartup: true);
  }

  void setReady() {
    state = state.copyWith(
      phase: SelfieCapturePhase.ready,
      startupStage: null,
      isSlowStartup: false,
      error: null,
    );
  }

  void setPaused() {
    state = state.copyWith(
      phase: SelfieCapturePhase.paused,
      startupStage: null,
      isSlowStartup: false,
    );
  }

  void updateGuidance(ActiveGuidanceState guidance) {
    final phase = guidance.hasTimedOut
        ? SelfieCapturePhase.timedOut
        : guidance.suggestsCapture
            ? SelfieCapturePhase.captureSuggested
            : SelfieCapturePhase.analyzing;
    state = state.copyWith(
      phase: phase,
      startupStage: null,
      guidance: guidance,
      error: null,
    );
  }

  void setCapturing() {
    state = state.copyWith(
      phase: SelfieCapturePhase.capturing,
      error: null,
    );
  }

  void setCaptured() {
    state = state.copyWith(
      phase: SelfieCapturePhase.captured,
      error: null,
    );
  }

  void setPermissionDenied({required bool permanentlyDenied}) {
    state = state.copyWith(
      phase: permanentlyDenied
          ? SelfieCapturePhase.permissionPermanentlyDenied
          : SelfieCapturePhase.permissionDenied,
      startupStage: null,
      isSlowStartup: false,
      error: null,
    );
  }

  void setCameraUnavailable(Object error) {
    state = state.copyWith(
      phase: SelfieCapturePhase.cameraUnavailable,
      startupStage: null,
      isSlowStartup: false,
      error: error,
    );
  }

  void setFailure(Object error) {
    state = state.copyWith(
      phase: SelfieCapturePhase.failed,
      startupStage: null,
      error: error,
    );
  }

  void reset() => state = const SelfieCaptureState();
}

final selfieCaptureProvider =
    AutoDisposeNotifierProvider<SelfieCaptureNotifier, SelfieCaptureState>(
  SelfieCaptureNotifier.new,
);
