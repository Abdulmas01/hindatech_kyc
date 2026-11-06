/// Shared strict readers for NestJS contract maps.
abstract final class JsonFields {
  static String requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    final parsed = value is String ? value.trim() : '';
    if (parsed.isEmpty) throw FormatException('$key is missing or invalid.');
    return parsed;
  }

  static DateTime requiredDateTime(Map<String, Object?> json, String key) {
    final value = json[key];
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) throw FormatException('$key is missing or invalid.');
    return parsed.toUtc();
  }

  static List<String> requiredStringList(
    Map<String, Object?> json,
    String key,
  ) {
    final raw = json[key];
    if (raw is! List) throw FormatException('$key must be a list.');
    return raw.map((value) {
      final parsed = value is String ? value.trim() : '';
      if (parsed.isEmpty) {
        throw FormatException('$key contains an invalid value.');
      }
      return parsed;
    }).toList(growable: false);
  }

  static Map<String, Object?> requiredMap(
    Map<String, Object?> json,
    String key,
  ) {
    final raw = json[key];
    if (raw is! Map) throw FormatException('$key is missing or invalid.');
    return Map<String, Object?>.from(raw);
  }

  static List<Object?> requiredList(
    Map<String, Object?> json,
    String key,
  ) {
    final raw = json[key];
    if (raw is! List) throw FormatException('$key must be a list.');
    return List<Object?>.from(raw);
  }
}
