import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

import 'fixtures/sdk_bootstrap_payload.dart';

void main() {
  test('parses backend-owned document quality guidance constraints', () {
    final policy = VerificationDocumentQualityPolicy.fromJson(
      sdkDocumentQualityPolicyPayload(),
    );

    expect(policy.mode, VerificationDocumentQualityMode.guidanceOnly);
    expect(
      policy.decisionAuthority,
      VerificationDocumentQualityDecisionAuthority.backend,
    );
    expect(policy.supportedSignals, [
      VerificationDocumentQualitySignal.good,
      VerificationDocumentQualitySignal.blurry,
      VerificationDocumentQualitySignal.glare,
      VerificationDocumentQualitySignal.dark,
      VerificationDocumentQualitySignal.noDocument,
    ]);
    expect(policy.permitsLocalGuidance, isTrue);
    expect(
      policy.acceptsSignal(signalValue: 'good', confidence: 0.7),
      isTrue,
    );
    expect(
      policy.acceptsSignal(signalValue: 'good', confidence: 0.69),
      isFalse,
    );
    expect(
      policy.acceptsSignal(signalValue: 'future_signal', confidence: 1),
      isFalse,
    );
  });

  test('requires every supported signal to have a confidence threshold', () {
    final payload = sdkDocumentQualityPolicyPayload();
    payload['minimumConfidenceBySignal'] = {'good': 0.7};

    expect(
      () => VerificationDocumentQualityPolicy.fromJson(payload),
      throwsFormatException,
    );
  });

  test('rejects confidence thresholds outside zero and one', () {
    final payload = sdkDocumentQualityPolicyPayload();
    payload['minimumConfidenceBySignal'] = {
      ...(payload['minimumConfidenceBySignal']! as Map<String, Object?>),
      'good': 1.1,
    };

    expect(
      () => VerificationDocumentQualityPolicy.fromJson(payload),
      throwsFormatException,
    );
  });

  test('requires the nullable policy field in session contracts', () {
    expect(
      () => VerificationDocumentQualityPolicy.readNullable(<String, Object?>{}),
      throwsFormatException,
    );
    expect(
      VerificationDocumentQualityPolicy.readNullable(
        <String, Object?>{'documentQualityPolicy': null},
      ),
      isNull,
    );
  });
}
