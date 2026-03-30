// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PerformanceModelAdapter extends TypeAdapter<PerformanceModel> {
  @override
  final int typeId = 1;

  @override
  PerformanceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PerformanceModel(
      id: fields[0] as String,
      cardId: fields[1] as String,
      year: fields[2] as int,
      month: fields[3] as int,
      usedAmount: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PerformanceModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardId)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.month)
      ..writeByte(4)
      ..write(obj.usedAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
