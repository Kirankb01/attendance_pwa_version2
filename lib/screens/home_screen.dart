import 'package:flutter/material.dart';
import '../services/embedding_storage.dart';
import '../models/face_embedding.dart';
import '../widgets/model_status_banner.dart';
import '../services/pwa_service.dart';
import 'register_screen.dart';
import 'match_screen.dart';
import 'agent_register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = EmbeddingStorage();
  List<FaceEmbedding> _registered = [];
  bool _modelsReady = false;
  bool _showInstallButton = false;

  @override
  void initState() {
    super.initState();
    _loadRegistered();
    
    // Check if install is already available
    if (PwaService.isInstallAvailable) {
      _showInstallButton = true;
    }
    
    // Listen for the event if it hasn't fired yet
    PwaService.setOnInstallAvailable(() {
      if (mounted) {
        setState(() {
          _showInstallButton = true;
        });
      }
    });
  }

  Future<void> _loadRegistered() async {
    final faces = await _storage.getAll();
    if (mounted) setState(() => _registered = faces);
  }

  Future<void> _deleteFace(String id) async {
    await _storage.delete(id);
    await _loadRegistered();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1828),
        title: const Text('Clear All?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This removes all registered faces. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Color(0xFFFF4D6D))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.clearAll();
      await _loadRegistered();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Column(
        children: [
          // Model loading banner (disappears when ready)
          ModelStatusBanner(onReady: () {
            if (mounted) setState(() => _modelsReady = true);
          }),

          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildFlowDiagram(),
                    const SizedBox(height: 32),
                    _buildActionCards(context),
                    const SizedBox(height: 32),
                    _buildRegisteredFaces(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.face_retouching_natural,
                  color: Color(0xFF00D4FF), size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face Recognition',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Browser POC · Stage 1',
                  style: TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (_showInstallButton) ...[
              GestureDetector(
                onTap: () async {
                  final installed = await PwaService.promptInstall();
                  if (installed && mounted) {
                    setState(() {
                      _showInstallButton = false;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, size: 14, color: Color(0xFF7C4DFF)),
                      SizedBox(width: 4),
                      Text('Install App', style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (_modelsReady)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C87A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF00C87A).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFF00C87A)),
                    SizedBox(width: 5),
                    Text('AI Ready',
                        style: TextStyle(
                            color: Color(0xFF00C87A), fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Prove the core loop:\nRegister a face → Match it → Confirm it works.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFlowDiagram() {
    final steps = [
      ('Camera', Icons.videocam),
      ('Register', Icons.person_add),
      ('Embedding', Icons.memory),
      ('Store', Icons.save),
      ('Capture', Icons.photo_camera),
      ('Compare', Icons.compare_arrows),
      ('Match', Icons.check_circle),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1828),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF1A2A40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POC Flow',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                _FlowStep(label: steps[i].$1, icon: steps[i].$2),
                if (i < steps.length - 1)
                  const Icon(Icons.arrow_forward_ios,
                      size: 10, color: Colors.white24),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Register',
                subtitle: 'Add a face to the database',
                icon: Icons.person_add_alt_1,
                color: const Color(0xFF00D4FF),
                count: _registered.length,
                countLabel: 'stored',
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()));
                  _loadRegistered();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionCard(
                title: 'Match',
                subtitle: 'Verify identity from camera',
                icon: Icons.face_unlock_rounded,
                color: const Color(0xFF7C4DFF),
                count: _registered.length,
                countLabel: 'to match against',
                onTap: _registered.isEmpty
                    ? null
                    : () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const MatchScreen()));
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'API Post',
                subtitle: 'Register Agent via API',
                icon: Icons.api,
                color: const Color(0xFF00C87A),
                count: 0,
                countLabel: 'Fields',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AgentRegisterScreen()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisteredFaces() {
    if (_registered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1828),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A2A40)),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.person_outline,
                  size: 36, color: Colors.white24),
              const SizedBox(height: 8),
              Text(
                'No faces registered',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Registered Faces (${_registered.length})',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear All',
                  style: TextStyle(color: Color(0xFFFF4D6D), fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _registered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final face = _registered[i];
            return _FaceCard(
              face: face,
              onDelete: () => _deleteFace(face.id),
            );
          },
        ),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _FlowStep extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FlowStep({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF00D4FF)),
        const SizedBox(height: 3),
        Text(label,
            style:
                const TextStyle(color: Colors.white60, fontSize: 9)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int count;
  final String countLabel;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.count,
    required this.countLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12)),
              const SizedBox(height: 16),
              Text(
                '$count $countLabel',
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceCard extends StatelessWidget {
  final FaceEmbedding face;
  final VoidCallback onDelete;

  const _FaceCard({required this.face, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1828),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2A40)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: face.thumbnailBase64 != null
                ? Image.network(
                    face.thumbnailBase64!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const _AvatarPlaceholder(),
                  )
                : const _AvatarPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(face.label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Registered ${_timeAgo(face.registeredAt)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  '128-d embedding · ${face.embedding.length} dimensions',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.white24, size: 20),
            onPressed: onDelete,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: const Color(0xFF1A2A40),
      child: const Icon(Icons.person, color: Colors.white24, size: 24),
    );
  }
}
