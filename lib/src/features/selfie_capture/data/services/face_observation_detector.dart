import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/selfie_frame_models.dart';

abstract interface class FaceObservationDetector {
  Future<List<RawFaceObservation>> detect(InputImage image);

  Future<void> close();
}

class MlKitFaceObservationDetector implements FaceObservationDetector {
  MlKitFaceObservationDetector({FaceDetector? detector})
      : _detector = detector ??
            FaceDetector(
              options: FaceDetectorOptions(
                performanceMode: FaceDetectorMode.accurate,
                enableClassification: true,
                enableTracking: true,
                minFaceSize: 0.15,
              ),
            );

  final FaceDetector _detector;

  @override
  Future<List<RawFaceObservation>> detect(InputImage image) async {
    final faces = await _detector.processImage(image);
    return List.unmodifiable(
      faces.map(
        (face) => RawFaceObservation(
          bounds: face.boundingBox,
          yawDegrees: face.headEulerAngleY,
          pitchDegrees: face.headEulerAngleX,
          rollDegrees: face.headEulerAngleZ,
          leftEyeOpenProbability: face.leftEyeOpenProbability,
          rightEyeOpenProbability: face.rightEyeOpenProbability,
          trackingId: face.trackingId,
        ),
      ),
    );
  }

  @override
  Future<void> close() => _detector.close();
}
