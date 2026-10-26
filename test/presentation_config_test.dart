import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  test('provides complete default document capture copy', () {
    const strings = DocumentCaptureStrings();
    expect(strings.documentTitle, isNotEmpty);
    expect(strings.cameraPermissionMessage, isNotEmpty);
    expect(strings.captureButton, isNotEmpty);
    expect(strings.continueButton, isNotEmpty);
  });

  test('accepts customer copy overrides', () {
    const strings = DocumentCaptureStrings(captureButton: 'Scan ID');
    expect(strings.captureButton, 'Scan ID');
  });

  test('applies SDK colors without replacing the host text theme', () {
    const captureTheme = DocumentCaptureTheme(primaryColor: Colors.purple);
    final hostTheme = ThemeData.light().copyWith(
      textTheme: const TextTheme(titleLarge: TextStyle(fontSize: 30)),
    );
    final result = captureTheme.applyTo(hostTheme);
    expect(result.colorScheme.primary, Colors.purple);
    expect(result.textTheme.titleLarge?.fontSize, 30);
  });

  test('SDK config carries presentation configuration', () {
    final config = KycConfig(
      apiBaseUri: Uri.parse('https://api.hindatech.com'),
      strings: const DocumentCaptureStrings(captureButton: 'Scan'),
      theme: const DocumentCaptureTheme(primaryColor: Colors.orange),
    );
    expect(config.strings.captureButton, 'Scan');
    expect(config.theme.primaryColor, Colors.orange);
  });
}
