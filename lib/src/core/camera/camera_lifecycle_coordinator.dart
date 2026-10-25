import 'package:camera/camera.dart';

typedef CameraLifecycleErrorHandler = void Function(Object error);

class CameraLifecycleCoordinator {
  CameraLifecycleCoordinator({this.onError});

  final CameraLifecycleErrorHandler? onError;

  Future<void> _transitionFuture = Future.value();
  Future<void>? _disposeFuture;
  bool _isStreaming = false;
  bool _isActive = true;
  bool _isDisposed = false;

  bool get isStreaming => _isStreaming;
  bool get isActive => _isActive;
  bool get isDisposed => _isDisposed;

  void setActive(bool value) {
    if (_isDisposed) return;
    _isActive = value;
  }

  void markDisposed() {
    _isDisposed = true;
    _isActive = false;
  }

  Future<void> queueTransition(Future<void> Function() operation) {
    final next = _transitionFuture.catchError((_) {}).then((_) async {
      if (_isDisposed) return;
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
      if (!_isActive || controller == null) return;
      if (controller.value.isStreamingImages) {
        _isStreaming = true;
        return;
      }
      if (_isStreaming) return;
      await controller.startImageStream(onImage);
      _isStreaming = true;
    });
  }

  Future<void> stopImageStream(CameraController? controller) {
    return queueTransition(() => _stopImageStream(controller));
  }

  Future<void> _stopImageStream(CameraController? controller) async {
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
    future = _disposeController(controller).whenComplete(() {
      if (identical(_disposeFuture, future)) {
        _disposeFuture = null;
      }
    });
    _disposeFuture = future;
    return future;
  }

  Future<void> _disposeController(CameraController? controller) async {
    _isStreaming = false;
    if (controller == null) return;
    await _stopImageStream(controller);
    try {
      await controller.dispose();
    } catch (error) {
      onError?.call(error);
    }
  }
}
