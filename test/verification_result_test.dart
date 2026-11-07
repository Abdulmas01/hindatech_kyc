import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  test('maps the customer-safe NestJS result fields', () {
    final result = VerificationResult.fromJson({
      'id': 'verification-id',
      'status': 'completed',
      'decision': 'accept',
      'riskScore': 0.12,
      'createdAt': '2026-08-02T16:00:00.000Z',
      'completedAt': '2026-08-02T16:01:00.000Z',
      'failureCode': null,
      'failureMessage': null,
      'reasonCodes': ['document_verified'],
      'documentExtraction': {'internal': 'not exposed'},
    });

    expect(result.verificationSessionId, 'verification-id');
    expect(result.status, VerificationSessionStatus.completed);
    expect(result.decision, VerificationDecision.accept);
    expect(result.riskScore, 0.12);
    expect(result.completedAt, DateTime.utc(2026, 8, 2, 16, 1));
    expect(result.reasonCodes, ['document_verified']);
  });

  test('keeps future decision values forward compatible', () {
    final result = VerificationResult.fromJson({
      'id': 'verification-id',
      'status': 'future_status',
      'decision': 'future_decision',
      'riskScore': null,
      'createdAt': '2026-08-02T16:00:00.000Z',
      'completedAt': null,
    });

    expect(result.status, VerificationSessionStatus.unknown);
    expect(result.decision, VerificationDecision.unknown);
    expect(result.statusValue, 'future_status');
    expect(result.decisionValue, 'future_decision');
    expect(result.reasonCodes, isEmpty);
  });

  test('rejects malformed required result fields', () {
    expect(
      () => VerificationResult.fromJson({
        'id': 'verification-id',
        'status': 'completed',
        'decision': 'accept',
        'createdAt': '2026-08-02T16:00:00.000Z',
        'completedAt': null,
      }),
      throwsFormatException,
    );
  });
}
