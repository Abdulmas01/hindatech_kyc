import '../../../../core/camera/camera_preview_geometry.dart';
import '../../domain/models/face_alignment.dart';
import '../../domain/services/face_alignment_service.dart';
import '../models/selfie_frame_models.dart';
import 'face_observation_detector.dart';
import 'face_observation_mapper.dart';
import 'selfie_input_image_adapter.dart';

class SelfieFrameAnalysisService {
  SelfieFrameAnalysisService({
    SelfieInputImageAdapter inputImageAdapter = const SelfieInputImageAdapter(),
    FaceObservationDetector? detector,
    FaceObservationMapper observationMapper = const FaceObservationMapper(),
    PolicyFaceAlignmentService? alignmentService,
  })  : _inputImageAdapter = inputImageAdapter,
        _detector = detector ?? MlKitFaceObservationDetector(),
        _observationMapper = observationMapper,
        _alignmentService = alignmentService ?? PolicyFaceAlignmentService();

  final SelfieInputImageAdapter _inputImageAdapter;
  final FaceObservationDetector _detector;
  final FaceObservationMapper _observationMapper;
  final PolicyFaceAlignmentService _alignmentService;

  Future<SelfieFrameAnalysis?> analyze(
      SelfieFrameAnalysisRequest request) async {
    final frame = _inputImageAdapter.prepare(
      SelfieCameraFrameRequest(
        controller: request.controller,
        image: request.image,
      ),
    );
    if (frame == null) return null;

    final rawFaces = await _detector.detect(frame.inputImage);
    final geometry = CameraPreviewGeometry(
      sourceSize: frame.sourceSize,
      viewportSize: request.viewportSize,
      rotation: frame.rotation,
      mirrored: frame.mirrored,
    );
    final faces = _observationMapper.map(
      FaceObservationMappingRequest(faces: rawFaces, geometry: geometry),
    );
    final alignment = _alignmentService.evaluate(
      PolicyFaceAlignmentRequest(
        faces: faces.map((face) => face.geometry).toList(growable: false),
        guideRect: request.guideRect,
        policy: request.policy,
      ),
    );
    return SelfieFrameAnalysis(faces: faces, alignment: alignment);
  }

  void reset() => _alignmentService.reset();

  Future<void> close() => _detector.close();
}
