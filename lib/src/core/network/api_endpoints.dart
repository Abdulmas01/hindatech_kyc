/// Builds every verification API endpoint from one versioned base URI.
///
/// Configure the base as the API root, for example
/// `https://api.example.com/api/v1/`. Feature code should use this class rather
/// than assembling URL strings independently.
class ApiEndpoints {
  ApiEndpoints(Uri apiBaseUri) : _baseUri = _normalizeBaseUri(apiBaseUri);

  final Uri _baseUri;

  Uri get verifications => _resolve(const ['verifications']);

  Uri verification(String verificationId) =>
      _resolve(['verifications', _requireId(verificationId)]);

  Uri verificationAssets(String verificationId) =>
      _resolve(['verifications', _requireId(verificationId), 'assets']);

  Uri verificationSubmit(String verificationId) =>
      _resolve(['verifications', _requireId(verificationId), 'submit']);

  Uri _resolve(List<String> segments) => _baseUri.replace(
        pathSegments: [..._baseUri.pathSegments, ...segments],
      );

  static Uri _normalizeBaseUri(Uri uri) {
    if (!uri.hasScheme || !uri.hasAuthority) {
      throw ArgumentError.value(
        uri,
        'apiBaseUri',
        'Must be an absolute HTTP or HTTPS URI.',
      );
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError.value(
        uri,
        'apiBaseUri',
        'Must use the HTTP or HTTPS scheme.',
      );
    }

    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    return uri.replace(pathSegments: segments.toList(growable: false));
  }

  static String _requireId(String value) {
    final id = value.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(value, 'verificationId', 'Must not be empty.');
    }
    return id;
  }
}
