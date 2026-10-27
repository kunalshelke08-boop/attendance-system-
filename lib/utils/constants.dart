import 'package:flutter/material.dart';

class AppConstants {
  // Raspberry Pi defaults
  static const String defaultPiUrl = 'http://192.168.4.1:5000';

  // Roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';

  // Attendance statuses
  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusHoliday = 'holiday';

  // Mark methods
  static const String markBiometric = 'biometric';
  static const String markManual = 'manual';

  // Colors for attendance
  static const Color presentColor = Color(0xFF4CAF50);
  static const Color absentColor = Color(0xFFE53935);
  static const Color holidayColor = Color(0xFFFFC107);

  // Class options
  static const List<String> classOptions = [
    'IIOT-7',
    'CS-A',
    'CS-B',
    'IT-A',
    'IT-B',
    'EC-A',
  ];

  // Session duration options (minutes)
  static const List<int> sessionDurations = [5, 10, 15, 20, 30, 45, 60];

  // Holidays (yyyy-MM-dd format) — customizable
  static const List<String> holidays = [
    '2026-01-26',
    '2026-03-14',
    '2026-08-15',
    '2026-10-02',
    '2026-11-01',
    '2026-12-25',
  ];

  static bool isHoliday(String date) => holidays.contains(date);

  static bool isWeekend(DateTime date) =>
      date.weekday == DateTime.sunday;
}
