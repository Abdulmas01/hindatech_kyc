import '../../domain/models/selfie_capture_config.dart';

enum SelfieRuntimeOperation { frameAnalysis, capture }

class SelfieRuntimeTicket {
  const SelfieRuntimeTicket._({
    required this.generation,
    required this.id,
    required this.operation,
  });

  final int generation;
  final int id;
  final SelfieRuntimeOperation operation;
}

class SelfieRuntimeActivity {
  const SelfieRuntimeActivity({
    required this.routeActive,
    required this.appActive,
  });

  final bool routeActive;
  final bool appActive;

  bool get canRun => routeActive && appActive;
}

class SelfieCaptureRuntimeController {
  SelfieCaptureRuntimeController({
    this.config = const SelfieCaptureConfig.balanced(),
  }) : _frameStride = config.initialFrameStride;

  final SelfieCaptureConfig config;

  SelfieRuntimeActivity _activity = const SelfieRuntimeActivity(
    routeActive: true,
    appActive: true,
  );
  int _generation = 0;
  int _nextTicketId = 0;
  int _frameCounter = 0;
  int _frameStride;
  int _windowSamples = 0;
  double _windowInferenceMs = 0;
  int _totalInferenceSamples = 0;
  double _averageInferenceMs = 0;
  SelfieRuntimeTicket? _activeFrame;
  SelfieRuntimeTicket? _activeCapture;
  bool _isDisposed = false;

  bool get canRun => _activity.canRun && !_isDisposed;
  bool get isProcessingFrame => _activeFrame != null;
  bool get isCapturing => _activeCapture != null;
  int get frameStride => _frameStride;
  double get averageInferenceMs => _averageInferenceMs;
  int get generation => _generation;

  void updateActivity(SelfieRuntimeActivity activity) {
    if (_isDisposed) return;
    final wasRunning = _activity.canRun;
    _activity = activity;
    if (wasRunning && !activity.canRun) _invalidateInFlightWork();
  }

  SelfieRuntimeTicket? tryBeginFrame() {
    if (!canRun || isCapturing) return null;
    _frameCounter++;
    if (isProcessingFrame || _frameCounter % _frameStride != 0) return null;

    final ticket = _newTicket(SelfieRuntimeOperation.frameAnalysis);
    _activeFrame = ticket;
    return ticket;
  }

  bool finishFrame(
    SelfieRuntimeTicket ticket, {
    required Duration inferenceDuration,
  }) {
    if (!_matches(ticket, _activeFrame)) return false;
    _activeFrame = null;
    _recordInference(inferenceDuration);
    return canRun;
  }

  bool cancelFrame(SelfieRuntimeTicket ticket) {
    if (!_matches(ticket, _activeFrame)) return false;
    _activeFrame = null;
    return true;
  }

  SelfieRuntimeTicket? tryBeginCapture() {
    if (!canRun || isCapturing) return null;
    _generation++;
    _activeFrame = null;
    final ticket = _newTicket(SelfieRuntimeOperation.capture);
    _activeCapture = ticket;
    return ticket;
  }

  bool finishCapture(SelfieRuntimeTicket ticket) {
    if (!_matches(ticket, _activeCapture)) return false;
    _activeCapture = null;
    return canRun;
  }

  void reset() {
    if (_isDisposed) return;
    _invalidateInFlightWork();
    _frameCounter = 0;
    _frameStride = config.initialFrameStride;
    _windowSamples = 0;
    _windowInferenceMs = 0;
    _totalInferenceSamples = 0;
    _averageInferenceMs = 0;
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _activity = const SelfieRuntimeActivity(
      routeActive: false,
      appActive: false,
    );
    _invalidateInFlightWork();
  }

  SelfieRuntimeTicket _newTicket(SelfieRuntimeOperation operation) {
    return SelfieRuntimeTicket._(
      generation: _generation,
      id: ++_nextTicketId,
      operation: operation,
    );
  }

  bool _matches(SelfieRuntimeTicket ticket, SelfieRuntimeTicket? active) {
    return active != null &&
        ticket.generation == _generation &&
        ticket.id == active.id &&
        ticket.operation == active.operation;
  }

  void _invalidateInFlightWork() {
    _generation++;
    _activeFrame = null;
    _activeCapture = null;
    _frameCounter = 0;
  }

  void _recordInference(Duration duration) {
    final milliseconds = duration.inMicroseconds / 1000;
    _totalInferenceSamples++;
    _averageInferenceMs =
        ((_averageInferenceMs * (_totalInferenceSamples - 1)) + milliseconds) /
            _totalInferenceSamples;

    _windowSamples++;
    _windowInferenceMs += milliseconds;
    if (_windowSamples < config.strideAdjustmentWindow) return;

    final windowAverage = _windowInferenceMs / _windowSamples;
    if (windowAverage > config.increaseStrideInferenceMs &&
        _frameStride < config.maxFrameStride) {
      _frameStride++;
    } else if (windowAverage < config.decreaseStrideInferenceMs &&
        _frameStride > config.minFrameStride) {
      _frameStride--;
    }
    _windowSamples = 0;
    _windowInferenceMs = 0;
  }
}
