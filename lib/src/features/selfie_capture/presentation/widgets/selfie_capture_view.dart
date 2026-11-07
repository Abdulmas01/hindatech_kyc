import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/camera/camera_lifecycle_coordinator.dart';
import '../../../../core/camera/camera_permission_service.dart';
import '../../../../presentation/selfie_capture_strings.dart';
import '../../../../presentation/selfie_capture_theme.dart';
import '../../../../session/verification_liveness_policy.dart';
import '../../data/models/selfie_frame_models.dart';
import '../../data/services/selfie_camera_controller_factory.dart';
import '../../data/services/selfie_frame_analysis_service.dart';
import '../../domain/models/active_guidance.dart';
import '../../domain/models/face_alignment.dart';
import '../../domain/models/face_guide_config.dart';
import '../../domain/models/selfie_capture_config.dart';
import '../../domain/models/selfie_capture_result.dart';
import '../../domain/services/active_guidance_service.dart';
import '../controllers/selfie_capture_notifier.dart';
import '../controllers/selfie_capture_runtime_controller.dart';
import '../controllers/selfie_frame_processor.dart';
import '../models/selfie_capture_state.dart';
import 'selfie_capture_overlay.dart';

class SelfieCaptureView extends StatelessWidget {
  const SelfieCaptureView({
    required this.policy,
    required this.onCompleted,
    super.key,
    this.onCancel,
    this.onError,
    this.config = const SelfieCaptureConfig.balanced(),
    this.guideConfig = const FaceGuideConfig(),
    this.strings = const SelfieCaptureStrings(),
    this.theme = const SelfieCaptureTheme(),
    this.routeObserver,
    @visibleForTesting this.autoInitialize = true,
  });

  /// Backend-owned liveness capture policy for the current session.
  final VerificationLivenessPolicy policy;

  /// Transfers ownership of the captured local file to the application.
  ///
  /// The application should call [SelfieCaptureResult.deleteLocalFile] after
  /// it finishes uploading or otherwise processing the result.
  final ValueChanged<SelfieCaptureResult> onCompleted;
  final VoidCallback? onCancel;
  final ValueChanged<Object>? onError;
  final SelfieCaptureConfig config;
  final FaceGuideConfig guideConfig;
  final SelfieCaptureStrings strings;
  final SelfieCaptureTheme theme;

  /// Optional observer registered on the host Navigator.
  ///
  /// Supplying it lets the SDK stop analysis as soon as another route covers
  /// this view and resume without restarting the camera when appropriate.
  final RouteObserver<ModalRoute<dynamic>>? routeObserver;
  final bool autoInitialize;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _SelfieCaptureBody(
        policy: policy,
        onCompleted: onCompleted,
        onCancel: onCancel,
        onError: onError,
        config: config,
        guideConfig: guideConfig,
        strings: strings,
        captureTheme: theme,
        routeObserver: routeObserver,
        autoInitialize: autoInitialize,
      ),
    );
  }
}

class _SelfieCaptureBody extends ConsumerStatefulWidget {
  const _SelfieCaptureBody({
    required this.policy,
    required this.onCompleted,
    required this.config,
    required this.guideConfig,
    required this.strings,
    required this.captureTheme,
    required this.autoInitialize,
    this.onCancel,
    this.onError,
    this.routeObserver,
  });

  final VerificationLivenessPolicy policy;
  final ValueChanged<SelfieCaptureResult> onCompleted;
  final VoidCallback? onCancel;
  final ValueChanged<Object>? onError;
  final SelfieCaptureConfig config;
  final FaceGuideConfig guideConfig;
  final SelfieCaptureStrings strings;
  final SelfieCaptureTheme captureTheme;
  final RouteObserver<ModalRoute<dynamic>>? routeObserver;
  final bool autoInitialize;

  @override
  ConsumerState<_SelfieCaptureBody> createState() => _SelfieCaptureBodyState();
}

