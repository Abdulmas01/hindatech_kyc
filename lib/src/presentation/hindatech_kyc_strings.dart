class HindatechKycStrings {
  const HindatechKycStrings({
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
    this.captureButton = 'Capture document',
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
  final String captureButton;
  final String retryButton;
  final String openSettingsButton;
  final String retakeButton;
  final String continueButton;
  final String cancelButton;
}
