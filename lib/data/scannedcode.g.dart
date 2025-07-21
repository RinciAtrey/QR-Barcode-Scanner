// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scannedcode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScannedCodeAdapter extends TypeAdapter<ScannedCode> {
  @override
  final int typeId = 2;

  @override
  ScannedCode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScannedCode(
      title: fields[0] as String,
      isQr: fields[1] as bool,
      data: fields[2] as String,
      formatName: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ScannedCode obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.isQr)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.formatName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedCodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
