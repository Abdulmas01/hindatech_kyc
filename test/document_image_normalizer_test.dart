import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/capture/document/document_image_normalizer.dart';

void main() {
  group('DocumentImageNormalizer.calculateOutputSize', () {
    test('preserves images within the maximum dimension', () {
      final size = DocumentImageNormalizer.calculateOutputSize(
        width: 1200,
        height: 800,
      );

      expect(size, (width: 1200, height: 800));
    });

    test('downscales without changing aspect ratio', () {
      final size = DocumentImageNormalizer.calculateOutputSize(
        width: 3200,
        height: 1600,
      );

      expect(size, (width: 1600, height: 800));
    });

    test('rejects invalid dimensions', () {
      expect(
        () => DocumentImageNormalizer.calculateOutputSize(
          width: 0,
          height: 800,
        ),
        throwsArgumentError,
      );
    });
  });

  test('centered guide stays within a portrait image', () {
    final rect = DocumentImageNormalizer.centeredGuideRect(
      imageWidth: 1080,
      imageHeight: 1920,
      guideWidthFactor: 0.86,
      guideAspectRatio: 0.63,
      guideMaxHeightFactor: 0.82,
    );

    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(1080));
    expect(rect.bottom, lessThanOrEqualTo(1920));
  });

  test('intersection returns null for non-overlapping rectangles', () {
    final intersection = DocumentImageNormalizer.intersect(
      const Rect.fromLTWH(0, 0, 10, 10),
      const Rect.fromLTWH(20, 20, 10, 10),
    );

    expect(intersection, isNull);
  });
}
