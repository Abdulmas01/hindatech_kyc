import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/features/document_capture/domain/models/document_quality_assessment.dart';
import 'package:hindatech_kyc/src/features/document_capture/domain/services/document_quality_guidance_service.dart';

void main() {
  const good = DocumentQualityAssessment(
    signal: DocumentQualitySignal.good,
    confidence: 0.92,
    source: DocumentQualitySource.onDeviceInference,
  );
  const glare = DocumentQualityAssessment(
    signal: DocumentQualitySignal.glare,
    confidence: 0.81,
    source: DocumentQualitySource.heuristic,
  );

  test('does not suggest capture until guidance is stable', () {
    final service = DocumentQualityGuidanceService();

    final first = service.evaluate(assessment: good, stabilityFrames: 2);
    final second = service.evaluate(assessment: good, stabilityFrames: 2);

    expect(first.signal, DocumentQualitySignal.unknown);
    expect(first.isStable, isFalse);
    expect(first.suggestsCaptureReady, isFalse);
    expect(second.signal, DocumentQualitySignal.good);
    expect(second.isStable, isTrue);
    expect(second.suggestsCaptureReady, isTrue);
  });

  test('requires a stable transition away from good quality', () {
    final service = DocumentQualityGuidanceService();
    service.evaluate(assessment: good, stabilityFrames: 2);
    service.evaluate(assessment: good, stabilityFrames: 2);

    final firstGlare = service.evaluate(
      assessment: glare,
      stabilityFrames: 2,
    );
    final secondGlare = service.evaluate(
      assessment: glare,
      stabilityFrames: 2,
    );

    expect(firstGlare.signal, DocumentQualitySignal.good);
    expect(firstGlare.suggestsCaptureReady, isFalse);
    expect(secondGlare.signal, DocumentQualitySignal.glare);
    expect(secondGlare.suggestsCaptureReady, isFalse);
  });

  test('reset removes the active signal', () {
    final service = DocumentQualityGuidanceService();
    service.evaluate(assessment: good, stabilityFrames: 1);

    service.reset();

    expect(service.activeSignal, DocumentQualitySignal.unknown);
  });

  test('rejects invalid stability configuration', () {
    final service = DocumentQualityGuidanceService();

    expect(
      () => service.evaluate(assessment: good, stabilityFrames: 0),
      throwsArgumentError,
    );
  });
}
