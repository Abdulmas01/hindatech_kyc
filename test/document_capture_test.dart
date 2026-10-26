import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';
import 'package:hindatech_kyc/src/features/document_capture/presentation/controllers/document_capture_runtime_controller.dart';

void main() {
  test('balanced document capture configuration is stable', () {
    const config = DocumentCaptureConfig.balanced();

    expect(config.resolution, DocumentCaptureResolution.medium);
    expect(config.initialFrameStride, 5);
    expect(config.autoCaptureEnabled, isTrue);
    expect(
      config.qualityGuidanceMode,
      DocumentQualityGuidanceMode.advisory,
    );
    expect(config.guideWidthFactor, 0.86);
  });

  test('document result reports guide fallback', () {
    const result = DocumentCaptureResult(
      originalPath: 'original.jpg',
      normalizedPath: 'normalized.jpg',
      captureSource: DocumentCaptureSource.guideFallback,
    );

    expect(result.usedGuideCropFallback, isTrue);
  });

  test('host app can disable advisory guidance and auto-capture', () {
    final config = const DocumentCaptureConfig.balanced().copyWith(
      qualityGuidanceMode: DocumentQualityGuidanceMode.disabled,
      autoCaptureEnabled: false,
    );

    expect(config.qualityGuidanceMode, DocumentQualityGuidanceMode.disabled);
    expect(config.autoCaptureEnabled, isFalse);
  });

  test('runtime controller throttles frame processing', () {
    final controller = DocumentCaptureRuntimeController(initialFrameStride: 2);

    expect(controller.shouldProcessNextFrame(), isFalse);
    expect(controller.shouldProcessNextFrame(), isTrue);
    expect(controller.shouldProcessNextFrame(), isFalse);

    controller.finishFrameProcessing();

    expect(controller.shouldProcessNextFrame(), isTrue);
  });

  test('runtime controller adapts to slow inference', () {
    const config = DocumentCaptureConfig(
      resolution: DocumentCaptureResolution.medium,
      initialFrameStride: 2,
      minFrameStride: 1,
      maxFrameStride: 3,
      strideAdjustmentWindow: 2,
      increaseStrideInferenceMs: 80,
      decreaseStrideInferenceMs: 40,
      autoCaptureHoldDuration: Duration(seconds: 1),
      autoCaptureEnabled: true,
      guidanceStabilityFrames: 2,
    );
    final controller = DocumentCaptureRuntimeController(initialFrameStride: 2);

    controller.recordInference(milliseconds: 100, config: config);
    controller.recordInference(milliseconds: 100, config: config);

    expect(controller.frameStride, 3);
    expect(controller.averageInferenceMs, 100);
  });
}
