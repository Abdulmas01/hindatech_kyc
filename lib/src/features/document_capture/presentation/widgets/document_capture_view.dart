import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/camera/camera_lifecycle_coordinator.dart';
import '../../../../core/camera/camera_permission_service.dart';
import '../../../../presentation/document_capture_strings.dart';
import '../../../../presentation/document_capture_theme.dart';
import '../../data/services/document_bounds_detector.dart';
import '../../data/services/document_camera_controller_factory.dart';
import '../../data/services/document_capture_service.dart';
import '../../domain/models/document_capture_config.dart';
import '../../domain/models/document_capture_result.dart';
import '../controllers/document_capture_notifier.dart';
import '../models/document_capture_state.dart';
import 'document_capture_overlay.dart';

class DocumentCaptureView extends StatelessWidget {
  const DocumentCaptureView({
    required this.onCompleted,
    super.key,
    this.onCancel,
    this.onError,
    this.config = const DocumentCaptureConfig.balanced(),
    this.strings = const DocumentCaptureStrings(),
    this.theme = const DocumentCaptureTheme(),
    @visibleForTesting this.autoInitialize = true,
  });

  final ValueChanged<DocumentCaptureResult> onCompleted;
  final VoidCallback? onCancel;
  final ValueChanged<Object>? onError;
  final DocumentCaptureConfig config;
  final DocumentCaptureStrings strings;
  final DocumentCaptureTheme theme;
  final bool autoInitialize;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _DocumentCaptureBody(
        onCompleted: onCompleted,
        onCancel: onCancel,
        onError: onError,
        config: config,
        strings: strings,
        captureTheme: theme,
        autoInitialize: autoInitialize,
      ),
    );
  }
}

class _DocumentCaptureBody extends ConsumerStatefulWidget {
  const _DocumentCaptureBody({
    required this.onCompleted,
    required this.config,
    required this.strings,
    required this.captureTheme,
    required this.autoInitialize,
    this.onCancel,
    this.onError,
  });

  final ValueChanged<DocumentCaptureResult> onCompleted;
  final VoidCallback? onCancel;
  final ValueChanged<Object>? onError;
  final DocumentCaptureConfig config;
  final DocumentCaptureStrings strings;
  final DocumentCaptureTheme captureTheme;
  final bool autoInitialize;

  @override
  ConsumerState<_DocumentCaptureBody> createState() =>
      _DocumentCaptureBodyState();
}

