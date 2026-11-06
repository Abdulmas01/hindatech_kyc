import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/core/async/polling_runner.dart';

void main() {
  test('polls sequentially and stops when the task is complete', () async {
    var value = 0;
    var activeRequests = 0;
    var maximumActiveRequests = 0;

    final values = await PollingRunner.run(
      PollingTask<int>(
        load: () async {
          activeRequests++;
          if (activeRequests > maximumActiveRequests) {
            maximumActiveRequests = activeRequests;
          }
          await Future<void>.delayed(const Duration(milliseconds: 1));
          activeRequests--;
          return ++value;
        },
        shouldContinue: (value) => value < 3,
        interval: const Duration(milliseconds: 1),
      ),
    ).toList();

    expect(values, [1, 2, 3]);
    expect(maximumActiveRequests, 1);
  });

  test('closes with a timeout when work never completes', () async {
    final stream = PollingRunner.run(
      PollingTask<int>(
        load: () async => 1,
        shouldContinue: (_) => true,
        interval: const Duration(milliseconds: 50),
        timeout: const Duration(milliseconds: 20),
      ),
    );

    await expectLater(
        stream, emitsInOrder([1, emitsError(isA<TimeoutException>())]));
  });

  test('does not emit a request that completes after the timeout', () async {
    final stream = PollingRunner.run(
      PollingTask<int>(
        load: () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return 1;
        },
        shouldContinue: (_) => true,
        interval: const Duration(milliseconds: 1),
        timeout: const Duration(milliseconds: 1),
      ),
    );

    await expectLater(stream, emitsError(isA<TimeoutException>()));
  });

  test('cancellation prevents another request', () async {
    var requestCount = 0;
    final stream = PollingRunner.run(
      PollingTask<int>(
        load: () async => ++requestCount,
        shouldContinue: (_) => true,
        interval: const Duration(seconds: 1),
      ),
    );
    late final StreamSubscription<int> subscription;
    subscription = stream.listen((_) {
      unawaited(subscription.cancel());
    });

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(requestCount, 1);
  });
}
