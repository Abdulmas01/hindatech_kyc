import '../../domain/models/active_guidance.dart';

enum SelfieCapturePhase {
  initializing,
  ready,
  analyzing,
  paused,
  captureSuggested,
  capturing,
  captured,
  permissionDenied,
  permissionPermanentlyDenied,
  cameraUnavailable,
  timedOut,
  failed,
}

enum SelfieCameraStartupStage {
  requestingPermission,
  discoveringCamera,
  initializingController,
  startingStream,
}

class SelfieCaptureState {
  static const Object _unset = Object();

  const SelfieCaptureState({
    this.phase = SelfieCapturePhase.initializing,
    this.startupStage = SelfieCameraStartupStage.requestingPermission,
    this.guidance,
    this.isSlowStartup = false,
    this.error,
  });

  final SelfieCapturePhase phase;
  final SelfieCameraStartupStage? startupStage;
  final ActiveGuidanceState? guidance;
  final bool isSlowStartup;
  final Object? error;

  bool get showsCameraLoading => phase == SelfieCapturePhase.initializing;

  bool get canAnalyze =>
      phase == SelfieCapturePhase.ready ||
      phase == SelfieCapturePhase.analyzing;

  SelfieCaptureState copyWith({
    SelfieCapturePhase? phase,
    Object? startupStage = _unset,
    Object? guidance = _unset,
    bool? isSlowStartup,
    Object? error = _unset,
  }) {
    return SelfieCaptureState(
      phase: phase ?? this.phase,
      startupStage: identical(startupStage, _unset)
          ? this.startupStage
          : startupStage as SelfieCameraStartupStage?,
      guidance: identical(guidance, _unset)
          ? this.guidance
          : guidance as ActiveGuidanceState?,
      isSlowStartup: isSlowStartup ?? this.isSlowStartup,
      error: identical(error, _unset) ? this.error : error,
    );
  }
}
