import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  test('models the NestJS typed payload request', () {
    final payload = <String, Object?>{
      'source': 'customer_account',
      'referenceId': 'profile-photo-123',
    };
    final metadata = <String, Object?>{'capturedBy': 'customer_backend'};
    final request = VerificationPayloadRequest(
      payloadType: 'reference_provenance',
      payload: payload,
      metadata: metadata,
    );
    payload['source'] = 'changed';
    metadata['capturedBy'] = 'changed';

    expect(request.toJson(), {
      'payloadType': 'reference_provenance',
      'payload': {
        'source': 'customer_account',
        'referenceId': 'profile-photo-123',
      },
      'metadata': {'capturedBy': 'customer_backend'},
    });
  });

  test('omits optional metadata when it is not supplied', () {
    final request = VerificationPayloadRequest(
      payloadType: 'subject_metadata',
      payload: {'channel': 'mobile'},
    );

    expect(request.toJson(), {
      'payloadType': 'subject_metadata',
      'payload': {'channel': 'mobile'},
    });
  });

  test('parses the NestJS typed payload receipt', () {
    final receipt = VerificationPayloadReceipt.fromJson({
      'id': 'payload_123',
      'payloadType': 'reference_provenance',
      'revision': 1,
    });

    expect(receipt.payloadType, VerificationPayloadType.referenceProvenance);
    expect(receipt.revision, 1);
  });
}
