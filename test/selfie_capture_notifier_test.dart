import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/domain/models/active_guidance.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/presentation/controllers/selfie_capture_notifier.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/presentation/models/selfie_capture_state.dart';

void main() {
  late ProviderContainer container;
  late ProviderSubscription<SelfieCaptureState> subscription;

  setUp(() {
    container = ProviderContainer();
    subscription = container.listen(selfieCaptureProvider, (_, __) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  test('exposes startup progress and a slow-startup hint', () {
    final notifier = container.read(selfieCaptureProvider.notifier);

    notifier.setStartupStage(SelfieCameraStartupStage.initializingController);
    notifier.markSlowStartup();
    final state = container.read(selfieCaptureProvider);

    expect(state.phase, SelfieCapturePhase.initializing);
    expect(
      state.startupStage,
      SelfieCameraStartupStage.initializingController,
    );
    expect(state.isSlowStartup, isTrue);
    expect(state.showsCameraLoading, isTrue);
  });

  test('maps capture guidance without treating it as a verdict', () {
    final notifier = container.read(selfieCaptureProvider.notifier);
    const guidance = ActiveGuidanceState(
      phase: ActiveGuidancePhase.captureSuggested,
      signal: ActiveGuidanceSignal.captureSuggested,
      activeChallenge: null,
      completedChallengeCount: 2,
      totalChallengeCount: 2,
      challengeDeadline: null,
      alignmentSignal: null,
    );

    notifier.updateGuidance(guidance);
    final state = container.read(selfieCaptureProvider);

    expect(state.phase, SelfieCapturePhase.captureSuggested);
    expect(state.guidance?.suggestsCapture, isTrue);
  });

  test('moves to paused without discarding guidance progress', () {
    final notifier = container.read(selfieCaptureProvider.notifier);
    const guidance = ActiveGuidanceState(
      phase: ActiveGuidancePhase.performingChallenge,
      signal: ActiveGuidanceSignal.blink,
      activeChallenge: null,
      completedChallengeCount: 0,
      totalChallengeCount: 2,
      challengeDeadline: null,
      alignmentSignal: null,
    );
    notifier.updateGuidance(guidance);

    notifier.setPaused();
    final state = container.read(selfieCaptureProvider);

    expect(state.phase, SelfieCapturePhase.paused);
    expect(state.guidance, same(guidance));
  });
}
