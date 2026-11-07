import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

import 'fixtures/sdk_bootstrap_payload.dart';

void main() {
  group('VerificationSession', () {
    test('parses a server-defined document workflow', () {
      final session = VerificationSession.fromJson(sdkBootstrapPayload());

      expect(session.verificationSessionId, 'verification-id');
      expect(session.workflowKey, 'document_extract');
      expect(session.status, VerificationSessionStatus.started);
      expect(session.assetIngestionMode, AssetIngestionMode.smartKycHosted);
      expect(session.requiredInputs.assetRequirements, hasLength(2));
      expect(
        session.requiredInputs.assetRequirements.first.assetType,
        CaptureAssetType.documentFront,
      );
      expect(session.allows(VerificationSessionAction.uploadAsset), isTrue);
      expect(session.uploadPolicy.maxFileSizeBytes, 10485760);
      expect(session.polling.recommendedInterval, const Duration(seconds: 3));
    });

    test('preserves unknown input values for forward compatibility', () {
      final payload = sdkBootstrapPayload(
        requiredAssetTypes: const ['future_identity_signal'],
        optionalAssetTypes: const [],
      );
      final requiredInputs =
          VerificationSession.fromJson(payload).requiredInputs;

      final requirement = requiredInputs.assetRequirements.single;
      expect(requirement.assetType, CaptureAssetType.unknown);
      expect(requirement.assetTypeValue, 'future_identity_signal');
      expect(requiredInputs.allowsAssetType('future_identity_signal'), isTrue);
    });

    test('rejects a bootstrap response without a scoped SDK token', () {
      expect(
        () => VerificationSession.fromJson({
          ...sdkBootstrapPayload(),
          'sdkToken': '',
        }),
        throwsFormatException,
      );
    });
  });

  test('KycConfig provides conservative defaults', () {
    final config = KycConfig(
      apiBaseUri: Uri.parse('https://api.example.com/api/v1/'),
    );

    expect(config.requestTimeout, const Duration(seconds: 30));
    expect(config.pollingInterval, const Duration(seconds: 2));
    expect(config.maxPollingAttempts, 30);
  });

  test('KycConfig production preset uses the hosted Hindatech API', () {
    final config = KycConfig.production();

    expect(
      config.apiBaseUri,
      Uri.parse('https://api.kyc.hindatech.com/api/v1/'),
    );
    expect(config.requestTimeout, const Duration(seconds: 30));
    expect(config.pollingInterval, const Duration(seconds: 2));
    expect(config.maxPollingAttempts, 30);
  });

  test('KycConfig rejects non-positive timing values', () {
    expect(
      () => KycConfig(
        apiBaseUri: Uri.parse('https://api.example.com/api/v1/'),
        requestTimeout: Duration.zero,
      ),
      throwsAssertionError,
    );
    expect(
      () => KycConfig(
        apiBaseUri: Uri.parse('https://api.example.com/api/v1/'),
        pollingInterval: Duration.zero,
      ),
      throwsAssertionError,
    );
  });
}
