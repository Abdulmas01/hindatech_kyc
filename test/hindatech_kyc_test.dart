import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  group('HindatechSdkSession', () {
    test('parses a server-defined document workflow', () {
      final session = HindatechSdkSession.fromJson({
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
        HindatechAssetType.documentFront,
      );
      expect(
        session.captureManifest.requiredAssets.single.captureMethod,
        HindatechCaptureMethod.document,
      );
    });

    test('preserves unknown asset values for forward compatibility', () {
      final manifest = HindatechCaptureManifest.fromJson({
        'required_assets': [
          {
            'type': 'future_identity_signal',
            'capture': 'future_capture_method',
          },
        ],
      });

      final requirement = manifest.requiredAssets.single;
      expect(requirement.assetType, HindatechAssetType.unknown);
      expect(requirement.captureMethod, HindatechCaptureMethod.unknown);
      expect(requirement.assetTypeValue, 'future_identity_signal');
      expect(requirement.captureMethodValue, 'future_capture_method');
    });

    test('rejects a bootstrap response without a scoped SDK token', () {
      expect(
        () => HindatechSdkSession.fromJson({
          'id': 'verification-id',
          'capture_manifest': {'required_assets': <Object?>[]},
        }),
        throwsFormatException,
      );
    });
  });

  test('HindatechKycConfig provides conservative defaults', () {
    final config = HindatechKycConfig(
      apiBaseUri: Uri.parse('https://api.hindatech.com'),
    );

    expect(config.requestTimeout, const Duration(seconds: 30));
    expect(config.pollingInterval, const Duration(seconds: 2));
    expect(config.maxPollingAttempts, 30);
    expect(config.enableLocalQualityGuidance, isTrue);
  });
}
