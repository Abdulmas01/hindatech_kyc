import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  final config = KycConfig(apiBaseUri: Uri.parse('https://api.example.com'));

  group('KycClient bootstrap', () {
    test('creates a client from a customer-provided session response',
        () async {
      final client = await KycClient.bootstrap(
        config: config,
        sessionProvider: () async => _sessionPayload(
          expiresAt: '2099-01-01T00:00:00Z',
        ),
      );

      expect(client.config, same(config));
      expect(client.session.verificationId, 'verification-id');
      expect(client.session.sdkToken, 'short-lived-token');
      expect(client.session.captureManifest.requiredAssets, hasLength(1));
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
            'id': 'verification-id',
            'capture_manifest': {'required_assets': <Object?>[]},
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
      final payload = _sessionPayload(expiresAt: 'not-a-date');

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
          sessionProvider: () async => _sessionPayload(
            expiresAt: '2020-01-01T00:00:00Z',
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

Map<String, Object?> _sessionPayload({required String expiresAt}) => {
      'id': 'verification-id',
      'sdk_token': 'short-lived-token',
      'expires_at': expiresAt,
      'capture_manifest': {
        'version': 1,
        'required_assets': [
          {
            'type': 'document_front',
            'capture': 'document',
          },
        ],
      },
    };
