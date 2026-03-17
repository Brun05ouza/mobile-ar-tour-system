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

  PointModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageReference,
    required this.latitude,
    required this.longitude,
    this.details = '',
    this.imagePath = '',
  });

  factory PointModel.fromJson(Map<String, dynamic> json) => PointModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        imageReference: json['imageReference'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        details: json['details'] ?? '',
        imagePath: json['imagePath'] ?? '',
      );
}