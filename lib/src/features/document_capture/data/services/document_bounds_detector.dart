import 'dart:ui';

import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

abstract interface class DocumentBoundsDetector {
  Future<Rect?> detect(String imagePath);

  Future<void> close();
}

class MlKitDocumentBoundsDetector implements DocumentBoundsDetector {
  MlKitDocumentBoundsDetector({ObjectDetector? detector})
      : _detector = detector ??
            ObjectDetector(
              options: ObjectDetectorOptions(
                mode: DetectionMode.single,
                classifyObjects: false,
                multipleObjects: false,
              ),
            );

  final ObjectDetector _detector;

  @override
  Future<Rect?> detect(String imagePath) async {
    final objects = await _detector.processImage(
      InputImage.fromFilePath(imagePath),
    );
    return objects.isEmpty ? null : objects.first.boundingBox;
  }

  @override
  Future<void> close() => _detector.close();
}
