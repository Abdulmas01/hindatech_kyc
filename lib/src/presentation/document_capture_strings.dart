/// Customer-facing text used by the document capture experience.
class DocumentCaptureStrings {
  const DocumentCaptureStrings({
    this.documentTitle = 'Capture your document',
    this.documentInstruction = 'Position your document inside the frame.',
    this.cameraPermissionTitle = 'Camera permission needed',
    this.cameraPermissionMessage =
        'Allow camera access to continue document capture.',
    this.cameraPermissionSettingsMessage =
        'Enable camera access in your device settings to continue.',
    this.cameraUnavailableTitle = 'Camera unavailable',
    this.cameraUnavailableMessage =
        'The camera could not be started. Please try again.',
    this.documentCaptureFailedMessage =
        'The document could not be captured. Please try again.',
    this.documentCaptureFailedTitle = 'Capture failed',
    this.qualityEvaluatingMessage = 'Checking image quality...',
    this.qualityReadyMessage = 'Hold steady for capture.',
    this.qualityBlurryMessage = 'Hold still for a clearer image.',
    this.qualityGlareMessage = 'Tilt the document to reduce glare.',
    this.qualityDarkMessage = 'Move to a brighter area.',
    this.qualityNoDocumentMessage = 'Place the document inside the frame.',
    this.captureButton = 'Capture document',
    this.autoCapturingButton = 'Capturing...',
    this.retryButton = 'Try again',
    this.openSettingsButton = 'Open settings',
    this.retakeButton = 'Retake',
    this.continueButton = 'Continue',
    this.cancelButton = 'Cancel',
  });

  final String documentTitle;
  final String documentInstruction;
  final String cameraPermissionTitle;
  final String cameraPermissionMessage;
  final String cameraPermissionSettingsMessage;
  final String cameraUnavailableTitle;
  final String cameraUnavailableMessage;
  final String documentCaptureFailedMessage;
  final String documentCaptureFailedTitle;
  final String qualityEvaluatingMessage;
  final String qualityReadyMessage;
  final String qualityBlurryMessage;
  final String qualityGlareMessage;
  final String qualityDarkMessage;
  final String qualityNoDocumentMessage;
  final String captureButton;
  final String autoCapturingButton;
  final String retryButton;
  final String openSettingsButton;
  final String retakeButton;
  final String continueButton;
  final String cancelButton;
}
