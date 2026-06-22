import 'dart:convert';

/// Represents a registered face with its 128-d embedding from face-api.js
class FaceEmbedding {
  final String id;
  final String label; // e.g. "User 1", employee name later
  final List<double> embedding; // 128-dimensional vector from FaceRecognitionNet
  final DateTime registeredAt;
  final String? thumbnailBase64; // small preview for UI

  const FaceEmbedding({
    required this.id,
    required this.label,
    required this.embedding,
    required this.registeredAt,
    this.thumbnailBase64,
  });

  factory FaceEmbedding.fromJson(Map<String, dynamic> json) {
    return FaceEmbedding(
      id: json['id'] as String,
      label: json['label'] as String,
      embedding: (json['embedding'] as List).map((e) => (e as num).toDouble()).toList(),
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      thumbnailBase64: json['thumbnailBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'embedding': embedding,
    'registeredAt': registeredAt.toIso8601String(),
    'thumbnailBase64': thumbnailBase64,
  };

  String toJsonString() => jsonEncode(toJson());

  static FaceEmbedding fromJsonString(String s) =>
      FaceEmbedding.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// Result of a face match comparison
class MatchResult {
  final bool match;
  final double distance; // Euclidean distance, lower = more similar
  final int confidence;  // 0–100, higher = more confident match
  final FaceEmbedding? matchedFace;
  final String? error;

  const MatchResult({
    required this.match,
    required this.distance,
    required this.confidence,
    this.matchedFace,
    this.error,
  });

  factory MatchResult.error(String message) => MatchResult(
    match: false,
    distance: 1.0,
    confidence: 0,
    error: message,
  );

  /// Visual label for the confidence level
  String get confidenceLabel {
    if (confidence >= 80) return 'Very High';
    if (confidence >= 60) return 'High';
    if (confidence >= 40) return 'Medium';
    if (confidence >= 20) return 'Low';
    return 'Very Low';
  }
}
