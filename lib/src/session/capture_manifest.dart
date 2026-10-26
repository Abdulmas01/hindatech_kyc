/// A known asset that a verification workflow can ask the SDK to collect.
enum CaptureAssetType {
  documentFront('document_front'),
  documentBack('document_back'),
  selfie('selfie'),
  livenessSequence('liveness_sequence'),
  referenceFace('reference_face'),
  unknown('unknown');

  const CaptureAssetType(this.wireValue);

  final String wireValue;

  static CaptureAssetType fromWireValue(String value) {
    for (final type in values) {
      if (type != unknown && type.wireValue == value) {
        return type;
      }
    }
    return unknown;
  }
}

/// A known capture experience that can collect an asset.
enum CaptureMethod {
  document('document'),
  selfie('selfie'),
  liveness('liveness'),
  fileUpload('file_upload'),
  unknown('unknown');

  const CaptureMethod(this.wireValue);

  final String wireValue;

  static CaptureMethod fromWireValue(String? value) {
    for (final method in values) {
      if (method != unknown && method.wireValue == value) {
        return method;
      }
    }
    return unknown;
  }
}

/// One asset requested by a server-defined verification workflow.
class CaptureRequirement {
  CaptureRequirement({
    required this.assetTypeValue,
    this.captureMethodValue,
    this.isRequired = true,
    Map<String, Object?> options = const {},
  }) : options = Map.unmodifiable(options);

  final String assetTypeValue;
  final String? captureMethodValue;
  final bool isRequired;
  final Map<String, Object?> options;

  CaptureAssetType get assetType =>
      CaptureAssetType.fromWireValue(assetTypeValue);

  CaptureMethod get captureMethod =>
      CaptureMethod.fromWireValue(captureMethodValue);

  factory CaptureRequirement.fromJson(Map<String, Object?> json) {
    final assetType = json['type']?.toString().trim() ?? '';
    if (assetType.isEmpty) {
      throw const FormatException('Capture requirement type is missing.');
    }

    final captureMethod = json['capture']?.toString().trim();
    final rawOptions = json['options'];

    return CaptureRequirement(
      assetTypeValue: assetType,
      captureMethodValue:
          captureMethod == null || captureMethod.isEmpty ? null : captureMethod,
      isRequired: json['required'] is bool ? json['required']! as bool : true,
      options:
          rawOptions is Map ? Map<String, Object?>.from(rawOptions) : const {},
    );
  }

  Map<String, Object?> toJson() => {
        'type': assetTypeValue,
        if (captureMethodValue != null) 'capture': captureMethodValue,
        'required': isRequired,
        if (options.isNotEmpty) 'options': options,
      };
}

/// Server-provided instructions describing what the SDK must collect.
class CaptureManifest {
  CaptureManifest({
    required List<CaptureRequirement> requiredAssets,
    this.workflowKey,
    this.version,
  }) : requiredAssets = List.unmodifiable(requiredAssets);

  final String? workflowKey;
  final int? version;
  final List<CaptureRequirement> requiredAssets;

  bool get isEmpty => requiredAssets.isEmpty;

  factory CaptureManifest.fromJson(Map<String, Object?> json) {
    final rawAssets = json['required_assets'];
    if (rawAssets is! List) {
      throw const FormatException(
        'Capture manifest required_assets must be a list.',
      );
    }

    return CaptureManifest(
      workflowKey: _optionalString(json['workflow_key']),
      version: _optionalInt(json['version']),
      requiredAssets: rawAssets.map((asset) {
        if (asset is! Map) {
          throw const FormatException(
            'Each capture requirement must be an object.',
          );
        }
        return CaptureRequirement.fromJson(
          Map<String, Object?>.from(asset),
        );
      }).toList(growable: false),
    );
  }

  Map<String, Object?> toJson() => {
        if (workflowKey != null) 'workflow_key': workflowKey,
        if (version != null) 'version': version,
        'required_assets': requiredAssets
            .map((requirement) => requirement.toJson())
            .toList(growable: false),
      };

  static String? _optionalString(Object? value) {
    final parsed = value?.toString().trim();
    return parsed == null || parsed.isEmpty ? null : parsed;
  }

  static int? _optionalInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
