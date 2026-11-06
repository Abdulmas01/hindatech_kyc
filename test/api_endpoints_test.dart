import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/core/network/api_endpoints.dart';

void main() {
  final endpoints = ApiEndpoints(
    Uri.parse('https://api.example.com/api/v1/'),
  );

  test('builds centralized verification endpoints', () {
    expect(
      endpoints.sdkVerificationBootstrap,
      Uri.parse(
        'https://api.example.com/api/v1/sdk/verification-sessions/bootstrap',
      ),
    );
    expect(
      endpoints.sdkVerificationSession('verification-id'),
      Uri.parse(
        'https://api.example.com/api/v1/sdk/verification-sessions/verification-id',
      ),
    );
    expect(
      endpoints.sdkVerificationPayloads('verification-id'),
      Uri.parse(
        'https://api.example.com/api/v1/sdk/verification-sessions/verification-id/payloads',
      ),
    );
    expect(
      endpoints.sdkHostedAssets('verification-id'),
      Uri.parse(
        'https://api.example.com/api/v1/sdk/verification-sessions/verification-id/assets/hosted',
      ),
    );
    expect(
      endpoints.sdkHostedAssetSubmit('verification-id'),
      Uri.parse(
        'https://api.example.com/api/v1/sdk/verification-sessions/verification-id/assets/submit',
      ),
    );
    expect(
      endpoints.sdkExternalAssetSubmit('verification-id'),
      Uri.parse(
        'https://api.example.com/api/v1/sdk/verification-sessions/verification-id/assets/external-reference/submit',
      ),
    );
    expect(
      endpoints.sdkVerificationCancel('verification-id'),
      Uri.parse(
        'https://api.example.com/api/v1/sdk/verification-sessions/verification-id/cancel',
      ),
    );
    expect(
      endpoints.sdkVerificationConsent('verification-id'),
      Uri.parse(
        'https://api.example.com/api/v1/sdk/verification-sessions/verification-id/consent',
      ),
    );
  });

  test('encodes verification ids as path segments', () {
    expect(
      endpoints.sdkVerificationSession('id with spaces').toString(),
      'https://api.example.com/api/v1/sdk/verification-sessions/id%20with%20spaces',
    );
  });

  test('rejects an invalid API base URI', () {
    expect(
      () => ApiEndpoints(Uri.parse('/api/v1/')),
      throwsArgumentError,
    );
  });
}
