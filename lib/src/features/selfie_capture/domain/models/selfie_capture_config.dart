enum SelfieCaptureResolution { medium, high, veryHigh }

enum SelfieRouteInactivityHandling {
  /// Stops analysis while retaining the initialized controller for fast return.
  pauseStream,

  /// Releases the camera when another route covers the capture view.
  disposeController,
}

class SelfieCaptureConfig {
  const SelfieCaptureConfig({
    required this.resolution,
    required this.initialFrameStride,
    required this.minFrameStride,
    required this.maxFrameStride,
    required this.strideAdjustmentWindow,
    required this.increaseStrideInferenceMs,
    required this.decreaseStrideInferenceMs,
    required this.cameraStartupTimeout,
    required this.slowStartupThreshold,
    required this.routeInactivityHandling,
  })  : assert(minFrameStride > 0),
        assert(initialFrameStride >= minFrameStride),
        assert(initialFrameStride <= maxFrameStride),
        assert(strideAdjustmentWindow > 0),
        assert(increaseStrideInferenceMs > decreaseStrideInferenceMs),
        assert(decreaseStrideInferenceMs > 0),
        assert(cameraStartupTimeout > Duration.zero),
        assert(slowStartupThreshold > Duration.zero);

  const SelfieCaptureConfig.balanced()
      : resolution = SelfieCaptureResolution.high,
        initialFrameStride = 3,
        minFrameStride = 2,
        maxFrameStride = 6,
        strideAdjustmentWindow = 8,
        increaseStrideInferenceMs = 95,
        decreaseStrideInferenceMs = 45,
        cameraStartupTimeout = const Duration(seconds: 20),
        slowStartupThreshold = const Duration(milliseconds: 1200),
        routeInactivityHandling = SelfieRouteInactivityHandling.pauseStream;

  const SelfieCaptureConfig.fast()
      : resolution = SelfieCaptureResolution.medium,
        initialFrameStride = 4,
        minFrameStride = 3,
        maxFrameStride = 8,
        strideAdjustmentWindow = 6,
        increaseStrideInferenceMs = 75,
        decreaseStrideInferenceMs = 35,
        cameraStartupTimeout = const Duration(seconds: 15),
        slowStartupThreshold = const Duration(milliseconds: 900),
        routeInactivityHandling = SelfieRouteInactivityHandling.pauseStream;

  const SelfieCaptureConfig.highQuality()
      : resolution = SelfieCaptureResolution.veryHigh,
        initialFrameStride = 2,
        minFrameStride = 1,
        maxFrameStride = 5,
        strideAdjustmentWindow = 10,
        increaseStrideInferenceMs = 120,
        decreaseStrideInferenceMs = 55,
        cameraStartupTimeout = const Duration(seconds: 25),
        slowStartupThreshold = const Duration(milliseconds: 1500),
        routeInactivityHandling = SelfieRouteInactivityHandling.pauseStream;

  final SelfieCaptureResolution resolution;
  final int initialFrameStride;
  final int minFrameStride;
  final int maxFrameStride;
  final int strideAdjustmentWindow;
  final double increaseStrideInferenceMs;
  final double decreaseStrideInferenceMs;
  final Duration cameraStartupTimeout;
  final Duration slowStartupThreshold;
  final SelfieRouteInactivityHandling routeInactivityHandling;
}
