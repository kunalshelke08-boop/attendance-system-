import 'dart:convert';
import 'package:http/http.dart' as http;

class PiApiService {
  String _baseUrl = 'http://192.168.4.1:5000';

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// Mark attendance on Raspberry Pi
  Future<Map<String, dynamic>> markAttendance({
    required String uid,
    required String name,
    required String timestamp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/mark'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'uid': uid,
              'name': name,
              'timestamp': timestamp,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Pi server error: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to Raspberry Pi: $e');
    }
  }

  /// Get real-time attendance list from Pi (Teacher use)
  Future<List<Map<String, dynamic>>> getAttendanceList() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/attendance_list'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> students = data['students'] ?? [];
        return students.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Pi server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch attendance from Pi: $e');
    }
  }

  /// Start an attendance session on Pi
  Future<bool> startSession({
    required String classId,
    required int durationMinutes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/session/start'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'classId': classId,
              'duration': durationMinutes,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to start session on Pi: $e');
    }
  }

  /// Stop the current session on Pi
  Future<bool> stopSession() async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/session/stop'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to stop session on Pi: $e');
    }
  }

  /// Get full server status including session_active flag
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/ping'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'session_active': false};
    } catch (e) {
      return {'status': 'error', 'session_active': false};
    }
  }
}
