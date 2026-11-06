import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  const digest =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('models the exact NestJS consent record request', () {
    final request = VerificationConsentRequest(
      purposeCode: ' verification_processing ',
      noticeId: 'kyc_notice',
      noticeVersion: '2026-01',
      noticeSha256: digest.toUpperCase(),
    );

    expect(request.toJson(), {
      'purposeCode': 'verification_processing',
      'noticeId': 'kyc_notice',
      'noticeVersion': '2026-01',
      'noticeSha256': digest,
    });
  });

  test('rejects consent fields that violate the NestJS constraints', () {
    expect(
      () => VerificationConsentRequest(
        purposeCode: 'Not Allowed',
        noticeId: 'kyc_notice',
        noticeVersion: '2026-01',
        noticeSha256: digest,
      ),
      throwsArgumentError,
    );
    expect(
      () => VerificationConsentRequest(
        purposeCode: 'verification_processing',
        noticeId: 'kyc_notice',
        noticeVersion: '2026-01',
        noticeSha256: 'not-a-digest',
      ),
      throwsArgumentError,
    );
  });

  test('parses recorded consent evidence', () {
    final evidence = VerificationConsentEvidence.fromJson(
      _evidenceJson('evidence-1'),
    );

    expect(evidence.purposeCode, 'verification_processing');
    expect(evidence.noticeSha256, digest);
    expect(evidence.affirmedAt, DateTime.utc(2026, 11, 6, 18, 30));
  });

  test('parses retained consent evidence results', () {
    final evidence = VerificationConsentEvidenceList.fromJson({
      'results': [_evidenceJson('evidence-1'), _evidenceJson('evidence-2')],
    });

    expect(evidence.results.map((item) => item.id), [
      'evidence-1',
      'evidence-2',
    ]);
  });
}

Map<String, Object?> _evidenceJson(String id) => {
      'id': id,
      'purposeCode': 'verification_processing',
      'noticeId': 'kyc_notice',
      'noticeVersion': '2026-01',
      'noticeSha256':
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'sourceType': 'product_ui',
      'affirmedAt': '2026-11-06T18:30:00.000Z',
    };
