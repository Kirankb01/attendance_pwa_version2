import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/face_embedding.dart';

/// Persists registered face embeddings in browser localStorage via SharedPreferences.
/// In the POC this is per-device. In production, swap for an API call.
class EmbeddingStorage {
  static final EmbeddingStorage _instance = EmbeddingStorage._internal();
  factory EmbeddingStorage() => _instance;
  EmbeddingStorage._internal();

  static const _key = 'face_poc_embeddings';

  // In-memory cache
  List<FaceEmbedding> _cache = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await loadAll();
  }

  /// Load all stored embeddings
  Future<List<FaceEmbedding>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      _loaded = true;
      return [];
    }
    try {
      final list = jsonDecode(raw) as List;
      _cache = list
          .map((e) => FaceEmbedding.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _cache = [];
    }
    _loaded = true;
    return List.unmodifiable(_cache);
  }

  /// All embeddings (from cache — call loadAll first)
  Future<List<FaceEmbedding>> getAll() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache);
  }

  /// Save a new embedding
  Future<void> save(FaceEmbedding embedding) async {
    await _ensureLoaded();
    _cache.add(embedding);
    await _persist();
  }

  /// Delete by id
  Future<void> delete(String id) async {
    await _ensureLoaded();
    _cache.removeWhere((e) => e.id == id);
    await _persist();
  }

  /// Clear all
  Future<void> clearAll() async {
    _cache = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Count
  Future<int> count() async {
    await _ensureLoaded();
    return _cache.length;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_cache.map((e) => e.toJson()).toList());
    await prefs.setString(_key, data);
  }
}
