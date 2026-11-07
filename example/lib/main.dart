import 'dart:async';

import 'package:flutter/material.dart';
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

  Future<void> _startDocumentCapture() async {
    final result = await Navigator.of(context).push<DocumentCaptureResult>(
      MaterialPageRoute(builder: (_) => const DocumentCapturePage()),
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
          policy: demoLivenessPolicy(),
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
      appBar: AppBar(title: const Text('Hindatech KYC')),
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

class SelfieCapturePage extends StatelessWidget {
  const SelfieCapturePage({required this.policy, super.key});

  final VerificationLivenessPolicy policy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SelfieCaptureView(
        policy: policy,
        routeObserver: exampleRouteObserver,
        config: const SelfieCaptureConfig.balanced(),
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
    );
  }
}

/// Offline fixture for exercising the example camera UI only.
///
/// Production applications must pass `client.session.livenessPolicy` from the
/// NestJS bootstrap or recovery response instead of constructing this policy.
VerificationLivenessPolicy demoLivenessPolicy() {
  return VerificationLivenessPolicy(
    version: 'demo-v1',
    modeValue: 'passive_with_active_guidance',
    decisionAuthorityValue: 'backend',
    activeGuidanceRoleValue: 'guidance_only',
    challengeCount: 2,
    allowedChallengeValues: const ['blink', 'turn_left', 'turn_right'],
    randomize: true,
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

class DocumentCapturePage extends StatelessWidget {
  const DocumentCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DocumentCaptureView(
        config: const DocumentCaptureConfig.highQuality(),
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
    );
  }
}
