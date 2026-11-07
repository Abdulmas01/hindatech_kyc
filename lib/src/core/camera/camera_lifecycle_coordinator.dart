import 'package:camera/camera.dart';

typedef CameraLifecycleErrorHandler = void Function(Object error);

class CameraLifecycleCoordinator {
  CameraLifecycleCoordinator({this.onError});

  final CameraLifecycleErrorHandler? onError;

  Future<void> _transitionFuture = Future.value();
  Future<void>? _disposeFuture;
  bool _isStreaming = false;
  bool _isRouteActive = true;
  bool _isAppActive = true;
  bool _isDisposed = false;

  bool get isStreaming => _isStreaming;
  bool get isRouteActive => _isRouteActive;
  bool get isAppActive => _isAppActive;
  bool get isActive => _isRouteActive && _isAppActive && !_isDisposed;
  bool get isDisposed => _isDisposed;

  void setRouteActive(bool value) {
    if (_isDisposed) return;
    _isRouteActive = value;
  }

  void setAppActive(bool value) {
    if (_isDisposed) return;
    _isAppActive = value;
  }

  void markDisposed() {
    _isDisposed = true;
    _isRouteActive = false;
    _isAppActive = false;
  }

  void syncStreamingFromController(CameraController? controller) {
    _isStreaming = controller?.value.isStreamingImages ?? false;
  }

  Future<void> queueTransition(Future<void> Function() operation) {
    return _enqueueTransition(operation, runWhenDisposed: false);
  }

  Future<void> _enqueueTransition(
    Future<void> Function() operation, {
    required bool runWhenDisposed,
  }) {
    final next = _transitionFuture.catchError((_) {}).then((_) async {
      if (_isDisposed && !runWhenDisposed) return;
      await operation();
    });
    _transitionFuture = next;
    return next;
  }

  Future<void> startImageStream({
    required CameraController? controller,
    required void Function(CameraImage image) onImage,
  }) {
    return queueTransition(() async {
      await startImageStreamImmediate(controller: controller, onImage: onImage);
    });
  }

  Future<void> startImageStreamImmediate({
    required CameraController? controller,
    required void Function(CameraImage image) onImage,
  }) async {
    if (!isActive || controller == null) return;
    if (controller.value.isStreamingImages) {
      _isStreaming = true;
      return;
    }
    if (_isStreaming) return;
    await controller.startImageStream(onImage);
    _isStreaming = true;
  }

  Future<void> stopImageStream(CameraController? controller) {
    return queueTransition(() => stopImageStreamImmediate(controller));
  }

  Future<void> stopImageStreamImmediate(CameraController? controller) async {
    if (controller == null) {
      _isStreaming = false;
      return;
    }
    if (!(controller.value.isStreamingImages || _isStreaming)) {
      _isStreaming = false;
      return;
    }
    try {
      await controller.stopImageStream();
    } catch (error) {
      onError?.call(error);
    }
    _isStreaming = false;
  }

  Future<void> disposeController(CameraController? controller) {
    final existing = _disposeFuture;
    if (existing != null) return existing;

    late final Future<void> future;
    future = _enqueueTransition(
      () => _disposeController(controller),
      runWhenDisposed: true,
    ).whenComplete(() {
      if (identical(_disposeFuture, future)) {
        _disposeFuture = null;
      }
    });
    _disposeFuture = future;
    return future;
  }

  Future<void> _disposeController(CameraController? controller) async {
    if (controller == null) {
      _isStreaming = false;
      return;
    }
    await stopImageStreamImmediate(controller);
    try {
      await controller.dispose();
    } catch (error) {
      onError?.call(error);
    }
    _isStreaming = false;
  }
}
