import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/local_storage_service.dart';
import '../services/pi_api_service.dart';
import '../services/biometric_service.dart';
import '../services/timetable_service.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

enum MarkingStatus { idle, authenticating, sending, success, error }

class AttendanceProvider extends ChangeNotifier {
  final LocalStorageService _localStorage;
  final PiApiService _piApi;
  final BiometricService _biometricService;
  final TimetableService _timetableService;

  MarkingStatus _markingStatus = MarkingStatus.idle;
  String _markingMessage = '';
  List<AttendanceRecord> _todayRecords = [];
  List<Map<String, dynamic>> _piAttendanceList = [];
  CurrentLectureInfo _currentLecture = const CurrentLectureInfo(
    status: 'idle',
    message: 'Checking timetable...',
  );

  // For batch lecture selection
  String? _selectedBatch;

  MarkingStatus get markingStatus => _markingStatus;
  String get markingMessage => _markingMessage;
  List<AttendanceRecord> get todayRecords => _todayRecords;
  List<Map<String, dynamic>> get piAttendanceList => _piAttendanceList;
  CurrentLectureInfo get currentLecture => _currentLecture;
  TimetableService get timetableService => _timetableService;
  String? get selectedBatch => _selectedBatch;

  AttendanceProvider(
    this._localStorage,
    this._piApi,
    this._biometricService,
    this._timetableService,
  ) {
    refreshCurrentLecture();
  }

  /// Refresh the current lecture info based on current time
  void refreshCurrentLecture() {
    _currentLecture = _timetableService.getCurrentLecture();
    notifyListeners();
  }

  /// Set the selected batch for batch lecture slots
  void setSelectedBatch(String? batch) {
    _selectedBatch = batch;
    notifyListeners();
  }

  /// Get the active lecture slot (handles batch selection)
  LectureSlot? getActiveLecture() {
    if (_currentLecture.lecture != null) {
      return _currentLecture.lecture;
    }
    if (_currentLecture.batchLectures != null && _selectedBatch != null) {
      return _currentLecture.batchLectures!.firstWhere(
        (l) => l.batch == _selectedBatch,
        orElse: () => _currentLecture.batchLectures!.first,
      );
    }
    return null;
  }

  /// Full attendance marking flow: biometric → Pi → local save
  /// Now auto-attaches subject, faculty, and lecture slot
  Future<bool> markAttendance({
    required String uid,
    required String name,
    required String classId,
  }) async {
    final today = Helpers.todayDate();

    // Refresh lecture info
    refreshCurrentLecture();

    // Get the active lecture
    final activeLecture = getActiveLecture();
    if (activeLecture == null) {
      _markingStatus = MarkingStatus.error;
      _markingMessage = _currentLecture.status == 'in_lecture'
          ? 'Please select your batch first.'
          : 'No lecture is currently in session.';
      notifyListeners();
      return false;
    }

    final lectureSlot = activeLecture.periodNumber;

    // Check if already marked for THIS lecture
    if (_localStorage.hasRecord(classId, today, uid, lectureSlot: lectureSlot)) {
      _markingStatus = MarkingStatus.error;
      _markingMessage =
          'Attendance already marked for ${activeLecture.subject} (${activeLecture.periodLabel}).';
      notifyListeners();
      return false;
    }

    // Step 1: Biometric auth
    _markingStatus = MarkingStatus.authenticating;
    _markingMessage = 'Authenticating biometrics...';
    notifyListeners();

    try {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        _markingStatus = MarkingStatus.error;
        _markingMessage = 'Biometric authentication failed.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _markingStatus = MarkingStatus.error;
      _markingMessage = e.toString();
      notifyListeners();
      return false;
    }

    // Step 2: Send to Raspberry Pi
    _markingStatus = MarkingStatus.sending;
    _markingMessage = 'Sending to attendance server...';
    notifyListeners();

    final timestamp = Helpers.currentTimestamp();
    bool piSuccess = false;

    try {
      await _piApi.markAttendance(
        uid: uid,
        name: name,
        timestamp: timestamp,
      );
      piSuccess = true;
    } catch (e) {
      // Continue even if Pi fails — offline-first
      print('Pi API failed: $e');
    }

    // Step 3: Save locally with lecture info
    final record = AttendanceRecord(
      uid: uid,
      name: name,
      classId: classId,
      date: today,
      timestamp: timestamp,
      status: AppConstants.statusPresent,
      markedVia: AppConstants.markBiometric,
      isSynced: false,
      subject: activeLecture.subject,
      facultyInitials: activeLecture.facultyInitials,
      lectureSlot: lectureSlot,
    );

    await _localStorage.saveAttendance(record);

    _markingStatus = MarkingStatus.success;
    _markingMessage = piSuccess
        ? '✓ ${activeLecture.subject} (${activeLecture.facultyInitials}) — Marked!'
        : '✓ ${activeLecture.subject} saved locally (Pi unreachable).';
    notifyListeners();

    await loadTodayRecords(classId);
    return true;
  }

  /// Load today's records for a class from local storage
  Future<void> loadTodayRecords(String classId) async {
    final today = Helpers.todayDate();
    _todayRecords = _localStorage.getRecordsByDate(classId, today);
    notifyListeners();
  }

  /// Get attendance records for a student
  List<AttendanceRecord> getStudentRecords(String uid) {
    return _localStorage.getRecordsForStudent(uid);
  }

  /// Get attendance records for a student on a specific date
  List<AttendanceRecord> getRecordsForDate(String uid, String classId, String date) {
    return _localStorage.getRecordsForStudent(uid)
        .where((r) => r.classId == classId && r.date == date)
        .toList()
      ..sort((a, b) => a.lectureSlot.compareTo(b.lectureSlot));
  }

  /// Get attendance percentage for a student
  double getStudentPercentage(String uid, String classId) {
    return _localStorage.getAttendancePercentage(uid, classId);
  }

  /// Get monthly status map for calendar
  Map<String, String> getMonthlyStatus(
      String uid, String classId, int year, int month) {
    return _localStorage.getStudentMonthlyStatus(uid, classId, year, month);
  }

  /// Get monthly stats
  Map<String, int> getMonthlyStats(
      String uid, String classId, int year, int month) {
    return _localStorage.getMonthlyStats(uid, classId, year, month);
  }

  /// Poll attendance list from Pi (for teacher)
  Future<void> fetchPiAttendanceList() async {
    try {
      _piAttendanceList = await _piApi.getAttendanceList();
      notifyListeners();
    } catch (e) {
      print('Failed to fetch Pi attendance: $e');
    }
  }

  /// Check if today already marked for the current lecture
  bool isCurrentLectureMarked(String uid, String classId) {
    final activeLecture = getActiveLecture();
    if (activeLecture == null) return false;
    return _localStorage.hasRecord(
      classId,
      Helpers.todayDate(),
      uid,
      lectureSlot: activeLecture.periodNumber,
    );
  }

  /// Legacy: Check if any attendance marked today
  bool isTodayMarked(String uid, String classId) {
    return _localStorage.hasRecord(classId, Helpers.todayDate(), uid);
  }

  void resetStatus() {
    _markingStatus = MarkingStatus.idle;
    _markingMessage = '';
    notifyListeners();
  }
}
