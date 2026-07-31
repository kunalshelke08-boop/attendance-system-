import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../utils/theme.dart';

class MarkAttendanceScreen extends StatelessWidget {
  const MarkAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final attendance = Provider.of<AttendanceProvider>(context);
    final connectivity = Provider.of<ConnectivityProvider>(context);
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();

    final alreadyMarked = attendance.isTodayMarked(user.uid, user.classId);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text('Mark Attendance', style: AppTheme.headingLarge),
                const SizedBox(height: 8),
                Text(
                  'Authenticate with biometrics',
                  style: AppTheme.bodyMedium,
                ),
                const Spacer(),

                // Status display
                _buildStatusUI(attendance, alreadyMarked),

                const Spacer(),

                // Connection info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCard,
                  child: Row(
                    children: [
                      Icon(
                        connectivity.isPiReachable
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        color: connectivity.isPiReachable
                            ? AppTheme.successGreen
                            : AppTheme.errorRed,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          connectivity.isPiReachable
                              ? (connectivity.isSessionActive
                                  ? 'Connected to Server (Session Active)'
                                  : 'Connected to Server (Waiting for Teacher...)')
                              : 'Server unreachable — will save locally',
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Mark button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: alreadyMarked ||
                            attendance.markingStatus == MarkingStatus.authenticating ||
                            attendance.markingStatus == MarkingStatus.sending ||
                            (connectivity.isPiReachable && !connectivity.isSessionActive)
                        ? null
                        : () async {
                            await attendance.markAttendance(
                              uid: user.uid,
                              name: user.name,
                              classId: user.classId,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alreadyMarked
                          ? AppTheme.successGreen.withOpacity(0.3)
                          : AppTheme.accentPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      alreadyMarked
                          ? 'Already Marked Today ✓'
                          : 'Authenticate & Mark',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusUI(AttendanceProvider attendance, bool alreadyMarked) {
    IconData icon;
    Color color;
    String text;
    double size = 120;

    if (alreadyMarked) {
      icon = Icons.check_circle_rounded;
      color = AppTheme.successGreen;
      text = 'Attendance Marked!';
    } else {
      switch (attendance.markingStatus) {
        case MarkingStatus.idle:
          icon = Icons.fingerprint_rounded;
          color = AppTheme.accentPurple;
          text = 'Tap below to mark attendance';
          break;
        case MarkingStatus.authenticating:
          icon = Icons.fingerprint_rounded;
          color = AppTheme.warningYellow;
          text = 'Authenticating...';
          break;
        case MarkingStatus.sending:
          icon = Icons.cloud_upload_rounded;
          color = AppTheme.accentTeal;
          text = 'Sending to server...';
          break;
        case MarkingStatus.success:
          icon = Icons.check_circle_rounded;
          color = AppTheme.successGreen;
          text = attendance.markingMessage;
          break;
        case MarkingStatus.error:
          icon = Icons.error_rounded;
          color = AppTheme.errorRed;
          text = attendance.markingMessage;
          break;
      }
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3), width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(icon, size: 56, color: color),
        ),
        const SizedBox(height: 20),
        Text(
          text,
          style: AppTheme.bodyLarge.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
