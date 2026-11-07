import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/data/services/selfie_input_image_adapter.dart';

void main() {
  test('accepts a single-plane CameraX NV21 buffer reported as YUV420', () {
    final bytes = Uint8List(12);

    final normalized = normalizeSinglePlaneNv21Bytes(
      source: bytes,
      width: 4,
      height: 2,
    );

    expect(normalized, same(bytes));
  });

  test('trims padding and rejects an incomplete single-plane NV21 buffer', () {
    final padded = normalizeSinglePlaneNv21Bytes(
      source: Uint8List(16),
      width: 4,
      height: 2,
    );
    final incomplete = normalizeSinglePlaneNv21Bytes(
      source: Uint8List(11),
      width: 4,
      height: 2,
    );

    expect(padded, hasLength(12));
    expect(incomplete, isNull);
  });
}
