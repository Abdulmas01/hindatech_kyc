import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

import 'fixtures/sdk_bootstrap_payload.dart';

void main() {
  test('parses backend-owned active guidance constraints', () {
    final policy = VerificationLivenessPolicy.fromJson(
      sdkLivenessPolicyPayload(),
    );

    expect(
      policy.mode,
      VerificationLivenessCaptureMode.passiveWithActiveGuidance,
    );
    expect(
      policy.decisionAuthority,
      VerificationLivenessDecisionAuthority.backend,
    );
    expect(
      policy.activeGuidanceRole,
      VerificationLivenessActiveGuidanceRole.guidanceOnly,
    );
    expect(policy.challengeCount, 2);
    expect(policy.challengeTimeout, const Duration(seconds: 15));
    expect(policy.alignmentStabilityFrames, 5);
    expect(policy.requireSingleFace, isTrue);
    expect(policy.requireNeutralPose, isTrue);
    expect(policy.requireReturnToNeutral, isTrue);
    expect(policy.isGuidanceOnly, isTrue);
    expect(policy.isBackendAuthoritative, isTrue);
    expect(policy.canSubmitTemporalEvidence, isFalse);
  });

  test('creates only the backend-declared number of guidance challenges', () {
    final policy = VerificationLivenessPolicy.fromJson(
      sdkLivenessPolicyPayload(),
    );

    final sequence = policy.createGuidanceSequence();

    expect(sequence, hasLength(2));
    expect(
      sequence.toSet().difference(policy.allowedChallenges.toSet()),
      isEmpty,
    );
  });

  test('preserves future values but does not try to render them', () {
    final policy = VerificationLivenessPolicy.fromJson({
      ...sdkLivenessPolicyPayload(),
      'challengeCount': 1,
      'allowedChallenges': ['future_challenge'],
    });

    expect(policy.allowedChallengeValues, ['future_challenge']);
    expect(policy.allowedChallenges, [VerificationLivenessChallenge.unknown]);
    expect(policy.createGuidanceSequence, throwsUnsupportedError);
  });

  test('rejects invalid challenge and timing constraints', () {
    expect(
      () => VerificationLivenessPolicy.fromJson({
        ...sdkLivenessPolicyPayload(),
        'challengeCount': 4,
      }),
      throwsFormatException,
    );
    expect(
      () => VerificationLivenessPolicy.fromJson({
        ...sdkLivenessPolicyPayload(),
        'challengeTimeoutMs': 0,
      }),
      throwsFormatException,
    );
    expect(
      () => VerificationLivenessPolicy.fromJson({
        ...sdkLivenessPolicyPayload(),
        'requireSingleFace': 'yes',
      }),
      throwsFormatException,
    );
  });

  test('reads the required nullable contract field', () {
    expect(
      VerificationLivenessPolicy.readNullable({'livenessPolicy': null}),
      isNull,
    );
    expect(
      () => VerificationLivenessPolicy.readNullable(const {}),
      throwsFormatException,
    );
  });
}
