import 'dart:js_interop';

@JS('promptInstall')
external JSPromise<JSBoolean> _promptInstall();

@JS('isInstallAvailable')
external JSBoolean _isInstallAvailable();

@JS('onInstallAvailable')
external set _onInstallAvailable(JSFunction callback);

class PwaService {
  /// Checks if the PWA installation prompt is available
  static bool get isInstallAvailable => _isInstallAvailable().toDart;

  /// Prompts the user to install the PWA
  static Future<bool> promptInstall() async {
    final result = await _promptInstall().toDart;
    return result.toDart;
  }

  /// Register a callback for when the install prompt becomes available
  static void setOnInstallAvailable(void Function() callback) {
    _onInstallAvailable = callback.toJS;
  }
}
