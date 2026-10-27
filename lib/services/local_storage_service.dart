import 'package:hive_flutter/hive_flutter.dart';
import '../models/attendance_model.dart';

class LocalStorageService {
  static const String _attendanceBox = 'attendance_records';
  static const String _settingsBox = 'settings';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AttendanceRecordAdapter());
    await Hive.openBox<AttendanceRecord>(_attendanceBox);
    await Hive.openBox(_settingsBox);
  }

  // ─── Attendance Records ────────────────────────────────
  Box<AttendanceRecord> get _attendanceRecords =>
      Hive.box<AttendanceRecord>(_attendanceBox);

  Future<void> saveAttendance(AttendanceRecord record) async {
    await _attendanceRecords.put(record.key, record);
  }

  Future<void> saveMultipleAttendance(List<AttendanceRecord> records) async {
    final Map<String, AttendanceRecord> entries = {};
    for (final r in records) {
      entries[r.key] = r;
    }
    await _attendanceRecords.putAll(entries);
  }

  List<AttendanceRecord> getAllRecords() {
    return _attendanceRecords.values.toList();
  }

  List<AttendanceRecord> getUnsyncedRecords() {
    return _attendanceRecords.values.where((r) => !r.isSynced).toList();
  }

  List<AttendanceRecord> getRecordsByDate(String classId, String date) {
    return _attendanceRecords.values
        .where((r) => r.classId == classId && r.date == date)
        .toList();
  }

  List<AttendanceRecord> getRecordsForStudent(String uid) {
    return _attendanceRecords.values.where((r) => r.uid == uid).toList();
  }

  Map<String, String> getStudentMonthlyStatus(
      String uid, String classId, int year, int month) {
    final Map<String, String> result = {};
    final records = _attendanceRecords.values.where((r) =>
        r.uid == uid &&
        r.classId == classId &&
        r.date.startsWith('$year-${month.toString().padLeft(2, '0')}'));

    for (final record in records) {
      result[record.date] = record.status;
    }
    return result;
  }

  Future<void> markAsSynced(String key) async {
    final record = _attendanceRecords.get(key);
    if (record != null) {
      record.isSynced = true;
      await _attendanceRecords.put(key, record);
    }
  }

  Future<void> markMultipleAsSynced(List<String> keys) async {
    for (final key in keys) {
      final record = _attendanceRecords.get(key);
      if (record != null) {
        record.isSynced = true;
        await _attendanceRecords.put(key, record);
      }
    }
  }

  bool hasRecord(String classId, String date, String uid, {int lectureSlot = 0}) {
    if (lectureSlot > 0) {
      final key = '${classId}_${date}_${lectureSlot}_$uid';
      return _attendanceRecords.containsKey(key);
    }
    // Fallback: check if any record exists for this day
    return _attendanceRecords.values.any(
      (r) => r.classId == classId && r.date == date && r.uid == uid,
    );
  }

  int get totalRecords => _attendanceRecords.length;

  int get unsyncedCount =>
      _attendanceRecords.values.where((r) => !r.isSynced).length;

  // ─── Attendance Stats ──────────────────────────────────
  double getAttendancePercentage(String uid, String classId) {
    final records = _attendanceRecords.values
        .where((r) => r.uid == uid && r.classId == classId)
        .toList();
    if (records.isEmpty) return 0.0;
    final present = records.where((r) => r.status == 'present').length;
    return (present / records.length) * 100;
  }

  Map<String, int> getMonthlyStats(
      String uid, String classId, int year, int month) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final records = _attendanceRecords.values
        .where((r) =>
            r.uid == uid && r.classId == classId && r.date.startsWith(prefix))
        .toList();

    int present = 0, absent = 0;
    for (final r in records) {
      if (r.status == 'present') {
        present++;
      } else {
        absent++;
      }
    }

    return {'present': present, 'absent': absent, 'total': records.length};
  }

  // ─── Settings ──────────────────────────────────────────
  Box get _settings => Hive.box(_settingsBox);

  Future<void> saveSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settings.get(key, defaultValue: defaultValue);
  }

  String getPiBaseUrl() {
    return _settings.get('piBaseUrl', defaultValue: 'http://192.168.4.1:5000');
  }

  Future<void> setPiBaseUrl(String url) async {
    await _settings.put('piBaseUrl', url);
  }

  // ─── Clear ─────────────────────────────────────────────
  Future<void> clearAll() async {
    await _attendanceRecords.clear();
  }
}
