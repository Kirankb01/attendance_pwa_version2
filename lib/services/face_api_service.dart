import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';               // dart2wasm-safe JS interop
import 'package:flutter/foundation.dart';
import '../models/face_embedding.dart';

// ─── JS external declarations ────────────────────────────────────────────────
// These bind to the functions defined in web/index.html

@JS('getFaceApiStatus')
external JSString _getFaceApiStatus();

@JS('compareEmbeddings')
external JSString _compareEmbeddings(JSString a, JSString b);

@JS('generateFaceEmbedding')
external JSPromise<JSString> _generateFaceEmbedding(JSString base64);

// ─────────────────────────────────────────────────────────────────────────────

/// Service that bridges Flutter → JavaScript face-api.js functions
/// defined in web/index.html.
///
/// Uses dart:js_interop (dart2wasm-safe) instead of the legacy dart:js.
class FaceApiService {
  static final FaceApiService _instance = FaceApiService._internal();
  factory FaceApiService() => _instance;
  FaceApiService._internal();

  // ─── Model readiness ──────────────────────────────────────────────────────

  bool get isReady {
    try {
      final result = _getFaceApiStatus().toDart;
      final data = jsonDecode(result) as Map<String, dynamic>;
      return data['ready'] == true;
    } catch (_) {
      return false;
    }
  }

  String? get loadError {
    try {
      final result = _getFaceApiStatus().toDart;
      final data = jsonDecode(result) as Map<String, dynamic>;
      return data['error'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> waitForReady({int timeoutSeconds = 30}) async {
    final deadline = DateTime.now().add(Duration(seconds: timeoutSeconds));
    while (DateTime.now().isBefore(deadline)) {
      if (isReady) return true;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  // ─── Embedding generation ─────────────────────────────────────────────────

  Future<List<double>?> generateEmbedding(String base64Image) async {
    final r = await generateEmbeddingWithError(base64Image);
    return r.embedding;
  }

  Future<({List<double>? embedding, String? error})> generateEmbeddingWithError(
    String base64Image,
  ) async {
    try {
      // JSPromise<JSString> → Dart Future<String>
      final jsResult = await _generateFaceEmbedding(base64Image.toJS).toDart;
      final resultStr = jsResult.toDart;
      final data = jsonDecode(resultStr) as Map<String, dynamic>;

      if (data['success'] == true) {
        final raw = data['embedding'] as List;
        final emb = raw.map((e) => (e as num).toDouble()).toList();
        return (embedding: emb, error: null);
      }
      return (embedding: null, error: data['error'] as String?);
    } catch (e) {
      debugPrint('[FaceAPI] generateEmbedding error: $e');
      return (embedding: null, error: e.toString());
    }
  }

  // ─── Comparison ───────────────────────────────────────────────────────────

  MatchResult compareEmbeddings(List<double> embA, List<double> embB) {
    try {
      final aJson = jsonEncode(embA);
      final bJson = jsonEncode(embB);
      final resultStr = _compareEmbeddings(aJson.toJS, bJson.toJS).toDart;
      final data = jsonDecode(resultStr) as Map<String, dynamic>;

      return MatchResult(
        match: data['match'] == true,
        distance: (data['distance'] as num).toDouble(),
        confidence: (data['confidence'] as num).toInt(),
      );
    } catch (e) {
      return MatchResult.error(e.toString());
    }
  }

  MatchResult findBestMatch(
    List<double> queryEmbedding,
    List<FaceEmbedding> registered,
  ) {
    if (registered.isEmpty) return MatchResult.error('No registered faces');

    MatchResult? best;
    FaceEmbedding? bestFace;

    for (final face in registered) {
      final result = compareEmbeddings(queryEmbedding, face.embedding);
      if (best == null || result.distance < best.distance) {
        best = result;
        bestFace = face;
      }
    }

    return MatchResult(
      match: best!.match,
      distance: best.distance,
      confidence: best.confidence,
      matchedFace: best.match ? bestFace : null,
    );
  }
}
