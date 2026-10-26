import '../../../../core/files/local_file_cleanup.dart' as file_cleanup;

enum DocumentCaptureSource { objectDetector, guideFallback }

/// Local files produced by a completed document capture.
///
/// The capture view owns these files until its Continue action invokes
/// `onCompleted`. The receiving application owns them after that callback and
/// should call [deleteLocalFiles] when upload or other processing is finished.
class DocumentCaptureResult {
  const DocumentCaptureResult({
    required this.originalPath,
    required this.normalizedPath,
    required this.captureSource,
  });

  final String originalPath;
  final String normalizedPath;
  final DocumentCaptureSource captureSource;

  bool get usedGuideCropFallback =>
      captureSource == DocumentCaptureSource.guideFallback;

  /// Deletes the original and normalized files if they still exist.
  ///
  /// Calling this more than once is safe. The paths must not be used after the
  /// returned future completes.
  Future<void> deleteLocalFiles() =>
      file_cleanup.deleteLocalFiles({originalPath, normalizedPath});
}
