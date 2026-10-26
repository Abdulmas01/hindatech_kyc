import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  group('VerificationSession', () {
    test('parses a server-defined document workflow', () {
      final session = VerificationSession.fromJson({
        'id': 'verification-id',
        'sdk_token': 'short-lived-token',
        'workflow_key': 'document_extract',
        'expires_at': '2026-10-25T20:00:00Z',
        'capture_manifest': {
          'version': 1,
          'required_assets': [
            {
              'type': 'document_front',
              'capture': 'document',
            },
          ],
        },
      });

      expect(session.verificationId, 'verification-id');
      expect(session.workflowKey, 'document_extract');
      expect(session.captureManifest.workflowKey, 'document_extract');
      expect(session.captureManifest.requiredAssets, hasLength(1));
      expect(
        session.captureManifest.requiredAssets.single.assetType,
        CaptureAssetType.documentFront,
      );
      expect(
        session.captureManifest.requiredAssets.single.captureMethod,
        CaptureMethod.document,
      );
    });

    test('preserves unknown asset values for forward compatibility', () {
      final manifest = CaptureManifest.fromJson({
        'required_assets': [
          {
            'type': 'future_identity_signal',
            'capture': 'future_capture_method',
          },
        ],
      });

      final requirement = manifest.requiredAssets.single;
      expect(requirement.assetType, CaptureAssetType.unknown);
      expect(requirement.captureMethod, CaptureMethod.unknown);
      expect(requirement.assetTypeValue, 'future_identity_signal');
      expect(requirement.captureMethodValue, 'future_capture_method');
    });

    test('rejects a bootstrap response without a scoped SDK token', () {
      expect(
        () => VerificationSession.fromJson({
          'id': 'verification-id',
          'capture_manifest': {'required_assets': <Object?>[]},
        }),
        throwsFormatException,
      );
    });
  });

  test('KycConfig provides conservative defaults', () {
    final config = KycConfig(
      apiBaseUri: Uri.parse('https://api.hindatech.com'),
    );

    expect(config.requestTimeout, const Duration(seconds: 30));
    expect(config.pollingInterval, const Duration(seconds: 2));
    expect(config.maxPollingAttempts, 30);
    expect(config.enableLocalQualityGuidance, isTrue);
  });
}
