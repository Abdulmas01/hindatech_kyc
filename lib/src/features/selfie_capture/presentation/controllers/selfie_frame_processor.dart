import '../../data/models/selfie_frame_models.dart';
import '../../domain/models/active_guidance.dart';
import '../../domain/services/active_guidance_service.dart';
import 'selfie_capture_runtime_controller.dart';

typedef SelfieFrameAnalysisTask = Future<SelfieFrameAnalysis?> Function();

class SelfieFrameProcessorConfig {
  const SelfieFrameProcessorConfig({
    required this.runtime,
    required this.guidance,
  });

  final SelfieCaptureRuntimeController runtime;
  final ActiveGuidanceService guidance;
}

class SelfieFrameProcessingResult {
  const SelfieFrameProcessingResult({
    required this.analysis,
    required this.guidance,
  });

  final SelfieFrameAnalysis analysis;
  final ActiveGuidanceState guidance;
}

class SelfieFrameProcessor {
  SelfieFrameProcessor({required SelfieFrameProcessorConfig config})
      : _runtime = config.runtime,
        _guidance = config.guidance;

  final SelfieCaptureRuntimeController _runtime;
  final ActiveGuidanceService _guidance;
  SelfieRuntimeActivity _activity = const SelfieRuntimeActivity(
    routeActive: true,
    appActive: true,
  );

  Future<SelfieFrameProcessingResult?> process(
    SelfieFrameAnalysisTask analyze,
  ) async {
    final ticket = _runtime.tryBeginFrame();
    if (ticket == null) return null;

    final stopwatch = Stopwatch()..start();
    try {
      final analysis = await analyze();
      stopwatch.stop();
      if (analysis == null) {
        _runtime.cancelFrame(ticket);
        return null;
      }
      final isCurrent = _runtime.finishFrame(
        ticket,
        inferenceDuration: stopwatch.elapsed,
      );
      if (!isCurrent) return null;

      final guidance = _guidance.evaluate(analysis.toActiveGuidanceFrame());
      return SelfieFrameProcessingResult(
        analysis: analysis,
        guidance: guidance,
      );
    } catch (_) {
      stopwatch.stop();
      _runtime.cancelFrame(ticket);
      rethrow;
    }
  }

  ActiveGuidanceState checkTimeout() => _guidance.checkTimeout();

  void updateActivity(SelfieRuntimeActivity activity) {
    final wasRunning = _activity.canRun;
    _activity = activity;
    _runtime.updateActivity(activity);
    if (wasRunning && !activity.canRun) {
      _guidance.pause();
    } else if (!wasRunning && activity.canRun) {
      _guidance.resume();
    }
  }

  ActiveGuidanceState restart() {
    _runtime.reset();
    final state = _guidance.restart();
    if (!_activity.canRun) _guidance.pause();
    return state;
  }

  void dispose() {
    _guidance.pause();
    _runtime.dispose();
  }
}
