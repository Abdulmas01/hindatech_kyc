/// One temporary customer-managed asset reference for NestJS to fetch.
///
/// The URL may contain a short-lived signature and must never be logged or
/// retained beyond the active verification session.
class ExternalAssetReference {
  ExternalAssetReference({
    required this.referenceUri,
    String? referenceId,
    String? storageProvider,
    String? contentType,
    this.expiresAt,
  })  : referenceId = referenceId?.trim(),
        storageProvider = storageProvider?.trim(),
        contentType = contentType?.trim().toLowerCase() {
    _validate();
  }

  static final RegExp _labelPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$');

  final Uri referenceUri;
  final String? referenceId;
  final String? storageProvider;
  final String? contentType;
  final DateTime? expiresAt;

  bool get isExpired {
    final expiry = expiresAt;
    return expiry != null && !expiry.toUtc().isAfter(DateTime.now().toUtc());
  }

  Map<String, Object?> toJson() => {
        'referenceUrl': referenceUri.toString(),
        if (referenceId != null) 'referenceId': referenceId,
        if (storageProvider != null) 'storageProvider': storageProvider,
        if (contentType != null) 'contentType': contentType,
        if (expiresAt != null)
          'expiresAt': expiresAt!.toUtc().toIso8601String(),
      };

  void _validate() {
    if (referenceUri.scheme != 'https' ||
        !referenceUri.hasAuthority ||
        referenceUri.host.isEmpty ||
        referenceUri.userInfo.isNotEmpty) {
      throw ArgumentError(
        'referenceUri must be an absolute HTTPS URL without user credentials.',
      );
    }
    _validateLabel(referenceId, 'referenceId', 128);
    _validateLabel(storageProvider, 'storageProvider', 64);
    final type = contentType;
    if (type != null && (type.isEmpty || type.length > 128)) {
      throw ArgumentError('contentType must contain at most 128 characters.');
    }
  }

  static void _validateLabel(String? value, String name, int maxLength) {
    if (value == null) return;
    if (value.length > maxLength || !_labelPattern.hasMatch(value)) {
      throw ArgumentError(
        '$name must be a credential-free label with at most $maxLength characters.',
      );
    }
  }
}

/// External asset references selected for workflow input slots.
class ExternalAssetSubmissionRequest {
  ExternalAssetSubmissionRequest({
    required Map<String, ExternalAssetReference> assets,
  }) : assets = Map.unmodifiable(assets);

  final Map<String, ExternalAssetReference> assets;

  Map<String, Object?> toJson() => {
        'assets': assets.map(
          (inputType, reference) => MapEntry(inputType, reference.toJson()),
        ),
      };
}
