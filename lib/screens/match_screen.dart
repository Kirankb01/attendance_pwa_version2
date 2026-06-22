import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/face_api_service.dart';
import '../services/embedding_storage.dart';
import '../models/face_embedding.dart';
import '../widgets/camera_view.dart';

enum MatchState { idle, capturing, processing, matched, noMatch, error, noRegistered }

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  final _camera = CameraService();
  final _faceApi = FaceApiService();
  final _storage = EmbeddingStorage();

  MatchState _state = MatchState.idle;
  MatchResult? _result;
  String? _capturedDataUrl;
  String? _errorMessage;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _checkRegistrations();
  }

  Future<void> _checkRegistrations() async {
    final count = await _storage.count();
    if (mounted && count == 0) {
      setState(() => _state = MatchState.noRegistered);
    }
  }

  Future<void> _onCapture() async {
    if (_state == MatchState.processing) return;

    setState(() {
      _state = MatchState.capturing;
      _result = null;
      _errorMessage = null;
    });

    final dataUrl = await _camera.captureFrame();
    if (dataUrl == null) {
      setState(() {
        _state = MatchState.error;
        _errorMessage = 'Failed to capture photo.';
      });
      return;
    }

    setState(() {
      _capturedDataUrl = dataUrl;
      _state = MatchState.processing;
    });

    // Get embedding for captured face
    final r = await _faceApi.generateEmbeddingWithError(dataUrl);
    if (r.embedding == null) {
      setState(() {
        _state = MatchState.error;
        _errorMessage = _friendlyError(r.error);
        _capturedDataUrl = null;
      });
      return;
    }

    // Load all registered faces and find best match
    final registered = await _storage.getAll();
    if (registered.isEmpty) {
      setState(() => _state = MatchState.noRegistered);
      return;
    }

    final matchResult = _faceApi.findBestMatch(r.embedding!, registered);

    if (!mounted) return;
    setState(() {
      _result = matchResult;
      _state = matchResult.match ? MatchState.matched : MatchState.noMatch;
    });
  }

  void _reset() {
    setState(() {
      _state = MatchState.idle;
      _capturedDataUrl = null;
      _result = null;
      _errorMessage = null;
    });
  }

  String _friendlyError(String? raw) {
    if (raw == null) return 'Unknown error';
    if (raw.contains('NO_FACE_DETECTED')) {
      return 'No face detected. Ensure good lighting and face the camera directly.';
    }
    return raw;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Match Face',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(child: _buildMainArea()),
            const SizedBox(height: 20),
            _buildBottomArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainArea() {
    // Show result overlay on captured image
    if (_capturedDataUrl != null &&
        (_state == MatchState.matched ||
            _state == MatchState.noMatch ||
            _state == MatchState.processing)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(_capturedDataUrl!, fit: BoxFit.cover),
          ),
          if (_state == MatchState.processing)
            _buildProcessingOverlay()
          else if (_result != null)
            _buildResultOverlay(_result!),
        ],
      );
    }

    if (_state == MatchState.noRegistered) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add_disabled,
                size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No faces registered yet.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to Register first to add a face.',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CameraView(
        captureLabel: 'Match',
        onCapture: _state == MatchState.idle ? _onCapture : null,
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00D4FF)),
            SizedBox(height: 16),
            Text('Matching…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultOverlay(MatchResult result) {
    final isMatch = result.match;
    final color = isMatch ? const Color(0xFF00C87A) : const Color(0xFFFF4D6D);
    final icon = isMatch ? Icons.check_circle : Icons.cancel;
    final label = isMatch ? 'MATCH' : 'NO MATCH';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            color.withOpacity(0.7),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: Icon(icon, color: color, size: 56),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              if (isMatch && result.matchedFace != null) ...[
                const SizedBox(height: 4),
                Text(
                  result.matchedFace!.label,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
              const SizedBox(height: 12),
              _ConfidenceBar(
                confidence: result.confidence,
                distance: result.distance,
                isMatch: isMatch,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    if (_state == MatchState.noRegistered) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, color: Color(0xFF0A0E1A), size: 18),
              SizedBox(width: 8),
              Text('Register a Face First',
                  style: TextStyle(
                      color: Color(0xFF0A0E1A), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (_state == MatchState.matched || _state == MatchState.noMatch || _state == MatchState.error) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _reset,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00D4FF)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, color: Color(0xFF00D4FF), size: 18),
                    SizedBox(width: 8),
                    Text('Try Again',
                        style: TextStyle(
                            color: Color(0xFF00D4FF),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      'Point your face at the camera and tap Match.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final int confidence;
  final double distance;
  final bool isMatch;

  const _ConfidenceBar({
    required this.confidence,
    required this.distance,
    required this.isMatch,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMatch ? const Color(0xFF00C87A) : const Color(0xFFFF4D6D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Confidence',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text('$confidence%',
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence / 100,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distance: ${distance.toStringAsFixed(3)}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11)),
              Text('Threshold: 0.600',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
