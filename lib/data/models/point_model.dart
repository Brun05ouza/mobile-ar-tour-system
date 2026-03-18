import 'package:hive_flutter/hive_flutter.dart';

part 'point_model.g.dart';

@HiveType(typeId: 0)
class PointModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String imageReference;

  @HiveField(4)
  final double latitude;

  @HiveField(5)
  final double longitude;

  @HiveField(6)
  final String details;

  @HiveField(7)
  final String imagePath;

  // ── Campos adicionados para reconhecimento híbrido ──────────────────────────
  // Todos com valores default para não quebrar dados/código existente.

  @HiveField(8)
  final String category;

  @HiveField(9)
  final List<String> tags;

  /// Caminhos de assets visuais usados na comparação por OpenCV/ORB.
  /// Ficam em assets/recognition/<id>/
  @HiveField(10)
  final List<String> recognitionImages;

  /// Threshold de confiança específico para este ponto (override do global).
  /// Se 0.0, usa o threshold global configurado nas constantes.
  @HiveField(11)
  final double recognitionThreshold;

  @HiveField(12)
  final String thumbnailAsset;

  @HiveField(13)
  final String audioAsset;

  PointModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageReference,
    required this.latitude,
    required this.longitude,
    this.details = '',
    this.imagePath = '',
    this.category = '',
    this.tags = const [],
    this.recognitionImages = const [],
    this.recognitionThreshold = 0.0,
    this.thumbnailAsset = '',
    this.audioAsset = '',
  });

  factory PointModel.fromJson(Map<String, dynamic> json) => PointModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        imageReference: json['imageReference'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        details: json['details'] as String? ?? '',
        imagePath: json['imagePath'] as String? ?? '',
        category: json['category'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        recognitionImages: (json['recognitionImages'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        recognitionThreshold:
            (json['recognitionThreshold'] as num?)?.toDouble() ?? 0.0,
        thumbnailAsset: json['thumbnailAsset'] as String? ?? '',
        audioAsset: json['audioAsset'] as String? ?? '',
      );
}
