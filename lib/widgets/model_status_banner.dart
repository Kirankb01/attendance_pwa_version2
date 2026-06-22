import 'dart:async';
import 'package:flutter/material.dart';
import '../services/face_api_service.dart';

/// Banner that polls face-api.js model loading state and shows progress.
/// Disappears once models are ready.
class ModelStatusBanner extends StatefulWidget {
  final VoidCallback? onReady;

  const ModelStatusBanner({super.key, this.onReady});

  @override
  State<ModelStatusBanner> createState() => _ModelStatusBannerState();
}

class _ModelStatusBannerState extends State<ModelStatusBanner> {
  final _service = FaceApiService();
  Timer? _timer;
  bool _ready = false;
  String? _error;
  int _dots = 0;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  void _poll() {
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      final ready = _service.isReady;
      final error = _service.loadError;
      if (mounted) {
        setState(() {
          _ready = ready;
          _error = error;
          _dots = (_dots + 1) % 4;
        });
        if (ready) {
          _timer?.cancel();
          widget.onReady?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const SizedBox.shrink();

    final hasError = _error != null;
    final dotStr = '.' * (_dots + 1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: hasError
          ? const Color(0xFF3A1020)
          : const Color(0xFF0D1A2E),
      child: Row(
        children: [
          if (!hasError)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00D4FF),
              ),
            )
          else
            const Icon(Icons.warning_amber_rounded,
                size: 16, color: Color(0xFFFF4D6D)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasError
                  ? 'Model load failed: $_error'
                  : 'Loading AI models from CDN$dotStr',
              style: TextStyle(
                color: hasError
                    ? const Color(0xFFFF4D6D)
                    : Colors.white.withOpacity(0.75),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
