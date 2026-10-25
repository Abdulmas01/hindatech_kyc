enum DocumentCaptureResolution { low, medium, high, veryHigh }

enum DocumentFrameProfile { compact, standard, wide }

class DocumentCaptureConfig {
  const DocumentCaptureConfig({
    required this.resolution,
    required this.initialFrameStride,
    required this.minFrameStride,
    required this.maxFrameStride,
    required this.strideAdjustmentWindow,
    required this.increaseStrideInferenceMs,
    required this.decreaseStrideInferenceMs,
    required this.autoCaptureHoldDuration,
    required this.autoCaptureEnabled,
    required this.guidanceStabilityFrames,
    this.frameProfile = DocumentFrameProfile.standard,
    double? guideWidthFactor,
    double? guideAspectRatio,
    double? guideMaxHeightFactor,
    double? qualityCropScale,
  })  : assert(minFrameStride > 0),
        assert(initialFrameStride >= minFrameStride),
        assert(initialFrameStride <= maxFrameStride),
        assert(strideAdjustmentWindow > 0),
        guideWidthFactor = guideWidthFactor ??
            (frameProfile == DocumentFrameProfile.compact
                ? 0.78
                : frameProfile == DocumentFrameProfile.wide
                    ? 0.92
                    : 0.86),
        guideAspectRatio = guideAspectRatio ?? 0.63,
        guideMaxHeightFactor = guideMaxHeightFactor ?? 0.82,
        qualityCropScale = qualityCropScale ??
            (frameProfile == DocumentFrameProfile.compact
                ? 0.88
                : frameProfile == DocumentFrameProfile.wide
                    ? 0.78
                    : 0.82);

  const DocumentCaptureConfig.balanced()
      : resolution = DocumentCaptureResolution.medium,
        initialFrameStride = 5,
        minFrameStride = 3,
        maxFrameStride = 8,
        strideAdjustmentWindow = 10,
        increaseStrideInferenceMs = 80,
        decreaseStrideInferenceMs = 40,
        autoCaptureHoldDuration = const Duration(milliseconds: 1500),
        autoCaptureEnabled = true,
        guidanceStabilityFrames = 3,
        frameProfile = DocumentFrameProfile.standard,
        guideWidthFactor = 0.86,
        guideAspectRatio = 0.63,
        guideMaxHeightFactor = 0.82,
        qualityCropScale = 0.82;

  const DocumentCaptureConfig.fast()
      : resolution = DocumentCaptureResolution.low,
        initialFrameStride = 6,
        minFrameStride = 4,
        maxFrameStride = 9,
        strideAdjustmentWindow = 8,
        increaseStrideInferenceMs = 65,
        decreaseStrideInferenceMs = 30,
        autoCaptureHoldDuration = const Duration(milliseconds: 1200),
        autoCaptureEnabled = true,
        guidanceStabilityFrames = 2,
        frameProfile = DocumentFrameProfile.standard,
        guideWidthFactor = 0.86,
        guideAspectRatio = 0.63,
        guideMaxHeightFactor = 0.82,
        qualityCropScale = 0.82;

  const DocumentCaptureConfig.highQuality()
      : resolution = DocumentCaptureResolution.high,
        initialFrameStride = 4,
        minFrameStride = 2,
        maxFrameStride = 6,
        strideAdjustmentWindow = 12,
        increaseStrideInferenceMs = 95,
        decreaseStrideInferenceMs = 45,
        autoCaptureHoldDuration = const Duration(milliseconds: 1700),
        autoCaptureEnabled = true,
        guidanceStabilityFrames = 4,
        frameProfile = DocumentFrameProfile.standard,
        guideWidthFactor = 0.86,
        guideAspectRatio = 0.63,
        guideMaxHeightFactor = 0.82,
        qualityCropScale = 0.82;

  final DocumentCaptureResolution resolution;
  final int initialFrameStride;
  final int minFrameStride;
  final int maxFrameStride;
  final int strideAdjustmentWindow;
  final double increaseStrideInferenceMs;
  final double decreaseStrideInferenceMs;
  final Duration autoCaptureHoldDuration;
  final bool autoCaptureEnabled;
  final int guidanceStabilityFrames;
  final DocumentFrameProfile frameProfile;
  final double guideWidthFactor;
  final double guideAspectRatio;
  final double guideMaxHeightFactor;
  final double qualityCropScale;
}