class _SelfieCaptureBodyState extends ConsumerState<_SelfieCaptureBody>
    with WidgetsBindingObserver, RouteAware {
  final CameraPermissionService _permissionService =
      const CameraPermissionService();
  final SelfieCameraControllerFactory _cameraFactory =
      SelfieCameraControllerFactory();

  late final CameraLifecycleCoordinator _lifecycle;
  late final SelfieFrameAnalysisService _analysisService;
  late final SelfieCaptureRuntimeController _runtime;
  late final SelfieFrameProcessor _frameProcessor;
  CameraController? _controller;
  SelfieCaptureResult? _result;
  bool _resultOwnershipTransferred = false;
  Future<void>? _initialization;
  Timer? _slowStartupTimer;
  Timer? _deadlineTimer;
  Size? _viewportSize;
  Rect? _guideRect;
  bool _isAppActive = true;
  bool _isRouteActive = true;
  ModalRoute<dynamic>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycle = CameraLifecycleCoordinator(onError: widget.onError);
    _analysisService = SelfieFrameAnalysisService();
    _runtime = SelfieCaptureRuntimeController(config: widget.config);
    _frameProcessor = SelfieFrameProcessor(
      config: SelfieFrameProcessorConfig(
        runtime: _runtime,
        guidance: ActiveGuidanceService(
          config: ActiveGuidanceConfig(policy: widget.policy),
        ),
      ),
    );
    _deadlineTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _checkGuidanceDeadline(),
    );
    if (widget.autoInitialize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToRoute();
    final isCurrent = ModalRoute.isCurrentOf(context);
    if (isCurrent != null && isCurrent != _isRouteActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setRouteActive(isCurrent);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _SelfieCaptureBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.routeObserver, widget.routeObserver)) {
      oldWidget.routeObserver?.unsubscribe(this);
      _subscribedRoute = null;
      _subscribeToRoute();
    }
  }

  void _subscribeToRoute() {
    final observer = widget.routeObserver;
    final route = ModalRoute.of(context);
    if (observer == null ||
        route == null ||
        identical(route, _subscribedRoute)) {
      return;
    }
    observer.subscribe(this, route);
    _subscribedRoute = route;
  }

  @override
  void didPush() => _setRouteActive(true);

  @override
  void didPopNext() => _setRouteActive(true);

  @override
  void didPushNext() => _setRouteActive(false);

  @override
  void didPop() => _setRouteActive(false);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _lifecycle.isDisposed) return;
    final active = state == AppLifecycleState.resumed;
    if (_isAppActive == active) return;
    _isAppActive = active;
    _lifecycle.setAppActive(active);
    _syncRuntimeActivity();
    if (!active) {
      _cancelSlowStartupTimer();
      ref.read(selfieCaptureProvider.notifier).setPaused();
      unawaited(_disposeCamera());
    } else if (_isRouteActive) {
      unawaited(_resumeCamera());
    }
  }

  void _setRouteActive(bool active) {
    if (!mounted || _lifecycle.isDisposed || _isRouteActive == active) return;
    _isRouteActive = active;
    _lifecycle.setRouteActive(active);
    _syncRuntimeActivity();
    if (!active) {
      _cancelSlowStartupTimer();
      ref.read(selfieCaptureProvider.notifier).setPaused();
      if (widget.config.routeInactivityHandling ==
          SelfieRouteInactivityHandling.disposeController) {
        unawaited(_disposeCamera());
      } else {
        unawaited(_lifecycle.stopImageStream(_controller));
      }
    } else if (_isAppActive) {
      unawaited(_resumeCamera());
    }
  }

  void _syncRuntimeActivity() {
    _frameProcessor.updateActivity(
      SelfieRuntimeActivity(
        routeActive: _isRouteActive,
        appActive: _isAppActive,
      ),
    );
  }

  Future<void> _resumeCamera() async {
    if (!widget.autoInitialize) return;
    if (_controller == null) {
      await _initialize();
      return;
    }
    ref.read(selfieCaptureProvider.notifier).setReady();
    await _startImageStream();
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
    if (!_lifecycle.isActive) return;
    final notifier = ref.read(selfieCaptureProvider.notifier);
    notifier.beginInitialization(SelfieCameraStartupStage.requestingPermission);
    _startSlowStartupTimer();

    final permission = await _permissionService.request();
    if (!mounted || !_lifecycle.isActive) return;
    if (permission != CameraPermissionResult.granted) {
      _cancelSlowStartupTimer();
      notifier.setPermissionDenied(
        permanentlyDenied:
            permission == CameraPermissionResult.permanentlyDenied ||
                permission == CameraPermissionResult.restricted,
      );
      return;
    }

    try {
      notifier.setStartupStage(SelfieCameraStartupStage.discoveringCamera);
      await _cameraFactory.selectCamera();
      if (!mounted || !_lifecycle.isActive) return;

      notifier.setStartupStage(SelfieCameraStartupStage.initializingController);
      await _disposeCamera();
      final controller = await _cameraFactory.create(widget.config);
      if (!mounted || !_lifecycle.isActive) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      notifier.setStartupStage(SelfieCameraStartupStage.startingStream);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_lifecycle.isActive) return;
      await _startImageStream();
      _cancelSlowStartupTimer();
      notifier.setReady();
    } catch (error) {
      _cancelSlowStartupTimer();
      if (!mounted || !_lifecycle.isActive) return;
      notifier.setCameraUnavailable(error);
      widget.onError?.call(error);
    }
  }

  void _startSlowStartupTimer() {
    _cancelSlowStartupTimer();
    _slowStartupTimer = Timer(widget.config.slowStartupThreshold, () {
      if (mounted) ref.read(selfieCaptureProvider.notifier).markSlowStartup();
    });
  }

  void _cancelSlowStartupTimer() {
    _slowStartupTimer?.cancel();
    _slowStartupTimer = null;
  }

  Future<void> _startImageStream() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _viewportSize == null ||
        _guideRect == null) {
      return;
    }
    await _lifecycle.startImageStream(
      controller: controller,
      onImage: _handleCameraImage,
    );
  }

  void _handleCameraImage(CameraImage image) {
    final controller = _controller;
    final viewportSize = _viewportSize;
    final guideRect = _guideRect;
    if (controller == null || viewportSize == null || guideRect == null) return;

    unawaited(
      _frameProcessor
          .process(
        () => _analysisService.analyze(
          SelfieFrameAnalysisRequest(
            controller: controller,
            image: image,
            viewportSize: viewportSize,
            guideRect: guideRect,
            policy: widget.policy,
          ),
        ),
      )
          .then((result) {
        if (!mounted || result == null) return;
        ref
            .read(selfieCaptureProvider.notifier)
            .updateGuidance(result.guidance);
      }).catchError((Object error, StackTrace stackTrace) {
        if (mounted) widget.onError?.call(error);
      }),
    );
  }

  void _checkGuidanceDeadline() {
    if (!mounted || !_isAppActive || !_isRouteActive) return;
    final guidance = _frameProcessor.checkTimeout();
    if (guidance.hasTimedOut) {
      ref.read(selfieCaptureProvider.notifier).updateGuidance(guidance);
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    final ticket = _runtime.tryBeginCapture();
    if (controller == null || ticket == null) return;
    final notifier = ref.read(selfieCaptureProvider.notifier);
    notifier.setCapturing();
    try {
      await _lifecycle.stopImageStream(controller);
      final file = await controller.takePicture();
      final result = SelfieCaptureResult(path: file.path);
      if (!mounted) {
        await result.deleteLocalFile();
        return;
      }
      _runtime.finishCapture(ticket);
      setState(() {
        _result = result;
        _resultOwnershipTransferred = false;
      });
      notifier.setCaptured();
    } catch (error) {
      _runtime.finishCapture(ticket);
      if (!mounted) return;
      notifier.setFailure(error);
      widget.onError?.call(error);
      await _startImageStream();
    }
  }

  void _retryGuidance() {
    _analysisService.reset();
    _frameProcessor.restart();
    ref.read(selfieCaptureProvider.notifier).setReady();
    unawaited(_startImageStream());
  }

  void _retake() {
    final result = _result;
    final shouldDelete = !_resultOwnershipTransferred;
    setState(() {
      _result = null;
      _resultOwnershipTransferred = false;
    });
    if (shouldDelete && result != null) {
      unawaited(_deleteResult(result, reportError: true));
    }
    _retryGuidance();
  }

  void _completeCapture() {
    final result = _result;
    if (result == null || _resultOwnershipTransferred) return;
    setState(() => _resultOwnershipTransferred = true);
    widget.onCompleted(result);
  }

  Future<void> _deleteResult(
    SelfieCaptureResult result, {
    required bool reportError,
  }) async {
    try {
      await result.deleteLocalFile();
    } catch (error) {
      if (reportError && mounted) widget.onError?.call(error);
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _controller = null);
    await _lifecycle.disposeController(controller);
  }

  @override
  void dispose() {
    final abandonedResult = _result;
    if (!_resultOwnershipTransferred && abandonedResult != null) {
      unawaited(_deleteResult(abandonedResult, reportError: false));
    }
    widget.routeObserver?.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _cancelSlowStartupTimer();
    _deadlineTimer?.cancel();
    _frameProcessor.dispose();
    _lifecycle.markDisposed();
    final controller = _controller;
    _controller = null;
    unawaited(_lifecycle.disposeController(controller));
    unawaited(_analysisService.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selfieCaptureProvider);
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
                Text(widget.strings.title,
                    style: theme.textTheme.headlineSmall),
                SizedBox(height: widget.captureTheme.spacing / 2),
                Text(widget.strings.instruction),
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

  Widget _buildContent(SelfieCaptureState state) {
    switch (state.phase) {
      case SelfieCapturePhase.permissionDenied:
      case SelfieCapturePhase.permissionPermanentlyDenied:
        return _MessagePanel(
          title: widget.strings.cameraPermissionTitle,
          message: state.phase == SelfieCapturePhase.permissionPermanentlyDenied
              ? widget.strings.cameraPermissionSettingsMessage
              : widget.strings.cameraPermissionMessage,
          spacing: widget.captureTheme.spacing / 2,
        );
      case SelfieCapturePhase.cameraUnavailable:
        return _MessagePanel(
          title: widget.strings.cameraUnavailableTitle,
          message: widget.strings.cameraUnavailableMessage,
          spacing: widget.captureTheme.spacing / 2,
        );
      case SelfieCapturePhase.failed:
        return _MessagePanel(
          title: widget.strings.captureFailedTitle,
          message: widget.strings.captureFailedMessage,
          spacing: widget.captureTheme.spacing / 2,
        );
      case SelfieCapturePhase.captured:
        final result = _result;
        if (result == null) return const SizedBox.expand();
        return ClipRRect(
          borderRadius:
              BorderRadius.circular(widget.captureTheme.controlRadius),
          child: Image.file(File(result.path), fit: BoxFit.cover),
        );
      case SelfieCapturePhase.initializing:
        return _CameraLoadingPanel(
          message: state.isSlowStartup
              ? widget.strings.slowCameraMessage
              : widget.strings.startingCameraMessage,
          spacing: widget.captureTheme.spacing,
        );
      case SelfieCapturePhase.paused:
      case SelfieCapturePhase.ready:
      case SelfieCapturePhase.analyzing:
      case SelfieCapturePhase.captureSuggested:
      case SelfieCapturePhase.capturing:
      case SelfieCapturePhase.timedOut:
        final controller = _controller;
        if (controller == null || !controller.value.isInitialized) {
          return _CameraLoadingPanel(
            message: widget.strings.startingCameraMessage,
            spacing: widget.captureTheme.spacing,
          );
        }
        return ClipRRect(
          borderRadius:
              BorderRadius.circular(widget.captureTheme.controlRadius),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewport = constraints.biggest;
              _viewportSize = viewport;
              _guideRect = widget.guideConfig.resolve(Offset.zero & viewport);
              return Stack(
                fit: StackFit.expand,
                children: [
                  _CoverCameraPreview(controller: controller),
                  SelfieCaptureOverlay(
                    guideConfig: widget.guideConfig,
                    style: widget.captureTheme.overlayStyle,
                    state: _overlayState(state),
                    progress: state.guidance?.progress ?? 0,
                  ),
                  Positioned(
                    left: widget.captureTheme.spacing,
                    right: widget.captureTheme.spacing,
                    bottom: widget.captureTheme.spacing,
                    child: _GuidancePanel(
                      message: _guidanceMessage(state.guidance),
                      progress: state.guidance?.progress ?? 0,
                      captureTheme: widget.captureTheme,
                    ),
                  ),
                ],
              );
            },
          ),
        );
    }
  }

  SelfieCaptureOverlayState _overlayState(SelfieCaptureState state) {
    if (state.phase == SelfieCapturePhase.timedOut) {
      return SelfieCaptureOverlayState.timedOut;
    }
    if (state.phase == SelfieCapturePhase.captureSuggested ||
        state.phase == SelfieCapturePhase.capturing) {
      return SelfieCaptureOverlayState.ready;
    }
    if (state.guidance != null) return SelfieCaptureOverlayState.guiding;
    return SelfieCaptureOverlayState.searching;
  }

  String _guidanceMessage(ActiveGuidanceState? guidance) {
    if (guidance == null) return widget.strings.alignFaceMessage;
    if (guidance.signal == ActiveGuidanceSignal.alignFace) {
      return _alignmentMessage(guidance.alignmentSignal);
    }
    return switch (guidance.signal) {
      ActiveGuidanceSignal.alignFace => widget.strings.alignFaceMessage,
      ActiveGuidanceSignal.blink => widget.strings.blinkMessage,
      ActiveGuidanceSignal.turnLeft => widget.strings.turnLeftMessage,
      ActiveGuidanceSignal.turnRight => widget.strings.turnRightMessage,
      ActiveGuidanceSignal.returnToNeutral =>
        widget.strings.returnToNeutralMessage,
      ActiveGuidanceSignal.faceNotClear => widget.strings.faceNotClearMessage,
      ActiveGuidanceSignal.captureSuggested =>
        widget.strings.captureReadyMessage,
      ActiveGuidanceSignal.timedOut => widget.strings.timedOutMessage,
    };
  }

  String _alignmentMessage(FaceAlignmentSignal? signal) => switch (signal) {
        FaceAlignmentSignal.noFace => widget.strings.noFaceMessage,
        FaceAlignmentSignal.multipleFaces =>
          widget.strings.multipleFacesMessage,
        FaceAlignmentSignal.moveCloser => widget.strings.moveCloserMessage,
        FaceAlignmentSignal.moveBack => widget.strings.moveBackMessage,
        FaceAlignmentSignal.moveLeft => widget.strings.moveLeftMessage,
        FaceAlignmentSignal.moveRight => widget.strings.moveRightMessage,
        FaceAlignmentSignal.moveUp => widget.strings.moveUpMessage,
        FaceAlignmentSignal.moveDown => widget.strings.moveDownMessage,
        FaceAlignmentSignal.lookStraight => widget.strings.lookStraightMessage,
        FaceAlignmentSignal.holdStill ||
        FaceAlignmentSignal.aligned =>
          widget.strings.holdStillMessage,
        null => widget.strings.alignFaceMessage,
      };

  Widget _buildActions(SelfieCaptureState state) {
    if (state.phase == SelfieCapturePhase.captured && _result != null) {
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
        state.phase == SelfieCapturePhase.permissionPermanentlyDenied;
    final timedOut = state.phase == SelfieCapturePhase.timedOut;
    final retryable = state.phase == SelfieCapturePhase.permissionDenied ||
        state.phase == SelfieCapturePhase.cameraUnavailable ||
        state.phase == SelfieCapturePhase.failed;
    final canCapture = state.phase == SelfieCapturePhase.captureSuggested;
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
            onPressed: canCapture
                ? _capture
                : permanentlyDenied
                    ? _permissionService.openSettings
                    : timedOut
                        ? _retryGuidance
                        : retryable
                            ? _initialize
                            : null,
            child: Text(
              permanentlyDenied
                  ? widget.strings.openSettingsButton
                  : timedOut || retryable
                      ? widget.strings.retryButton
                      : state.phase == SelfieCapturePhase.capturing
                          ? widget.strings.capturingButton
                          : widget.strings.captureButton,
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  const _CoverCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.expand();
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: isPortrait ? previewSize.height : previewSize.width,
          height: isPortrait ? previewSize.width : previewSize.height,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _GuidancePanel extends StatelessWidget {
  const _GuidancePanel({
    required this.message,
    required this.progress,
    required this.captureTheme,
  });

  final String message;
  final double progress;
  final SelfieCaptureTheme captureTheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: captureTheme.guidanceSurfaceColor,
        borderRadius: BorderRadius.circular(captureTheme.guidanceRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(captureTheme.spacing * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: captureTheme.transitionDuration,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                message,
                key: ValueKey(message),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: captureTheme.onGuidanceSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (progress > 0) ...[
              SizedBox(height: captureTheme.spacing * 0.65),
              TweenAnimationBuilder<double>(
                duration: captureTheme.transitionDuration,
                tween: Tween(end: progress),
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CameraLoadingPanel extends StatelessWidget {
  const _CameraLoadingPanel({required this.message, required this.spacing});

  final String message;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: spacing),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              message,
              key: ValueKey(message),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
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
