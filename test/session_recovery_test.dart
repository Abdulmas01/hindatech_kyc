import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

import 'fixtures/sdk_bootstrap_payload.dart';

void main() {
  test('parses every recovered asset without silently selecting a duplicate',
      () {
    final payload = sdkBootstrapPayload()
      ..remove('sdkToken')
      ..remove('sdkTokenExpiresAt')
      ..remove('allowedActions')
      ..remove('sessionExpiresAt')
      ..remove('supportedAssetIngestionModes')
      ..['hostedAssets'] = [
        _hostedAsset('asset-older', '2026-08-02T16:01:00.000Z'),
        _hostedAsset('asset-newer', '2026-08-02T16:03:00.000Z'),
      ];

    final state = VerificationSessionState.fromJson(payload);
    final candidates = state.hostedAssetsFor('document_front').toList();

    expect(state.status, VerificationSessionStatus.started);
    expect(candidates.map((asset) => asset.assetKey), [
      'asset-older',
      'asset-newer',
    ]);
  });

  test('rejects a recovered asset from another session', () {
    final payload = sdkBootstrapPayload()
      ..remove('sdkToken')
      ..remove('sdkTokenExpiresAt')
      ..remove('allowedActions')
      ..remove('sessionExpiresAt')
      ..remove('supportedAssetIngestionModes')
      ..['hostedAssets'] = [
        {
          ..._hostedAsset('asset-key', '2026-08-02T16:03:00.000Z'),
          'verificationSessionId': 'another-session',
        },
      ];

    expect(
      () => VerificationSessionState.fromJson(payload),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _hostedAsset(String assetKey, String uploadedAt) => {
      'assetKey': assetKey,
      'verificationSessionId': 'verification-id',
      'inputType': 'document_front',
      'contentType': 'image/jpeg',
      'sizeBytes': 245678,
      'uploadedAt': uploadedAt,
      'expiresAt': '2099-08-03T16:03:00.000Z',
    };
