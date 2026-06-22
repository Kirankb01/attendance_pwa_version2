import 'dart:ui_web' as ui_web;        // dart2wasm-safe platform view registration
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../services/camera_service.dart';

/// Displays the live camera stream using HtmlElementView (Web only).
/// Uses dart:ui_web instead of the legacy dart:ui platformViewRegistry.
class CameraView extends StatefulWidget {
  final VoidCallback? onCapture;
  final bool showCaptureButton;
  final String captureLabel;

  const CameraView({
    super.key,
    this.onCapture,
    this.showCaptureButton = true,
    this.captureLabel = 'Capture',
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final CameraService _camera = CameraService();
  String? _viewId;
  bool _starting = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    final ok = await _camera.start();
    if (!mounted) return;

    if (!ok) {
      setState(() { _starting = false; _failed = true; });
      return;
    }

    _viewId = 'camera-view-${DateTime.now().millisecondsSinceEpoch}';

    // dart:ui_web is the dart2wasm-compatible way to register platform views
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId!,
      (int id) => _camera.videoElement! as web.HTMLElement,
    );

    setState(() { _starting = false; });
  }

  @override
  void dispose() {
    _camera.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_starting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00D4FF)),
            SizedBox(height: 16),
            Text('Starting camera…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Color(0xFFFF4D6D), size: 48),
            const SizedBox(height: 16),
            const Text('Camera unavailable',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Allow camera access and reload the page.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: HtmlElementView(viewType: _viewId!),
        ),
        CustomPaint(size: Size.infinite, painter: _FaceOvalPainter()),
        if (widget.showCaptureButton)
          Positioned(
            bottom: 32,
            child: _CaptureButton(
              label: widget.captureLabel,
              onTap: widget.onCapture,
            ),
          ),
        Positioned(
          top: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Position your face in the oval',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Face oval guide ─────────────────────────────────────────────────────────

class _FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width * 0.32;
    final ry = size.height * 0.38;

    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final ovalPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, cy),
        width: rx * 2,
        height: ry * 2,
      ));
    final maskPath =
        Path.combine(PathOperation.difference, outerPath, ovalPath);

    canvas.drawPath(
        maskPath, Paint()..color = Colors.black.withOpacity(0.45));

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      Paint()
        ..color = const Color(0xFF00D4FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Capture button ───────────────────────────────────────────────────────────

class _CaptureButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _CaptureButton({required this.label, this.onTap});

  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.reverse().then((_) => _ctrl.forward());
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00D4FF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withOpacity(0.45),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Color(0xFF0A0E1A),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
