enum DocumentCaptureResolution { low, medium, high, veryHigh }

enum DocumentFrameProfile { compact, standard, wide }

/// Controls whether local camera-quality observations affect capture guidance.
enum DocumentQualityGuidanceMode {
  disabled,

  /// Shows capture advice without making an identity-verification decision.
  advisory,
}

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
    this.qualityGuidanceMode = DocumentQualityGuidanceMode.advisory,
    this.frameProfile = DocumentFrameProfile.standard,
    double? guideWidthFactor,
    double? guideAspectRatio,
    double? guideMaxHeightFactor,
    double? qualityCropScale,
  })  : assert(minFrameStride > 0),
        assert(initialFrameStride >= minFrameStride),
        assert(initialFrameStride <= maxFrameStride),
        assert(strideAdjustmentWindow > 0),
        assert(guidanceStabilityFrames > 0),
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
        qualityGuidanceMode = DocumentQualityGuidanceMode.advisory,
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
        qualityGuidanceMode = DocumentQualityGuidanceMode.advisory,
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
        qualityGuidanceMode = DocumentQualityGuidanceMode.advisory,
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
  final DocumentQualityGuidanceMode qualityGuidanceMode;
  final DocumentFrameProfile frameProfile;
  final double guideWidthFactor;
  final double guideAspectRatio;
  final double guideMaxHeightFactor;
  final double qualityCropScale;

  DocumentCaptureConfig copyWith({
    DocumentCaptureResolution? resolution,
    int? initialFrameStride,
    int? minFrameStride,
    int? maxFrameStride,
    int? strideAdjustmentWindow,
    double? increaseStrideInferenceMs,
    double? decreaseStrideInferenceMs,
    Duration? autoCaptureHoldDuration,
    bool? autoCaptureEnabled,
    int? guidanceStabilityFrames,
    DocumentQualityGuidanceMode? qualityGuidanceMode,
    DocumentFrameProfile? frameProfile,
    double? guideWidthFactor,
    double? guideAspectRatio,
    double? guideMaxHeightFactor,
    double? qualityCropScale,
  }) {
    return DocumentCaptureConfig(
      resolution: resolution ?? this.resolution,
      initialFrameStride: initialFrameStride ?? this.initialFrameStride,
      minFrameStride: minFrameStride ?? this.minFrameStride,
      maxFrameStride: maxFrameStride ?? this.maxFrameStride,
      strideAdjustmentWindow:
          strideAdjustmentWindow ?? this.strideAdjustmentWindow,
      increaseStrideInferenceMs:
          increaseStrideInferenceMs ?? this.increaseStrideInferenceMs,
      decreaseStrideInferenceMs:
          decreaseStrideInferenceMs ?? this.decreaseStrideInferenceMs,
      autoCaptureHoldDuration:
          autoCaptureHoldDuration ?? this.autoCaptureHoldDuration,
      autoCaptureEnabled: autoCaptureEnabled ?? this.autoCaptureEnabled,
      guidanceStabilityFrames:
          guidanceStabilityFrames ?? this.guidanceStabilityFrames,
      qualityGuidanceMode: qualityGuidanceMode ?? this.qualityGuidanceMode,
      frameProfile: frameProfile ?? this.frameProfile,
      guideWidthFactor: guideWidthFactor ?? this.guideWidthFactor,
      guideAspectRatio: guideAspectRatio ?? this.guideAspectRatio,
      guideMaxHeightFactor: guideMaxHeightFactor ?? this.guideMaxHeightFactor,
      qualityCropScale: qualityCropScale ?? this.qualityCropScale,
    );
  }
}
