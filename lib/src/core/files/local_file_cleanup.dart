import 'dart:io';

Future<void> deleteLocalFiles(Iterable<String> paths) async {
  Object? firstError;
  StackTrace? firstStackTrace;
  for (final path in paths.toSet()) {
    if (path.isEmpty) continue;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
  }
  if (firstError != null) {
    Error.throwWithStackTrace(firstError, firstStackTrace!);
  }
}
