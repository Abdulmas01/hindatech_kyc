/// Configuration supplied by the application using the SDK.
class HindatechKycConfig {
  const HindatechKycConfig({
    required this.apiBaseUri,
    this.requestTimeout = const Duration(seconds: 30),
    this.pollingInterval = const Duration(seconds: 2),
    this.maxPollingAttempts = 30,
    this.enableLocalQualityGuidance = true,
  }) : assert(maxPollingAttempts > 0);

  final Uri apiBaseUri;
  final Duration requestTimeout;
  final Duration pollingInterval;
  final int maxPollingAttempts;
  final bool enableLocalQualityGuidance;
}
