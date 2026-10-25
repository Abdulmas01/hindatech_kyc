import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';

class DocumentImageNormalizer {
  const DocumentImageNormalizer();

  static const int defaultMaxOutputDimension = 1600;
  static const int defaultJpegQuality = 95;

  Future<File> normalize({
    required String inputPath,
    Rect? boundingBox,
    int maxOutputDimension = defaultMaxOutputDimension,
    int jpegQuality = defaultJpegQuality,
    bool fallbackToGuide = true,
    bool constrainToGuide = true,
    double guideWidthFactor = 0.86,
    double guideAspectRatio = 0.63,
    double guideMaxHeightFactor = 0.82,
  }) async {
    final decoded = image.decodeImage(await File(inputPath).readAsBytes());
    if (decoded == null) {
      throw const FormatException('Unable to decode the document image.');
    }

    final oriented = image.bakeOrientation(decoded);
    final guideRect = centeredGuideRect(
      imageWidth: oriented.width.toDouble(),
      imageHeight: oriented.height.toDouble(),
      guideWidthFactor: guideWidthFactor,
      guideAspectRatio: guideAspectRatio,
      guideMaxHeightFactor: guideMaxHeightFactor,
    );

    Rect? cropRect = boundingBox;
    if (cropRect == null && fallbackToGuide) {
      cropRect = guideRect;
    }
    if (cropRect != null && constrainToGuide) {
      cropRect = intersect(cropRect, guideRect) ?? guideRect;
    }

    var normalized = oriented;
    if (cropRect != null) {
      final left = max(0, cropRect.left.floor());
      final top = max(0, cropRect.top.floor());
      final right = min(oriented.width, cropRect.right.ceil());
      final bottom = min(oriented.height, cropRect.bottom.ceil());
      normalized = image.copyCrop(
        oriented,
        x: left,
        y: top,
        width: max(1, right - left),
        height: max(1, bottom - top),
      );
    }

    final outputSize = calculateOutputSize(
      width: normalized.width,
      height: normalized.height,
      maxDimension: maxOutputDimension,
    );
    if (outputSize.width != normalized.width ||
        outputSize.height != normalized.height) {
      normalized = image.copyResize(
        normalized,
        width: outputSize.width,
        height: outputSize.height,
        interpolation: image.Interpolation.cubic,
      );
    }

    final outputDirectory = await getTemporaryDirectory();
    final output = File(
      '${outputDirectory.path}/hindatech_document_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await output.writeAsBytes(
      image.encodeJpg(normalized, quality: jpegQuality),
      flush: true,
    );
    return output;
  }

  static ({int width, int height}) calculateOutputSize({
    required int width,
    required int height,
    int maxDimension = defaultMaxOutputDimension,
  }) {
    if (width <= 0 || height <= 0 || maxDimension <= 0) {
      throw ArgumentError('Image dimensions must be positive.');
    }

    final longestSide = max(width, height);
    if (longestSide <= maxDimension) {
      return (width: width, height: height);
    }

    final scale = maxDimension / longestSide;
    return (
      width: max(1, (width * scale).round()),
      height: max(1, (height * scale).round()),
    );
  }

  static Rect centeredGuideRect({
    required double imageWidth,
    required double imageHeight,
    required double guideWidthFactor,
    required double guideAspectRatio,
    required double guideMaxHeightFactor,
  }) {
    var width = imageWidth * guideWidthFactor;
    var height = width * guideAspectRatio;
    if (height > imageHeight * guideMaxHeightFactor) {
      height = imageHeight * guideMaxHeightFactor;
      width = height / guideAspectRatio;
    }

    return Rect.fromLTWH(
      (imageWidth - width) / 2,
      (imageHeight - height) / 2,
      width,
      height,
    );
  }

  static Rect? intersect(Rect first, Rect second) {
    final left = max(first.left, second.left);
    final top = max(first.top, second.top);
    final right = min(first.right, second.right);
    final bottom = min(first.bottom, second.bottom);
    if (right <= left || bottom <= top) return null;
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
