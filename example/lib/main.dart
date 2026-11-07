import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() => runApp(const ExampleApp());

final RouteObserver<ModalRoute<dynamic>> exampleRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hindatech KYC Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B3A)),
        useMaterial3: true,
      ),
      navigatorObservers: [exampleRouteObserver],
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  DocumentCaptureResult? _lastDocumentCapture;
  SelfieCaptureResult? _lastSelfieCapture;
  _ExampleCaptureSettings _settings = const _ExampleCaptureSettings();

  Future<void> _openCaptureSettings() async {
    final next = await showModalBottomSheet<_ExampleCaptureSettings>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CaptureSettingsSheet(initial: _settings),
    );
    if (next != null && mounted) setState(() => _settings = next);
  }

  Future<void> _startDocumentCapture() async {
    final result = await Navigator.of(context).push<DocumentCaptureResult>(
      MaterialPageRoute(
        builder: (_) => DocumentCapturePage(
          config: _settings.documentConfig,
          showDiagnostics: _settings.showDiagnostics,
        ),
      ),
    );
    if (result == null) return;
    if (!mounted) {
      await result.deleteLocalFiles();
      return;
    }

    final previousCapture = _lastDocumentCapture;
    setState(() => _lastDocumentCapture = result);
    await previousCapture?.deleteLocalFiles();
  }

  Future<void> _startSelfieCapture() async {
    final result = await Navigator.of(context).push<SelfieCaptureResult>(
      MaterialPageRoute(
        builder: (_) => SelfieCapturePage(
          policy: demoLivenessPolicy(randomize: _settings.randomizeChallenges),
          config: _settings.selfieConfig,
          showDiagnostics: _settings.showDiagnostics,
        ),
      ),
    );
    if (result == null) return;
    if (!mounted) {
      await result.deleteLocalFile();
      return;
    }

    final previousCapture = _lastSelfieCapture;
    setState(() => _lastSelfieCapture = result);
    await previousCapture?.deleteLocalFile();
  }

  @override
  void dispose() {
    final documentCapture = _lastDocumentCapture;
    if (documentCapture != null) {
      unawaited(documentCapture.deleteLocalFiles());
    }
    final selfieCapture = _lastSelfieCapture;
    if (selfieCapture != null) {
      unawaited(selfieCapture.deleteLocalFile());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hindatech KYC'),
        actions: [
          IconButton(
            tooltip: 'Capture test settings',
            onPressed: _openCaptureSettings,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Capture examples',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Validate the SDK camera flows on a physical Android or iOS device. '
            'The selfie entry uses an offline demo policy; production must pass '
            'the policy returned by the verification session.',
          ),
          const SizedBox(height: 24),
          _CaptureExampleCard(
            title: 'Document capture',
            description:
                'Photograph an identity document and receive a normalized image.',
            buttonLabel: 'Start document capture',
            icon: Icons.document_scanner_outlined,
            onPressed: _startDocumentCapture,
          ),
          if (_lastDocumentCapture != null) ...[
            const SizedBox(height: 12),
            _CaptureResultPanel(
              title: 'Latest document',
              path: _lastDocumentCapture!.normalizedPath,
              detail: _lastDocumentCapture!.usedGuideCropFallback
                  ? 'Captured using the guide frame.'
                  : 'Document bounds detected automatically.',
            ),
          ],
          const SizedBox(height: 20),
          _CaptureExampleCard(
            title: 'Selfie and liveness guidance',
            description:
                'Exercise face alignment, backend-policy challenges, and selfie capture.',
            buttonLabel: 'Start selfie capture',
            icon: Icons.face_outlined,
            onPressed: _startSelfieCapture,
          ),
          if (_lastSelfieCapture != null) ...[
            const SizedBox(height: 12),
            _CaptureResultPanel(
              title: 'Latest selfie',
              path: _lastSelfieCapture!.path,
              detail: 'Ready for upload to a session-declared asset slot.',
            ),
          ],
        ],
      ),
    );
  }
}

class SelfieCapturePage extends StatefulWidget {
  const SelfieCapturePage({
    required this.policy,
    required this.config,
    required this.showDiagnostics,
    super.key,
  });

  final VerificationLivenessPolicy policy;
  final SelfieCaptureConfig config;
  final bool showDiagnostics;

  @override
  State<SelfieCapturePage> createState() => _SelfieCapturePageState();
}

class _SelfieCapturePageState extends State<SelfieCapturePage> {
  final ValueNotifier<SelfieCaptureDiagnostics?> _diagnostics =
      ValueNotifier(null);

  @override
  void dispose() {
    _diagnostics.dispose();
    super.dispose();
  }

