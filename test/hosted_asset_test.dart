import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  test('models hosted upload inputs as one request', () {
    const request = HostedAssetUploadRequest(
      inputType: 'document_front',
      filePath: 'capture.jpg',
      contentType: 'image/jpeg',
    );

    expect(request.inputType, 'document_front');
    expect(request.filePath, 'capture.jpg');
    expect(request.contentType, 'image/jpeg');
  });

  test('parses the NestJS hosted asset receipt', () {
    final asset = HostedAsset.fromJson({
      'assetKey': 'verifications/sandbox/tenant/session/front/file.jpg',
      'verificationSessionId': 'session-id',
      'inputType': 'document_front',
      'contentType': 'image/jpeg',
      'sizeBytes': 245678,
      'uploadedAt': '2026-08-02T16:03:00.000Z',
      'expiresAt': '2099-08-03T16:03:00.000Z',
    });

    expect(asset.inputType, CaptureAssetType.documentFront);
    expect(asset.sizeBytes, 245678);
    expect(asset.isExpired, isFalse);
  });

  test('preserves an unknown workflow input type', () {
    final asset = HostedAsset.fromJson({
      'assetKey': 'asset-key',
      'verificationSessionId': 'session-id',
      'inputType': 'future_asset',
      'contentType': 'image/jpeg',
      'sizeBytes': 1,
      'uploadedAt': '2026-08-02T16:03:00.000Z',
      'expiresAt': '2099-08-03T16:03:00.000Z',
    });

    expect(asset.inputTypeValue, 'future_asset');
    expect(asset.inputType, CaptureAssetType.unknown);
  });
}
