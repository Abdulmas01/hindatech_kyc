import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/core/network/api_endpoints.dart';

void main() {
  final endpoints = ApiEndpoints(
    Uri.parse('https://api.example.com/api/v1/'),
  );

  test('builds centralized verification endpoints', () {
    expect(
      endpoints.verifications,
      Uri.parse('https://api.example.com/api/v1/verifications'),
    );
    expect(
      endpoints.verification('verification-id'),
      Uri.parse('https://api.example.com/api/v1/verifications/verification-id'),
    );
    expect(
      endpoints.verificationAssets('verification-id'),
      Uri.parse(
        'https://api.example.com/api/v1/verifications/verification-id/assets',
      ),
    );
    expect(
      endpoints.verificationSubmit('verification-id'),
      Uri.parse(
        'https://api.example.com/api/v1/verifications/verification-id/submit',
      ),
    );
  });

  test('encodes verification ids as path segments', () {
    expect(
      endpoints.verification('id with spaces').toString(),
      'https://api.example.com/api/v1/verifications/id%20with%20spaces',
    );
  });

  test('rejects an invalid API base URI', () {
    expect(
      () => ApiEndpoints(Uri.parse('/api/v1/')),
      throwsArgumentError,
    );
  });
}
