import 'package:flutter/material.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() => runApp(const ExampleApp());

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
  DocumentCaptureResult? _lastCapture;

  Future<void> _startCapture() async {
    final result = await Navigator.of(context).push<DocumentCaptureResult>(
      MaterialPageRoute(builder: (_) => const DocumentCapturePage()),
    );
    if (result != null && mounted) {
      setState(() => _lastCapture = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hindatech KYC')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Document capture example',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Launch the SDK capture screen, photograph an identity document, '
              'and receive a normalized image ready for the next verification step.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startCapture,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Start document capture'),
            ),
            if (_lastCapture != null) ...[
              const SizedBox(height: 32),
              Text(
                'Latest capture',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(_lastCapture!.normalizedPath),
              const SizedBox(height: 8),
              Text(
                _lastCapture!.usedGuideCropFallback
                    ? 'Captured using the guide frame.'
                    : 'Document bounds detected automatically.',
              ),
            ],
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
