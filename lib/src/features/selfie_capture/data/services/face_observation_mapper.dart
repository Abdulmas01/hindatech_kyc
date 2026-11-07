import '../../domain/models/face_alignment.dart';
import '../models/selfie_frame_models.dart';

class FaceObservationMapper {
  const FaceObservationMapper();

  List<MappedFaceObservation> map(FaceObservationMappingRequest request) {
    return List.unmodifiable(
      request.faces.map(
        (face) => MappedFaceObservation(
          geometry: DetectedFaceGeometry(
            bounds: request.geometry.mapRect(face.bounds),
            yawDegrees: face.yawDegrees,
            pitchDegrees: face.pitchDegrees,
            rollDegrees: face.rollDegrees,
          ),
          leftEyeOpenProbability: face.leftEyeOpenProbability,
          rightEyeOpenProbability: face.rightEyeOpenProbability,
          trackingId: face.trackingId,
        ),
      ),
    );
  }
}