  void _showDiagnostics() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _SelfieDiagnosticsSheet(diagnostics: _diagnostics),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SelfieCaptureView(
            policy: widget.policy,
            routeObserver: exampleRouteObserver,
            config: widget.config,
            onDiagnosticsChanged: (value) => _diagnostics.value = value,
            onCompleted: (result) => Navigator.of(context).pop(result),
            onCancel: () => Navigator.of(context).pop(),
            onError: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selfie capture could not be completed.'),
                ),
              );
            },
          ),
          if (widget.showDiagnostics)
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton.filledTonal(
                  tooltip: 'Selfie diagnostics',
                  onPressed: _showDiagnostics,
                  icon: const Icon(Icons.monitor_heart_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Offline fixture for exercising the example camera UI only.
///
/// Production applications must pass `client.session.livenessPolicy` from the
/// NestJS bootstrap or recovery response instead of constructing this policy.
VerificationLivenessPolicy demoLivenessPolicy({bool randomize = true}) {
  return VerificationLivenessPolicy(
    version: 'demo-v1',
    modeValue: 'passive_with_active_guidance',
    decisionAuthorityValue: 'backend',
    activeGuidanceRoleValue: 'guidance_only',
    challengeCount: 2,
    allowedChallengeValues: const ['blink', 'turn_left', 'turn_right'],
    randomize: randomize,
    challengeTimeout: const Duration(seconds: 8),
    alignmentStabilityFrames: 5,
    requireSingleFace: true,
    requireNeutralPose: true,
    requireReturnToNeutral: true,
    temporalEvidenceSupported: false,
  );
}

class _CaptureExampleCard extends StatelessWidget {
  const _CaptureExampleCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 20),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

class _CaptureResultPanel extends StatelessWidget {
  const _CaptureResultPanel({
    required this.title,
    required this.path,
    required this.detail,
  });

  final String title;
  final String path;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(path),
            const SizedBox(height: 8),
            Text(detail),
          ],
        ),
      ),
    );
  }
}

class DocumentCapturePage extends StatefulWidget {
  const DocumentCapturePage({
    required this.config,
    required this.showDiagnostics,
    super.key,
  });

  final DocumentCaptureConfig config;
  final bool showDiagnostics;

  @override
  State<DocumentCapturePage> createState() => _DocumentCapturePageState();
}

class _DocumentCapturePageState extends State<DocumentCapturePage> {
  final StreamController<DocumentQualityAssessment> _qualityAssessments =
      StreamController.broadcast();

  @override
  void dispose() {
    unawaited(_qualityAssessments.close());
    super.dispose();
  }

  void _emitQuality(DocumentQualitySignal signal) {
    final assessment = DocumentQualityAssessment(
      signal: signal,
      confidence: signal == DocumentQualitySignal.unknown ? 0 : 0.95,
      source: DocumentQualitySource.heuristic,
    );
    for (var index = 0;
        index < widget.config.guidanceStabilityFrames;
        index++) {
      _qualityAssessments.add(assessment);
    }
  }

