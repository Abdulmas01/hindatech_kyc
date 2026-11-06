import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/core/serialization/json_fields.dart';

void main() {
  test('reads shared NestJS contract fields strictly', () {
    final json = <String, Object?>{
      'name': ' value ',
      'occurredAt': '2026-11-06T18:30:00.000Z',
      'values': ['one', 'two'],
      'nested': {'enabled': true},
    };

    expect(JsonFields.requiredString(json, 'name'), 'value');
    expect(
      JsonFields.requiredDateTime(json, 'occurredAt'),
      DateTime.utc(2026, 11, 6, 18, 30),
    );
    expect(JsonFields.requiredStringList(json, 'values'), ['one', 'two']);
    expect(JsonFields.requiredMap(json, 'nested'), {'enabled': true});
  });

  test('rejects invalid shared contract fields', () {
    expect(
      () => JsonFields.requiredString({'value': ' '}, 'value'),
      throwsFormatException,
    );
    expect(
      () => JsonFields.requiredDateTime({'value': 42}, 'value'),
      throwsFormatException,
    );
    expect(
      () => JsonFields.requiredStringList({
        'value': [1]
      }, 'value'),
      throwsFormatException,
    );
    expect(
      () => JsonFields.requiredMap({'value': []}, 'value'),
      throwsFormatException,
    );
  });
}
