import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc_example/main.dart';

void main() {
  testWidgets('shows document and selfie capture entry points', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Capture examples'), findsOneWidget);
    expect(find.text('Start document capture'), findsOneWidget);
    expect(find.text('Start selfie capture'), findsOneWidget);
    expect(find.byTooltip('Capture test settings'), findsOneWidget);
  });

  test('demo policy remains backend-authoritative guidance only', () {
    final policy = demoLivenessPolicy(randomize: false);

    expect(policy.isBackendAuthoritative, isTrue);
    expect(policy.isGuidanceOnly, isTrue);
    expect(policy.temporalEvidenceSupported, isFalse);
    expect(policy.randomize, isFalse);
  });
}
