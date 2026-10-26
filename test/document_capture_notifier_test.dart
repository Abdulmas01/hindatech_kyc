import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/features/document_capture/domain/models/document_quality_assessment.dart';
import 'package:hindatech_kyc/src/features/document_capture/domain/services/document_quality_guidance_service.dart';
import 'package:hindatech_kyc/src/features/document_capture/presentation/controllers/document_capture_notifier.dart';
import 'package:hindatech_kyc/src/features/document_capture/presentation/models/document_capture_state.dart';

void main() {
  late ProviderContainer container;
  late ProviderSubscription<DocumentCaptureState> subscription;

  setUp(() {
    container = ProviderContainer();
    subscription = container.listen(
      documentCaptureProvider,
      (_, __) {},
      fireImmediately: true,
    );
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  test('starts in the initializing phase', () {
    expect(
      container.read(documentCaptureProvider).phase,
      DocumentCapturePhase.initializing,
    );
  });

  test('records permanent permission denial without UI copy', () {
    container
        .read(documentCaptureProvider.notifier)
        .setPermissionDenied(permanentlyDenied: true);

    final state = container.read(documentCaptureProvider);
    expect(state.phase, DocumentCapturePhase.permissionPermanentlyDenied);
    expect(state.error, isNull);
  });

  test('captures and clears a document preview', () {
    final notifier = container.read(documentCaptureProvider.notifier);
    notifier.setReady();
    notifier.setCaptured('document.jpg');

    expect(
      container.read(documentCaptureProvider).capturedPreviewPath,
      'document.jpg',
    );

    notifier.clearCaptured();

    final state = container.read(documentCaptureProvider);
    expect(state.phase, DocumentCapturePhase.ready);
    expect(state.capturedPreviewPath, isNull);
  });

  test('keeps advisory quality guidance separate from capture phase', () {
    final notifier = container.read(documentCaptureProvider.notifier);
    notifier.setReady();
    notifier.updateQuality(
      const DocumentQualityGuidance(
        signal: DocumentQualitySignal.good,
        confidence: 0.91,
        isStable: true,
        suggestsCaptureReady: true,
      ),
    );

    final state = container.read(documentCaptureProvider);
    expect(state.phase, DocumentCapturePhase.ready);
    expect(state.qualitySignal, DocumentQualitySignal.good);
    expect(state.qualityConfidence, 0.91);
    expect(state.isQualityStable, isTrue);
    expect(state.suggestsCaptureReady, isTrue);
  });
}
