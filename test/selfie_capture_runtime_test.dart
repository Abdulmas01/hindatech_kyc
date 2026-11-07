import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/presentation/controllers/selfie_capture_runtime_controller.dart';

void main() {
  final config = SelfieCaptureConfig(
    resolution: SelfieCaptureResolution.medium,
    initialFrameStride: 2,
    minFrameStride: 1,
    maxFrameStride: 4,
    strideAdjustmentWindow: 2,
    increaseStrideInferenceMs: 80,
    decreaseStrideInferenceMs: 30,
    cameraStartupTimeout: Duration(seconds: 10),
    slowStartupThreshold: Duration(seconds: 1),
    routeInactivityHandling: SelfieRouteInactivityHandling.pauseStream,
  );

  test('prevents overlapping inference and adapts to slow frames', () {
    final runtime = SelfieCaptureRuntimeController(config: config);

    expect(runtime.tryBeginFrame(), isNull);
    final first = runtime.tryBeginFrame();
    expect(first, isNotNull);
    expect(runtime.tryBeginFrame(), isNull);
    expect(
      runtime.finishFrame(
        first!,
        inferenceDuration: const Duration(milliseconds: 100),
      ),
      isTrue,
    );

    final second = runtime.tryBeginFrame();
    expect(second, isNotNull);
    runtime.finishFrame(
      second!,
      inferenceDuration: const Duration(milliseconds: 100),
    );

    expect(runtime.frameStride, 3);
    expect(runtime.averageInferenceMs, 100);
  });

  test('invalidates late frame results when the route is covered', () {
    final runtime = SelfieCaptureRuntimeController(
      config: SelfieCaptureConfig(
        resolution: SelfieCaptureResolution.medium,
        initialFrameStride: 1,
        minFrameStride: 1,
        maxFrameStride: 2,
        strideAdjustmentWindow: 2,
        increaseStrideInferenceMs: 80,
        decreaseStrideInferenceMs: 30,
        cameraStartupTimeout: Duration(seconds: 10),
        slowStartupThreshold: Duration(seconds: 1),
        routeInactivityHandling: SelfieRouteInactivityHandling.pauseStream,
      ),
    );
    final ticket = runtime.tryBeginFrame()!;

    runtime.updateActivity(
      const SelfieRuntimeActivity(routeActive: false, appActive: true),
    );

    expect(
      runtime.finishFrame(
        ticket,
        inferenceDuration: const Duration(milliseconds: 20),
      ),
      isFalse,
    );
    expect(runtime.isProcessingFrame, isFalse);
    expect(runtime.canRun, isFalse);
  });

  test('does not restart under a covered route when the app resumes', () {
    final runtime = SelfieCaptureRuntimeController(config: config);
    runtime.updateActivity(
      const SelfieRuntimeActivity(routeActive: false, appActive: false),
    );
    runtime.updateActivity(
      const SelfieRuntimeActivity(routeActive: false, appActive: true),
    );

    expect(runtime.canRun, isFalse);
    expect(runtime.tryBeginFrame(), isNull);
  });

  test('capture invalidates active analysis and uses its own ticket', () {
    final runtime = SelfieCaptureRuntimeController(
      config: const SelfieCaptureConfig.fast(),
    );
    SelfieRuntimeTicket? frame;
    for (var i = 0; i < 4; i++) {
      frame ??= runtime.tryBeginFrame();
    }
    expect(frame, isNotNull);
    expect(runtime.isProcessingFrame, isTrue);

    final capture = runtime.tryBeginCapture();
    expect(capture, isNotNull);
    expect(runtime.isProcessingFrame, isFalse);
    expect(runtime.tryBeginFrame(), isNull);
    expect(runtime.finishCapture(capture!), isTrue);
  });
}
