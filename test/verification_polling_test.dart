import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

import 'fixtures/sdk_bootstrap_payload.dart';

void main() {
  test('validates host polling overrides', () {
    expect(
      () =>
          const VerificationPollingOptions(interval: Duration.zero).validate(),
      throwsArgumentError,
    );
    expect(
      () => const VerificationPollingOptions(timeout: Duration.zero).validate(),
      throwsArgumentError,
    );
  });

  test('recognizes terminal session states', () {
    for (final status in const [
      'completed',
      'failed',
      'manual_review',
      'expired',
      'cancelled',
    ]) {
      expect(_state(status).isTerminal, isTrue, reason: status);
    }
    for (final status in const [
      'started',
      'uploaded',
      'processing',
      'future'
    ]) {
      expect(_state(status).isTerminal, isFalse, reason: status);
    }
  });
}

VerificationSessionState _state(String status) {
  final payload = sdkBootstrapPayload()
    ..remove('sdkToken')
    ..remove('sdkTokenExpiresAt')
    ..remove('allowedActions')
    ..remove('sessionExpiresAt')
    ..remove('supportedAssetIngestionModes')
    ..['status'] = status
    ..['hostedAssets'] = <Object?>[];
  return VerificationSessionState.fromJson(payload);
}
