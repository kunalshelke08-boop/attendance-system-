// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceRecordAdapter extends TypeAdapter<AttendanceRecord> {
  @override
  final int typeId = 0;

  @override
  AttendanceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return AttendanceRecord(
      uid: fields[0] as String,
      name: fields[1] as String,
      classId: fields[2] as String,
      date: fields[3] as String,
      timestamp: fields[4] as String,
      status: fields[5] as String,
      markedVia: fields[6] as String,
      isSynced: fields[7] as bool,
      subject: fields[8] as String? ?? '',
      facultyInitials: fields[9] as String? ?? '',
      lectureSlot: fields[10] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.classId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.markedVia)
      ..writeByte(7)
      ..write(obj.isSynced)
      ..writeByte(8)
      ..write(obj.subject)
      ..writeByte(9)
      ..write(obj.facultyInitials)
      ..writeByte(10)
      ..write(obj.lectureSlot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
