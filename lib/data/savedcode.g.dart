// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savedcode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedCodeAdapter extends TypeAdapter<SavedCode> {
  @override
  final int typeId = 0;

  @override
  SavedCode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedCode(
      title: fields[0] as String,
      isQr: fields[1] as bool,
      data: fields[2] as String,
    )..createdAt = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, SavedCode obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.isQr)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedCodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
