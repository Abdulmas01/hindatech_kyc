import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc_example/main.dart';

void main() {
  testWidgets('shows the document capture entry point', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Document capture example'), findsOneWidget);
    expect(find.text('Start document capture'), findsOneWidget);
  });
}
