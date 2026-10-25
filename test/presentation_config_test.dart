import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  test('provides complete default document capture copy', () {
    const strings = HindatechKycStrings();
    expect(strings.documentTitle, isNotEmpty);
    expect(strings.cameraPermissionMessage, isNotEmpty);
    expect(strings.captureButton, isNotEmpty);
    expect(strings.continueButton, isNotEmpty);
  });

  test('accepts customer copy overrides', () {
    const strings = HindatechKycStrings(captureButton: 'Scan ID');
    expect(strings.captureButton, 'Scan ID');
  });

  test('applies SDK colors without replacing the host text theme', () {
    const sdkTheme = HindatechKycTheme(primaryColor: Colors.purple);
    final hostTheme = ThemeData.light().copyWith(
      textTheme: const TextTheme(titleLarge: TextStyle(fontSize: 30)),
    );
    final result = sdkTheme.applyTo(hostTheme);
    expect(result.colorScheme.primary, Colors.purple);
    expect(result.textTheme.titleLarge?.fontSize, 30);
  });

  test('SDK config carries presentation configuration', () {
    final config = HindatechKycConfig(
      apiBaseUri: Uri.parse('https://api.hindatech.com'),
      strings: const HindatechKycStrings(captureButton: 'Scan'),
      theme: const HindatechKycTheme(primaryColor: Colors.orange),
    );
    expect(config.strings.captureButton, 'Scan');
    expect(config.theme.primaryColor, Colors.orange);
  });
}
