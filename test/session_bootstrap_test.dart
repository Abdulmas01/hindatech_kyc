import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

import 'fixtures/sdk_bootstrap_payload.dart';

void main() {
  final config = KycConfig(apiBaseUri: Uri.parse('https://api.example.com'));

  group('KycClient bootstrap', () {
    test('creates a client from a customer-provided session response',
        () async {
      final client = await KycClient.bootstrap(
        config: config,
        sessionProvider: () async => sdkBootstrapPayload(),
      );

      expect(client.config, same(config));
      expect(client.session.verificationSessionId, 'verification-id');
      expect(client.session.sdkToken, 'short-lived-token');
      expect(client.session.requiredInputs.requiredAssetTypes, [
        'document_front',
      ]);
      expect(client.session.livenessPolicy, isNull);
    });

    test('reads liveness policy from the session response', () async {
      final client = await KycClient.bootstrap(
        config: config,
        sessionProvider: () async => {
          ...sdkBootstrapPayload(),
          'livenessPolicy': sdkLivenessPolicyPayload(),
        },
      );

      final policy = client.session.livenessPolicy!;
      expect(policy.challengeCount, 2);
      expect(policy.challengeTimeout, const Duration(seconds: 15));
      expect(policy.isBackendAuthoritative, isTrue);
      expect(policy.isGuidanceOnly, isTrue);
      expect(policy.canSubmitTemporalEvidence, isFalse);
    });

    test('reports customer backend failures without exposing credentials',
        () async {
      final error = StateError('customer request failed');

      await expectLater(
        KycClient.bootstrap(
          config: config,
          sessionProvider: () async => throw error,
        ),
        throwsA(
          isA<SessionBootstrapException>()
              .having(
                (exception) => exception.failure,
                'failure',
                SessionBootstrapFailure.provider,
              )
              .having((exception) => exception.cause, 'cause', same(error))
              .having(
                (exception) => exception.toString(),
                'message',
                isNot(contains('short-lived-token')),
              ),
        ),
      );
    });

    test('rejects an invalid session response', () async {
      await expectLater(
        KycClient.bootstrap(
          config: config,
          sessionProvider: () async => {
            'verificationSessionId': 'verification-id',
          },
        ),
        throwsA(
          isA<SessionBootstrapException>().having(
            (exception) => exception.failure,
            'failure',
            SessionBootstrapFailure.invalidResponse,
          ),
        ),
      );
    });

    test('requires a valid session expiry', () async {
      final payload = sdkBootstrapPayload(sdkTokenExpiresAt: 'not-a-date');

      await expectLater(
        KycClient.bootstrap(
          config: config,
          sessionProvider: () async => payload,
        ),
        throwsA(
          isA<SessionBootstrapException>().having(
            (exception) => exception.failure,
            'failure',
            SessionBootstrapFailure.invalidResponse,
          ),
        ),
      );
    });

    test('rejects an expired session', () async {
      await expectLater(
        KycClient.bootstrap(
          config: config,
          sessionProvider: () async => sdkBootstrapPayload(
            sdkTokenExpiresAt: '2020-01-01T00:00:00Z',
          ),
        ),
        throwsA(
          isA<SessionBootstrapException>().having(
            (exception) => exception.failure,
            'failure',
            SessionBootstrapFailure.expiredSession,
          ),
        ),
      );
    });
  });
}
