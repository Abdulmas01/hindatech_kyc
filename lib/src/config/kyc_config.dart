import '../presentation/document_capture_strings.dart';
import '../presentation/document_capture_theme.dart';

/// Configuration supplied by the application using the SDK.
class KycConfig {
  const KycConfig({
    required this.apiBaseUri,
    this.requestTimeout = const Duration(seconds: 30),
    this.pollingInterval = const Duration(seconds: 2),
    this.maxPollingAttempts = 30,
    this.enableLocalQualityGuidance = true,
    this.theme = const DocumentCaptureTheme(),
    this.strings = const DocumentCaptureStrings(),
  }) : assert(maxPollingAttempts > 0);

  final Uri apiBaseUri;
  final Duration requestTimeout;
  final Duration pollingInterval;
  final int maxPollingAttempts;
  final bool enableLocalQualityGuidance;
  final DocumentCaptureTheme theme;
  final DocumentCaptureStrings strings;
}
