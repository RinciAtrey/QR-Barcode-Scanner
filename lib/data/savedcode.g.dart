
part of 'savedcode.dart';


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
    )..createdAt = fields[2] as DateTime;
  }

  @override
  void write(BinaryWriter writer, SavedCode obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.isQr)
      ..writeByte(2)
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
