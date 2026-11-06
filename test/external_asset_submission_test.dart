import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  test('models the exact NestJS external reference request', () {
    final request = ExternalAssetSubmissionRequest(
      assets: {
        'document_front': ExternalAssetReference(
          referenceUri: Uri.parse(
            'https://storage.example.com/document.jpg?signature=secret',
          ),
          referenceId: 'customer-document-front-2026-08-02',
          storageProvider: 'customer-s3',
          contentType: 'IMAGE/JPEG',
          expiresAt: DateTime.utc(2099, 8, 2, 16, 10),
        ),
      },
    );

    expect(request.toJson(), {
      'assets': {
        'document_front': {
          'referenceUrl':
              'https://storage.example.com/document.jpg?signature=secret',
          'referenceId': 'customer-document-front-2026-08-02',
          'storageProvider': 'customer-s3',
          'contentType': 'image/jpeg',
          'expiresAt': '2099-08-02T16:10:00.000Z',
        },
      },
    });
  });

  test('omits optional external reference metadata', () {
    final reference = ExternalAssetReference(
      referenceUri: Uri.parse('https://storage.example.com/document.jpg'),
    );

    expect(reference.toJson(), {
      'referenceUrl': 'https://storage.example.com/document.jpg',
    });
  });

  test('rejects non-HTTPS and credential-bearing URLs', () {
    expect(
      () => ExternalAssetReference(
        referenceUri: Uri.parse('http://storage.example.com/document.jpg'),
      ),
      throwsArgumentError,
    );
    expect(
      () => ExternalAssetReference(
        referenceUri: Uri.parse(
          'https://user:password@storage.example.com/document.jpg',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects provenance labels that may contain credentials', () {
    expect(
      () => ExternalAssetReference(
        referenceUri: Uri.parse('https://storage.example.com/document.jpg'),
        referenceId: 'signed value with spaces',
      ),
      throwsArgumentError,
    );
  });

  test('reports expired external references', () {
    final reference = ExternalAssetReference(
      referenceUri: Uri.parse('https://storage.example.com/document.jpg'),
      expiresAt: DateTime.utc(2020),
    );

    expect(reference.isExpired, isTrue);
  });
}
