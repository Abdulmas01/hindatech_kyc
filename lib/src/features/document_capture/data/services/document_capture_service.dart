import 'package:camera/camera.dart';

import '../../../../core/files/local_file_cleanup.dart';
import 'document_bounds_detector.dart';
import 'document_image_normalizer.dart';
import '../../domain/models/document_capture_config.dart';
import '../../domain/models/document_capture_result.dart';

class DocumentCaptureService {
  const DocumentCaptureService({
    this.normalizer = const DocumentImageNormalizer(),
  });

  final DocumentImageNormalizer normalizer;

  Future<DocumentCaptureResult> capture({
    required CameraController controller,
    required DocumentBoundsDetector boundsDetector,
    required DocumentCaptureConfig config,
  }) async {
    final original = await controller.takePicture();
    try {
      final bounds = await boundsDetector.detect(original.path);
      final normalized = await normalizer.normalize(
        inputPath: original.path,
        boundingBox: bounds,
        guideWidthFactor: config.guideWidthFactor,
        guideAspectRatio: config.guideAspectRatio,
        guideMaxHeightFactor: config.guideMaxHeightFactor,
      );

      return DocumentCaptureResult(
        originalPath: original.path,
        normalizedPath: normalized.path,
        captureSource: bounds == null
            ? DocumentCaptureSource.guideFallback
            : DocumentCaptureSource.objectDetector,
      );
    } catch (error, stackTrace) {
      try {
        await deleteLocalFiles([original.path]);
      } catch (_) {
        // Preserve the original capture failure.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
