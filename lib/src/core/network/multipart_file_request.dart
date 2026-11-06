/// Internal transport input for one multipart file request.
class MultipartFileRequest {
  MultipartFileRequest({
    required Map<String, String> fields,
    required this.filePath,
    required this.contentType,
  }) : fields = Map.unmodifiable(fields);

  final Map<String, String> fields;
  final String filePath;
  final String contentType;
}
