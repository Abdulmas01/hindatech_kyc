import '../../../../core/files/local_file_cleanup.dart' as file_cleanup;

/// Local image produced by a completed selfie capture.
///
/// The capture view owns the file until its Continue action invokes
/// `onCompleted`. The receiving application owns it after that callback and
/// should call [deleteLocalFile] after upload or other processing is finished.
class SelfieCaptureResult {
  const SelfieCaptureResult({required this.path});

  final String path;

  /// Deletes the captured image if it still exists.
  ///
  /// Calling this more than once is safe. [path] must not be used after the
  /// returned future completes.
  Future<void> deleteLocalFile() => file_cleanup.deleteLocalFiles({path});
}