class _DocumentCaptureBodyState extends ConsumerState<_DocumentCaptureBody>
    with WidgetsBindingObserver {
  final CameraPermissionService _permissionService =
      const CameraPermissionService();
  final DocumentCameraControllerFactory _cameraFactory =
      const DocumentCameraControllerFactory();
  final DocumentCaptureService _captureService = const DocumentCaptureService();

  late final CameraLifecycleCoordinator _lifecycle;
  late final DocumentBoundsDetector _boundsDetector;
  CameraController? _controller;
  DocumentCaptureResult? _result;
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycle = CameraLifecycleCoordinator(onError: widget.onError);
    _boundsDetector = MlKitDocumentBoundsDetector();
    if (widget.autoInitialize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _lifecycle.isDisposed) return;
    if (state == AppLifecycleState.resumed) {
      _lifecycle.setActive(true);
      unawaited(_initialize());
      return;
    }
    _lifecycle.setActive(false);
    unawaited(_disposeCamera());
  }

  Future<void> _initialize() {
    final existing = _initialization;
    if (existing != null) return existing;
    late final Future<void> future;
    future = _initializeCamera().whenComplete(() {
      if (identical(_initialization, future)) _initialization = null;
    });
    _initialization = future;
    return future;
  }

  Future<void> _initializeCamera() async {
    final notifier = ref.read(documentCaptureProvider.notifier);
    notifier.reset();
    final permission = await _permissionService.request();
    if (!mounted) return;
    if (permission != CameraPermissionResult.granted) {
      notifier.setPermissionDenied(
        permanentlyDenied:
            permission == CameraPermissionResult.permanentlyDenied ||
                permission == CameraPermissionResult.restricted,
      );
      return;
    }

    try {
      await _disposeCamera();
      final controller = await _cameraFactory.create(widget.config);
      if (!mounted || !_lifecycle.isActive) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      notifier.setReady();
    } catch (error) {
      notifier.setCameraUnavailable(error);
      widget.onError?.call(error);
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final notifier = ref.read(documentCaptureProvider.notifier);
    notifier.setDetecting(true);
    try {
      final result = await _captureService.capture(
        controller: controller,
        boundsDetector: _boundsDetector,
        config: widget.config,
      );
      if (!mounted) return;
      setState(() => _result = result);
      notifier.setCaptured(result.normalizedPath);
    } catch (error) {
      if (!mounted) return;
      notifier.setFailure(error);
      widget.onError?.call(error);
    }
  }

  void _retake() {
    setState(() => _result = null);
    ref.read(documentCaptureProvider.notifier).clearCaptured();
  }

  Future<void> _disposeCamera() async {
    final controller = _controller;
    _controller = null;
    await _lifecycle.disposeController(controller);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.markDisposed();
    unawaited(_disposeCamera());
    unawaited(_boundsDetector.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentCaptureProvider);
    final theme = widget.captureTheme.applyTo(Theme.of(context));
    return Theme(
      data: theme,
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(widget.captureTheme.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.strings.documentTitle,
                    style: theme.textTheme.headlineSmall),
                SizedBox(height: widget.captureTheme.spacing / 2),
                Text(widget.strings.documentInstruction),
                SizedBox(height: widget.captureTheme.spacing),
                Expanded(child: _buildContent(state)),
                SizedBox(height: widget.captureTheme.spacing),
                _buildActions(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(DocumentCaptureState state) {
    switch (state.phase) {
      case DocumentCapturePhase.permissionDenied:
      case DocumentCapturePhase.permissionPermanentlyDenied:
        return _MessagePanel(
          title: widget.strings.cameraPermissionTitle,
          message:
              state.phase == DocumentCapturePhase.permissionPermanentlyDenied
                  ? widget.strings.cameraPermissionSettingsMessage
                  : widget.strings.cameraPermissionMessage,
          spacing: widget.captureTheme.spacing / 2,
        );
      case DocumentCapturePhase.cameraUnavailable:
        return _MessagePanel(
          title: widget.strings.cameraUnavailableTitle,
          message: widget.strings.cameraUnavailableMessage,
          spacing: widget.captureTheme.spacing / 2,
        );
      case DocumentCapturePhase.failed:
        return _MessagePanel(
          title: widget.strings.documentCaptureFailedTitle,
          message: widget.strings.documentCaptureFailedMessage,
          spacing: widget.captureTheme.spacing / 2,
        );
      case DocumentCapturePhase.captured:
        return ClipRRect(
          borderRadius:
              BorderRadius.circular(widget.captureTheme.controlRadius),
          child:
              Image.file(File(state.capturedPreviewPath!), fit: BoxFit.contain),
        );
      case DocumentCapturePhase.ready:
      case DocumentCapturePhase.detecting:
        final controller = _controller;
        if (controller == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ClipRRect(
          borderRadius:
              BorderRadius.circular(widget.captureTheme.controlRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              DocumentCaptureOverlay(
                config: widget.config,
                style: widget.captureTheme.overlayStyle,
              ),
            ],
          ),
        );
      case DocumentCapturePhase.initializing:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildActions(DocumentCaptureState state) {
    if (state.phase == DocumentCapturePhase.captured && _result != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _retake,
              child: Text(widget.strings.retakeButton),
            ),
          ),
          SizedBox(width: widget.captureTheme.spacing),
          Expanded(
            child: FilledButton(
              onPressed: () => widget.onCompleted(_result!),
              child: Text(widget.strings.continueButton),
            ),
          ),
        ],
      );
    }

    final permanentlyDenied =
        state.phase == DocumentCapturePhase.permissionPermanentlyDenied;
    final retryable = state.phase == DocumentCapturePhase.permissionDenied ||
        state.phase == DocumentCapturePhase.cameraUnavailable ||
        state.phase == DocumentCapturePhase.failed;
    return Row(
      children: [
        if (widget.onCancel != null)
          Expanded(
            child: TextButton(
              onPressed: widget.onCancel,
              child: Text(widget.strings.cancelButton),
            ),
          ),
        if (widget.onCancel != null)
          SizedBox(width: widget.captureTheme.spacing),
        Expanded(
          child: FilledButton(
            onPressed: state.canCapture
                ? _capture
                : permanentlyDenied
                    ? _permissionService.openSettings
                    : retryable
                        ? _initialize
                        : null,
            child: Text(
              permanentlyDenied
                  ? widget.strings.openSettingsButton
                  : retryable
                      ? widget.strings.retryButton
                      : widget.strings.captureButton,
            ),
          ),
        ),
      ],
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.message,
    required this.spacing,
  });

  final String title;
  final String message;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: spacing),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
