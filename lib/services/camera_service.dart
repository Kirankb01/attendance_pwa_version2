import 'dart:async';
import 'dart:js_interop';              // dart2wasm-safe
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web; // replaces dart:html
import '../widgets/debug_overlay.dart';

/// Manages browser camera via getUserMedia and captures base64 frames.
/// Uses package:web (dart2wasm-compatible) instead of dart:html.
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  web.HTMLVideoElement? _video;
  web.MediaStream? _stream;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  web.HTMLVideoElement? get videoElement => _video;

  /// Start front-facing camera
  Future<bool> start() async {
    DebugLogger().log('Starting camera...');
    try {
      // Build constraints as a JS object
      final constraints = web.MediaStreamConstraints(
        video: web.MediaTrackConstraints(
          facingMode: 'user'.toJS,
        ),
        audio: false.toJS,
      );
      DebugLogger().log('Constraints built: user facing');

      _stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;
      DebugLogger().log('getUserMedia success, stream acquired');

      final video = web.HTMLVideoElement();
      video.autoplay = true;
      video.muted = true;
      video.setAttribute('playsinline', 'true');
      video.setAttribute('webkit-playsinline', 'true');
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';
      video.srcObject = _stream;
      _video = video;
      DebugLogger().log('Video element configured and srcObject set');

      video.play();
      DebugLogger().log('video.play() called');

      // Wait for metadata (stream dimensions known)
      DebugLogger().log('Waiting for onLoadedMetadata...');
      await video.onLoadedMetadata.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          DebugLogger().log('TIMEOUT waiting for metadata!');
          throw TimeoutException('Camera stream timeout');
        },
      );
      DebugLogger().log('Metadata loaded! Dimensions: ${video.videoWidth}x${video.videoHeight}');

      _isRunning = true;
      return true;
    } catch (e) {
      DebugLogger().log('ERROR starting camera: $e');
      debugPrint('[Camera] start error: $e');
      return false;
    }
  }

  /// Capture current frame as a JPEG data URL string
  Future<String?> captureFrame({int quality = 85}) async {
    if (_video == null || !_isRunning) return null;
    DebugLogger().log('Capturing frame...');
    try {
      final canvas = web.HTMLCanvasElement();
      canvas.width = _video!.videoWidth;
      canvas.height = _video!.videoHeight;

      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
      if (ctx == null) {
        DebugLogger().log('Canvas 2D context is null');
        return null;
      }

      // Mirror horizontally for selfie feel
      ctx.translate(canvas.width.toDouble(), 0);
      ctx.scale(-1, 1);
      ctx.drawImage(_video!, 0, 0);

      final dataUrl = canvas.toDataURL('image/jpeg', (quality / 100).toJS);
      DebugLogger().log('Frame captured successfully');
      return dataUrl;
    } catch (e) {
      DebugLogger().log('ERROR capturing frame: $e');
      debugPrint('[Camera] captureFrame error: $e');
      return null;
    }
  }

  /// Stop camera and release resources
  Future<void> stop() async {
    _isRunning = false;
    _stream?.getTracks().toDart.forEach((t) => t.stop());
    _stream = null;
    _video?.srcObject = null;
    _video = null;
  }

  /// Check if the browser has any video input device
  static Future<bool> isCameraAvailable() async {
    try {
      final devices =
          await web.window.navigator.mediaDevices.enumerateDevices().toDart;
      return devices.toDart.any((d) => d.kind == 'videoinput');
    } catch (_) {
      return false;
    }
  }
}
