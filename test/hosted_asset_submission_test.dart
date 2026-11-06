import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  test('models exact hosted asset selections as one request', () {
    final source = {'document_front': 'asset-front'};
    final request = HostedAssetSubmissionRequest(assets: source);
    source['document_front'] = 'changed-after-construction';

    expect(request.toJson(), {
      'assets': {'document_front': 'asset-front'},
    });
  });

  test('parses the NestJS hosted submission response', () {
    final submission = VerificationSubmission.fromJson({
      'verificationSessionId': 'verification-id',
      'status': 'processing',
      'submittedAt': '2026-08-02T16:05:00.000Z',
    });

    expect(submission.status, VerificationSessionStatus.processing);
    expect(submission.submittedAt, DateTime.utc(2026, 8, 2, 16, 5));
  });
}
