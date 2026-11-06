import 'dart:async';

typedef PollingLoad<T> = Future<T> Function();
typedef PollingContinuation<T> = bool Function(T value);

/// Internal configuration for one sequential polling operation.
class PollingTask<T> {
  const PollingTask({
    required this.load,
    required this.shouldContinue,
    required this.interval,
    this.timeout,
  });

  final PollingLoad<T> load;
  final PollingContinuation<T> shouldContinue;
  final Duration interval;
  final Duration? timeout;
}

/// Runs cancellable polling without overlapping requests.
abstract final class PollingRunner {
  static Stream<T> run<T>(PollingTask<T> task) {
    late final StreamController<T> controller;
    Timer? timer;
    var cancelled = false;
    final elapsed = Stopwatch();

    Future<void> closeWithError(Object error, StackTrace stackTrace) async {
      if (cancelled || controller.isClosed) return;
      controller.addError(error, stackTrace);
      await controller.close();
    }

    Future<void> poll() async {
      if (cancelled || controller.isClosed) return;
      final timeout = task.timeout;
      if (timeout != null && elapsed.elapsed >= timeout) {
        await closeWithError(
          TimeoutException('The polling operation timed out.', timeout),
          StackTrace.current,
        );
        return;
      }

      try {
        final value = await task.load();
        if (cancelled || controller.isClosed) return;
        if (timeout != null && elapsed.elapsed >= timeout) {
          await closeWithError(
            TimeoutException('The polling operation timed out.', timeout),
            StackTrace.current,
          );
          return;
        }
        controller.add(value);
        if (!task.shouldContinue(value)) {
          await controller.close();
          return;
        }

        var delay = task.interval;
        if (timeout != null) {
          final remaining = timeout - elapsed.elapsed;
          if (remaining < delay) delay = remaining;
        }
        timer = Timer(delay.isNegative ? Duration.zero : delay, poll);
      } catch (error, stackTrace) {
        await closeWithError(error, stackTrace);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        elapsed.start();
        unawaited(poll());
      },
      onCancel: () {
        cancelled = true;
        timer?.cancel();
        elapsed.stop();
      },
    );
    return controller.stream;
  }
}
