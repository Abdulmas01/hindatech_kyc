import 'document_capture_config.dart';

class DocumentCaptureRuntimeController {
  DocumentCaptureRuntimeController({required int initialFrameStride})
      : _frameStride = initialFrameStride;

  bool _isProcessingFrame = false;
  int _frameCounter = 0;
  int _frameStride;
  int _strideAdjustCounter = 0;
  double _averageInferenceMs = 0;
  int _inferenceSamples = 0;

  int get frameStride => _frameStride;
  double get averageInferenceMs => _averageInferenceMs;

  bool shouldProcessNextFrame() {
    _frameCounter++;
    if (_isProcessingFrame || _frameCounter % _frameStride != 0) {
      return false;
    }
    _isProcessingFrame = true;
    return true;
  }

  void finishFrameProcessing() {
    _isProcessingFrame = false;
  }

  void reset({required int initialFrameStride}) {
    _isProcessingFrame = false;
    _frameCounter = 0;
    _frameStride = initialFrameStride;
    _strideAdjustCounter = 0;
    _averageInferenceMs = 0;
    _inferenceSamples = 0;
  }

  void recordInference({
    required double milliseconds,
    required DocumentCaptureConfig config,
  }) {
    _inferenceSamples++;
    _averageInferenceMs =
        ((_averageInferenceMs * (_inferenceSamples - 1)) + milliseconds) /
            _inferenceSamples;

    _strideAdjustCounter++;
    if (_strideAdjustCounter < config.strideAdjustmentWindow) {
      return;
    }

    if (_averageInferenceMs > config.increaseStrideInferenceMs &&
        _frameStride < config.maxFrameStride) {
      _frameStride++;
    } else if (_averageInferenceMs < config.decreaseStrideInferenceMs &&
        _frameStride > config.minFrameStride) {
      _frameStride--;
    }
    _strideAdjustCounter = 0;
  }
}
