// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PointModelAdapter extends TypeAdapter<PointModel> {
  @override
  final int typeId = 0;

  @override
  PointModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PointModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      imageReference: fields[3] as String,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PointModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageReference)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
