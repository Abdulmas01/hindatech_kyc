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
import '../../domain/models/document_quality_assessment.dart';
import '../../domain/services/document_quality_guidance_service.dart';
import '../controllers/document_capture_notifier.dart';
import '../models/document_capture_state.dart';
import 'document_capture_overlay.dart';
import 'document_quality_guidance_banner.dart';

class DocumentCaptureView extends StatelessWidget {
  const DocumentCaptureView({
    required this.onCompleted,
    super.key,
    this.onCancel,
    this.onError,
    this.onQualityError,
    this.qualityAssessments,
    this.config = const DocumentCaptureConfig.balanced(),
    this.strings = const DocumentCaptureStrings(),
    this.theme = const DocumentCaptureTheme(),
    @visibleForTesting this.autoInitialize = true,
  });

  /// Transfers ownership of the captured local files to the application.
  ///
  /// The application should call [DocumentCaptureResult.deleteLocalFiles]
  /// after it finishes uploading or otherwise processing the result.
  final ValueChanged<DocumentCaptureResult> onCompleted;
  final VoidCallback? onCancel;
  final ValueChanged<Object>? onError;

  /// Receives non-blocking failures from a customer-supplied quality stream.
  final ValueChanged<Object>? onQualityError;

  /// Optional device-local quality observations supplied by the host app.
  ///
  /// These observations affect capture guidance and optional auto-capture only.
  /// They never determine the verification result.
  final Stream<DocumentQualityAssessment>? qualityAssessments;
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
        onQualityError: onQualityError,
        qualityAssessments: qualityAssessments,
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
    this.onQualityError,
    this.qualityAssessments,
  });

  final ValueChanged<DocumentCaptureResult> onCompleted;
  final VoidCallback? onCancel;
  final ValueChanged<Object>? onError;
  final ValueChanged<Object>? onQualityError;
  final Stream<DocumentQualityAssessment>? qualityAssessments;
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
  bool _resultOwnershipTransferred = false;
  Future<void>? _initialization;
  final DocumentQualityGuidanceService _qualityGuidance =
      DocumentQualityGuidanceService();
  StreamSubscription<DocumentQualityAssessment>? _qualitySubscription;
  Timer? _autoCaptureTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycle = CameraLifecycleCoordinator(onError: widget.onError);
    _boundsDetector = MlKitDocumentBoundsDetector();
    _subscribeToQualityAssessments();
    if (widget.autoInitialize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
    }
  }

  @override
  void didUpdateWidget(covariant _DocumentCaptureBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.qualityAssessments, widget.qualityAssessments) ||
        !identical(oldWidget.config, widget.config)) {
      _subscribeToQualityAssessments();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _lifecycle.isDisposed) return;
    if (state == AppLifecycleState.resumed) {
      _lifecycle.setAppActive(true);
      unawaited(_initialize());
      return;
    }
    _lifecycle.setAppActive(false);
    _cancelAutoCapture();
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
    final notifier = ref.read(documentCaptureProvider.notifier);
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      notifier.setAutoCapturing(false);
      return;
    }
    _cancelAutoCapture();
    notifier.setDetecting(true);
    try {
      final result = await _captureService.capture(
        controller: controller,
        boundsDetector: _boundsDetector,
        config: widget.config,
      );
      if (!mounted) {
        await result.deleteLocalFiles();
        return;
      }
      setState(() {
        _result = result;
        _resultOwnershipTransferred = false;
      });
      notifier.setCaptured(result.normalizedPath);
    } catch (error) {
      if (!mounted) return;
      notifier.setFailure(error);
      widget.onError?.call(error);
    }
  }

  void _retake() {
    final discardedResult = _result;
    final shouldDelete = !_resultOwnershipTransferred;
    _qualityGuidance.reset();
    _cancelAutoCapture();
    setState(() {
      _result = null;
      _resultOwnershipTransferred = false;
    });
    if (shouldDelete && discardedResult != null) {
      unawaited(_deleteResult(discardedResult, reportError: true));
    }
    ref.read(documentCaptureProvider.notifier).clearCaptured();
  }

  void _completeCapture() {
    final result = _result;
    if (result == null || _resultOwnershipTransferred) return;
    setState(() => _resultOwnershipTransferred = true);
    widget.onCompleted(result);
  }

  Future<void> _deleteResult(
    DocumentCaptureResult result, {
    required bool reportError,
  }) async {
    try {
      await result.deleteLocalFiles();
    } catch (error) {
      if (reportError && mounted) widget.onError?.call(error);
    }
  }

  void _subscribeToQualityAssessments() {
    unawaited(_qualitySubscription?.cancel());
    _qualitySubscription = null;
    _qualityGuidance.reset();
    _cancelAutoCapture();

    if (widget.config.qualityGuidanceMode ==
            DocumentQualityGuidanceMode.disabled ||
        widget.qualityAssessments == null) {
      return;
    }

    _qualitySubscription = widget.qualityAssessments!.listen(
      _handleQualityAssessment,
      onError: (Object error, StackTrace stackTrace) {
        _cancelAutoCapture();
        widget.onQualityError?.call(error);
      },
    );
  }

  void _handleQualityAssessment(DocumentQualityAssessment assessment) {
    if (!mounted ||
        widget.config.qualityGuidanceMode ==
            DocumentQualityGuidanceMode.disabled) {
      return;
    }

    final guidance = _qualityGuidance.evaluate(
      assessment: assessment,
      stabilityFrames: widget.config.guidanceStabilityFrames,
    );
    ref.read(documentCaptureProvider.notifier).updateQuality(guidance);
    _syncAutoCapture(guidance);
  }

  void _syncAutoCapture(DocumentQualityGuidance guidance) {
    final state = ref.read(documentCaptureProvider);
    if (!widget.config.autoCaptureEnabled ||
        !guidance.suggestsCaptureReady ||
        !state.canCapture) {
      _cancelAutoCapture();
      return;
    }
    if (_autoCaptureTimer?.isActive ?? false) return;

    _autoCaptureTimer = Timer(widget.config.autoCaptureHoldDuration, () {
      if (!mounted) return;
      final current = ref.read(documentCaptureProvider);
      if (!widget.config.autoCaptureEnabled ||
          !current.canCapture ||
          !current.suggestsCaptureReady) {
        return;
      }
      ref.read(documentCaptureProvider.notifier).setAutoCapturing(true);
      unawaited(_capture());
    });
  }

  void _cancelAutoCapture() {
    _autoCaptureTimer?.cancel();
    _autoCaptureTimer = null;
  }

  Future<void> _disposeCamera() async {
    final controller = _controller;
    _controller = null;
    await _lifecycle.disposeController(controller);
  }

  @override
  void dispose() {
    final abandonedResult = _result;
    if (!_resultOwnershipTransferred && abandonedResult != null) {
      unawaited(_deleteResult(abandonedResult, reportError: false));
    }
    WidgetsBinding.instance.removeObserver(this);
    _cancelAutoCapture();
    unawaited(_qualitySubscription?.cancel());
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
              if (widget.config.qualityGuidanceMode ==
                      DocumentQualityGuidanceMode.advisory &&
                  state.qualityConfidence > 0)
                Positioned(
                  left: widget.captureTheme.spacing,
                  right: widget.captureTheme.spacing,
                  bottom: widget.captureTheme.spacing,
                  child: DocumentQualityGuidanceBanner(
                    signal: state.qualitySignal,
                    isStable: state.isQualityStable,
                    strings: widget.strings,
                    captureTheme: widget.captureTheme,
                  ),
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
              onPressed: _resultOwnershipTransferred ? null : _completeCapture,
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
            onPressed: state.canCapture && !state.isAutoCapturing
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
                      : state.isAutoCapturing
                          ? widget.strings.autoCapturingButton
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
