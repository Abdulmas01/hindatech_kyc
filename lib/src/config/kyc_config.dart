import '../presentation/document_capture_strings.dart';
import '../presentation/document_capture_theme.dart';
import '../presentation/selfie_capture_strings.dart';
import '../presentation/selfie_capture_theme.dart';

/// Configuration supplied by the application using the SDK.
class KycConfig {
  /// Creates configuration for the hosted Hindatech production API.
  factory KycConfig.production({
    Duration requestTimeout = const Duration(seconds: 30),
    Duration pollingInterval = const Duration(seconds: 2),
    int maxPollingAttempts = 30,
    DocumentCaptureTheme theme = const DocumentCaptureTheme(),
    DocumentCaptureStrings strings = const DocumentCaptureStrings(),
    SelfieCaptureTheme selfieTheme = const SelfieCaptureTheme(),
    SelfieCaptureStrings selfieStrings = const SelfieCaptureStrings(),
  }) {
    return KycConfig(
      apiBaseUri: productionApiBaseUri,
      requestTimeout: requestTimeout,
      pollingInterval: pollingInterval,
      maxPollingAttempts: maxPollingAttempts,
      theme: theme,
      strings: strings,
      selfieTheme: selfieTheme,
      selfieStrings: selfieStrings,
    );
  }

  const KycConfig({
    required this.apiBaseUri,
    this.requestTimeout = const Duration(seconds: 30),
    this.pollingInterval = const Duration(seconds: 2),
    this.maxPollingAttempts = 30,
    this.theme = const DocumentCaptureTheme(),
    this.strings = const DocumentCaptureStrings(),
    this.selfieTheme = const SelfieCaptureTheme(),
    this.selfieStrings = const SelfieCaptureStrings(),
  })  : assert(requestTimeout > Duration.zero),
        assert(pollingInterval > Duration.zero),
        assert(maxPollingAttempts > 0);

  /// Base URI of the hosted Hindatech production API.
  static final Uri productionApiBaseUri =
      Uri.parse('https://api.kyc.hindatech.com/api/v1/');

  /// API base URI used to construct every SDK endpoint.
  final Uri apiBaseUri;
  final Duration requestTimeout;
  final Duration pollingInterval;
  final int maxPollingAttempts;
  final DocumentCaptureTheme theme;
  final DocumentCaptureStrings strings;
  final SelfieCaptureTheme selfieTheme;
  final SelfieCaptureStrings selfieStrings;
}
