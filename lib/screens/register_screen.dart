import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/face_api_service.dart';
import '../services/embedding_storage.dart';
import '../models/face_embedding.dart';
import '../widgets/camera_view.dart';

enum RegisterState { idle, capturing, processing, success, error }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _camera = CameraService();
  final _faceApi = FaceApiService();
  final _storage = EmbeddingStorage();

  RegisterState _state = RegisterState.idle;
  String? _capturedDataUrl;
  String? _errorMessage;
  String? _statusMessage;
  final _labelController = TextEditingController(text: 'User 1');

  Future<void> _onCapture() async {
    if (_state == RegisterState.processing) return;

    setState(() {
      _state = RegisterState.capturing;
      _statusMessage = 'Capturing photo…';
      _errorMessage = null;
    });

    final dataUrl = await _camera.captureFrame();

    if (dataUrl == null) {
      setState(() {
        _state = RegisterState.error;
        _errorMessage = 'Failed to capture photo. Check camera permissions.';
      });
      return;
    }

    setState(() {
      _capturedDataUrl = dataUrl;
      _state = RegisterState.processing;
      _statusMessage = 'Detecting face…';
    });

    // Generate embedding
    final result = await _faceApi.generateEmbeddingWithError(dataUrl);

    if (result.embedding == null) {
      setState(() {
        _state = RegisterState.error;
        _errorMessage = _friendlyError(result.error);
        _capturedDataUrl = null;
      });
      return;
    }

    // Save to storage
    final embedding = FaceEmbedding(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelController.text.trim().isEmpty
          ? 'User'
          : _labelController.text.trim(),
      embedding: result.embedding!,
      registeredAt: DateTime.now(),
      thumbnailBase64: dataUrl,
    );
    await _storage.save(embedding);

    if (!mounted) return;
    setState(() {
      _state = RegisterState.success;
      _statusMessage = 'Face registered successfully!';
    });
  }

  void _reset() {
    setState(() {
      _state = RegisterState.idle;
      _capturedDataUrl = null;
      _errorMessage = null;
      _statusMessage = null;
    });
  }

  String _friendlyError(String? raw) {
    if (raw == null) return 'Unknown error';
    if (raw.contains('NO_FACE_DETECTED')) {
      return 'No face detected. Make sure your face is well-lit and centred in the oval.';
    }
    if (raw.contains('Models not loaded')) {
      return 'AI models are still loading. Wait a moment and try again.';
    }
    return raw;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Register Face',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Label input
            TextField(
              controller: _labelController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name / Label',
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                ),
                filled: true,
                fillColor: const Color(0xFF0F1828),
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00D4FF)),
              ),
            ),
            const SizedBox(height: 20),

            // Camera or preview
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildCameraArea(),
              ),
            ),

            const SizedBox(height: 20),

            // Status / buttons
            _buildBottomArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    // Show captured photo preview
    if (_capturedDataUrl != null && _state != RegisterState.idle) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(_capturedDataUrl!, fit: BoxFit.cover),
          if (_state == RegisterState.processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00D4FF)),
                    SizedBox(height: 16),
                    Text(
                      'Generating face embedding…',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // Live camera
    return CameraView(
      captureLabel: 'Register',
      onCapture: _state == RegisterState.idle ? _onCapture : null,
    );
  }

  Widget _buildBottomArea() {
    switch (_state) {
      case RegisterState.success:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00C87A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00C87A)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Face registered for "${_labelController.text}"',
                      style: const TextStyle(color: Color(0xFF00C87A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OutlineButton(
                    label: 'Register Another',
                    icon: Icons.add,
                    onTap: _reset,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilledButton(
                    label: 'Go to Match',
                    icon: Icons.arrow_forward,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        );

      case RegisterState.error:
        return Column(
          children: [
            _ErrorCard(message: _errorMessage ?? 'Unknown error'),
            const SizedBox(height: 16),
            _FilledButton(label: 'Try Again', icon: Icons.refresh, onTap: _reset),
          ],
        );

      default:
        return Text(
          _statusMessage ?? 'Tap the button below the oval to capture your face.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        );
    }
  }
}

// ─── Small reusable button widgets ───────────────────────────────────────────

class _FilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _FilledButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF00D4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0A0E1A)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF0A0E1A), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00D4FF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF00D4FF)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF00D4FF), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0A14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4D6D).withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF4D6D), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