  void _showDiagnostics() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _DocumentDiagnosticsSheet(
        config: widget.config,
        onSignalSelected: (signal) {
          Navigator.of(context).pop();
          _emitQuality(signal);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DocumentCaptureView(
            config: widget.config,
            qualityAssessments:
                widget.showDiagnostics ? _qualityAssessments.stream : null,
            strings: const DocumentCaptureStrings(
              documentInstruction:
                  'Keep the document flat and place all four corners inside the frame.',
            ),
            onCompleted: (result) => Navigator.of(context).pop(result),
            onCancel: () => Navigator.of(context).pop(),
            onError: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document capture could not be completed.'),
                ),
              );
            },
          ),
          if (widget.showDiagnostics)
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton.filledTonal(
                  tooltip: 'Document diagnostics',
                  onPressed: _showDiagnostics,
                  icon: const Icon(Icons.science_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _CapturePreset { fast, balanced, highQuality }

class _ExampleCaptureSettings {
  const _ExampleCaptureSettings({
    this.documentPreset = _CapturePreset.highQuality,
    this.documentFrameProfile = DocumentFrameProfile.standard,
    this.documentAutoCapture = true,
    this.selfiePreset = _CapturePreset.balanced,
    this.randomizeChallenges = true,
    this.showDiagnostics = true,
  });

  final _CapturePreset documentPreset;
  final DocumentFrameProfile documentFrameProfile;
  final bool documentAutoCapture;
  final _CapturePreset selfiePreset;
  final bool randomizeChallenges;
  final bool showDiagnostics;

  DocumentCaptureConfig get documentConfig {
    final base = switch (documentPreset) {
      _CapturePreset.fast => const DocumentCaptureConfig.fast(),
      _CapturePreset.balanced => const DocumentCaptureConfig.balanced(),
      _CapturePreset.highQuality => const DocumentCaptureConfig.highQuality(),
    };
    return base.copyWith(
      frameProfile: documentFrameProfile,
      autoCaptureEnabled: documentAutoCapture,
    );
  }

  SelfieCaptureConfig get selfieConfig => switch (selfiePreset) {
        _CapturePreset.fast => const SelfieCaptureConfig.fast(),
        _CapturePreset.balanced => const SelfieCaptureConfig.balanced(),
        _CapturePreset.highQuality => const SelfieCaptureConfig.highQuality(),
      };
}

class _CaptureSettingsSheet extends StatefulWidget {
  const _CaptureSettingsSheet({required this.initial});

  final _ExampleCaptureSettings initial;

  @override
  State<_CaptureSettingsSheet> createState() => _CaptureSettingsSheetState();
}

class _CaptureSettingsSheetState extends State<_CaptureSettingsSheet> {
  late _CapturePreset _documentPreset = widget.initial.documentPreset;
  late DocumentFrameProfile _documentFrameProfile =
      widget.initial.documentFrameProfile;
  late bool _documentAutoCapture = widget.initial.documentAutoCapture;
  late _CapturePreset _selfiePreset = widget.initial.selfiePreset;
  late bool _randomizeChallenges = widget.initial.randomizeChallenges;
  late bool _showDiagnostics = widget.initial.showDiagnostics;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Capture test settings',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<_CapturePreset>(
              value: _documentPreset,
              decoration: const InputDecoration(labelText: 'Document preset'),
              items: _presetItems(),
              onChanged: (value) {
                if (value != null) setState(() => _documentPreset = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DocumentFrameProfile>(
              value: _documentFrameProfile,
              decoration:
                  const InputDecoration(labelText: 'Document frame profile'),
              items: DocumentFrameProfile.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _documentFrameProfile = value);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Document auto-capture'),
              subtitle: const Text('Requires a supplied quality signal.'),
              value: _documentAutoCapture,
              onChanged: (value) =>
                  setState(() => _documentAutoCapture = value),
            ),
            const Divider(),
            DropdownButtonFormField<_CapturePreset>(
              value: _selfiePreset,
              decoration: const InputDecoration(labelText: 'Selfie preset'),
              items: _presetItems(),
              onChanged: (value) {
                if (value != null) setState(() => _selfiePreset = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Randomize demo challenges'),
              value: _randomizeChallenges,
              onChanged: (value) =>
                  setState(() => _randomizeChallenges = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show diagnostic buttons'),
              subtitle: const Text('Example APK only.'),
              value: _showDiagnostics,
              onChanged: (value) => setState(() => _showDiagnostics = value),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _ExampleCaptureSettings(
                  documentPreset: _documentPreset,
                  documentFrameProfile: _documentFrameProfile,
                  documentAutoCapture: _documentAutoCapture,
                  selfiePreset: _selfiePreset,
                  randomizeChallenges: _randomizeChallenges,
                  showDiagnostics: _showDiagnostics,
                ),
              ),
              child: const Text('Apply settings'),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<_CapturePreset>> _presetItems() => _CapturePreset.values
      .map(
        (value) => DropdownMenuItem(
          value: value,
          child: Text(value.name),
        ),
      )
      .toList();
}

class _SelfieDiagnosticsSheet extends StatelessWidget {
  const _SelfieDiagnosticsSheet({required this.diagnostics});

  final ValueListenable<SelfieCaptureDiagnostics?> diagnostics;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ValueListenableBuilder<SelfieCaptureDiagnostics?>(
          valueListenable: diagnostics,
          builder: (context, value, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Selfie diagnostics',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (value == null)
                  const Text('No camera frame has completed analysis yet.')
                else ...[
                  Text('Detected faces: ${value.detectedFaceCount}'),
                  Text('Alignment: ${value.signal.name}'),
                  Text(
                    'Stable frames: ${value.consecutiveAlignedFrames}/${value.requiredAlignedFrames}',
                  ),
                  Text(
                    'Subject yaw: ${value.subjectYawDegrees?.toStringAsFixed(1) ?? 'unavailable'}',
                  ),
                  Text(
                    'Challenge: ${value.activeChallenge?.wireValue ?? 'not started'}',
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'These values describe local capture guidance only. The backend owns the liveness decision.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DocumentDiagnosticsSheet extends StatelessWidget {
  const _DocumentDiagnosticsSheet({
    required this.config,
    required this.onSignalSelected,
  });

  final DocumentCaptureConfig config;
  final ValueChanged<DocumentQualitySignal> onSignalSelected;

  @override
  Widget build(BuildContext context) {
    const signals = [
      DocumentQualitySignal.good,
      DocumentQualitySignal.blurry,
      DocumentQualitySignal.glare,
      DocumentQualitySignal.dark,
      DocumentQualitySignal.noDocument,
      DocumentQualitySignal.unknown,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Document diagnostics',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Resolution: ${config.resolution.name}'),
            Text('Frame profile: ${config.frameProfile.name}'),
            Text('Auto-capture: ${config.autoCaptureEnabled}'),
            const SizedBox(height: 12),
            const Text(
              'Simulate a quality observation to test guidance UI. This does not test a production quality model.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: signals
                  .map(
                    (signal) => ActionChip(
                      label: Text(signal.name),
                      onPressed: () => onSignalSelected(signal),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
