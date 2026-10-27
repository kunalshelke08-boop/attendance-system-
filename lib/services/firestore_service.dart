import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users ─────────────────────────────────────────────
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<List<UserModel>> getStudentsByClass(String classId) async {
    final snap = await _db
        .collection('users')
        .where('classId', isEqualTo: classId)
        .where('role', isEqualTo: 'student')
        .get();
    return snap.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .toList();
  }

  // ─── Attendance ────────────────────────────────────────
  /// Firestore doc ID includes lecture slot so multiple lectures/day are stored separately
  String _attendanceDocId(AttendanceRecord record) {
    if (record.lectureSlot > 0) {
      return '${record.uid}_L${record.lectureSlot}';
    }
    return record.uid; // backward compat for old records
  }

  Future<void> uploadAttendance(AttendanceRecord record) async {
    await _db
        .collection('attendance')
        .doc(record.classId)
        .collection('records')
        .doc(record.date)
        .collection('students')
        .doc(_attendanceDocId(record))
        .set(record.toMap(), SetOptions(merge: true));
  }

  Future<void> batchUploadAttendance(List<AttendanceRecord> records) async {
    final batch = _db.batch();
    for (final record in records) {
      final ref = _db
          .collection('attendance')
          .doc(record.classId)
          .collection('records')
          .doc(record.date)
          .collection('students')
          .doc(_attendanceDocId(record));
      batch.set(ref, record.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<AttendanceRecord>> getAttendanceByDate(
      String classId, String date) async {
    final snap = await _db
        .collection('attendance')
        .doc(classId)
        .collection('records')
        .doc(date)
        .collection('students')
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      data['uid'] = d.id;
      data['classId'] = classId;
      data['date'] = date;
      return AttendanceRecord.fromMap(data);
    }).toList();
  }

  Future<Map<String, String>> getAttendanceForStudent(
      String classId, String uid, int year, int month) async {
    final Map<String, String> result = {};
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    for (var d = startDate;
        d.isBefore(endDate.add(Duration(days: 1)));
        d = d.add(Duration(days: 1))) {
      final dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final doc = await _db
          .collection('attendance')
          .doc(classId)
          .collection('records')
          .doc(dateStr)
          .collection('students')
          .doc(uid)
          .get();

      if (doc.exists) {
        result[dateStr] = doc.data()?['status'] ?? 'present';
      }
    }
    return result;
  }

  Future<void> updateAttendanceStatus(
      String classId, String date, String uid, String status) async {
    await _db
        .collection('attendance')
        .doc(classId)
        .collection('records')
        .doc(date)
        .collection('students')
        .doc(uid)
        .update({'status': status});
  }

  // ─── Sessions ──────────────────────────────────────────
  Future<void> createSession(SessionModel session) async {
    await _db
        .collection('sessions')
        .doc(session.sessionId)
        .set(session.toMap());
  }

  Future<void> stopSession(String sessionId) async {
    await _db.collection('sessions').doc(sessionId).update({
      'isActive': false,
      'endTime': DateTime.now().toIso8601String(),
    });
  }

  Future<SessionModel?> getActiveSession(String classId) async {
    final snap = await _db
        .collection('sessions')
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return SessionModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Stream<QuerySnapshot> getSessionsStream(String classId) {
    return _db
        .collection('sessions')
        .where('classId', isEqualTo: classId)
        .orderBy('startTime', descending: true)
        .limit(30)
        .snapshots();
  }

  // ─── Messages (Query/Chat) ─────────────────────────────
  Future<void> sendMessage({
    required String classId,
    required String senderUid,
    required String senderName,
    required String text,
    required String role,
  }) async {
    await _db
        .collection('messages')
        .doc(classId)
        .collection('chat')
        .add({
      'senderUid': senderUid,
      'senderName': senderName,
      'text': text,
      'role': role,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMessagesStream(String classId) {
    return _db
        .collection('messages')
        .doc(classId)
        .collection('chat')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
