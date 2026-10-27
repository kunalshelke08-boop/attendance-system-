import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../services/timetable_service.dart';
import '../../utils/theme.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh lecture info every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final attendance = Provider.of<AttendanceProvider>(context, listen: false);
      attendance.refreshCurrentLecture();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final attendance = Provider.of<AttendanceProvider>(context);
    final connectivity = Provider.of<ConnectivityProvider>(context);
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();

    final currentLecture = attendance.currentLecture;
    final activeLecture = attendance.getActiveLecture();
    final alreadyMarked = activeLecture != null &&
        attendance.isCurrentLectureMarked(user.uid, user.classId);

    // Determine if marking should be disabled
    final bool canMark = currentLecture.status == 'in_lecture' &&
        activeLecture != null &&
        !alreadyMarked &&
        attendance.markingStatus != MarkingStatus.authenticating &&
        attendance.markingStatus != MarkingStatus.sending;

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
                const SizedBox(height: 12),
                Text('Mark Attendance', style: AppTheme.headingLarge),
                const SizedBox(height: 4),
                Text(
                  _getDayDateLabel(),
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // ─── Current Lecture Info Card ───────────────────
                _buildLectureInfoCard(currentLecture, activeLecture, alreadyMarked),
                const SizedBox(height: 12),

                // ─── Batch Selector (if batch lecture) ──────────
                if (currentLecture.batchLectures != null &&
                    currentLecture.status == 'in_lecture')
                  _buildBatchSelector(attendance, currentLecture.batchLectures!),

                const Spacer(),

                // Status display
                _buildStatusUI(attendance, alreadyMarked, activeLecture),

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
                    onPressed: canMark
                        ? () async {
                            await attendance.markAttendance(
                              uid: user.uid,
                              name: user.name,
                              classId: user.classId,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alreadyMarked
                          ? AppTheme.successGreen.withOpacity(0.3)
                          : (canMark
                              ? AppTheme.accentPurple
                              : AppTheme.cardDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      alreadyMarked
                          ? 'Already Marked ✓'
                          : (currentLecture.status == 'in_lecture'
                              ? 'Authenticate & Mark'
                              : 'No Active Lecture'),
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

  String _getDayDateLabel() {
    final now = DateTime.now();
    final dayName = TimetableService.dayName(now.weekday);
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '$dayName, ${now.day} ${months[now.month]} ${now.year}';
  }

  Widget _buildLectureInfoCard(
    CurrentLectureInfo info,
    LectureSlot? activeLecture,
    bool alreadyMarked,
  ) {
    Color accentColor;
    IconData icon;
    String title;
    String subtitle;

    switch (info.status) {
      case 'in_lecture':
        accentColor = AppTheme.accentTeal;
        icon = Icons.school_rounded;
        if (activeLecture != null) {
          title = activeLecture.subject;
          subtitle =
              'Faculty: ${activeLecture.facultyInitials}  •  ${activeLecture.periodLabel}  •  ${activeLecture.room}';
        } else {
          title = 'Batch Lecture';
          subtitle = 'Select your batch below';
        }
        break;
      case 'break':
        accentColor = AppTheme.warningYellow;
        icon = Icons.coffee_rounded;
        title = 'Break Time';
        subtitle = info.message;
        break;
      case 'before_college':
        accentColor = AppTheme.textSecondary;
        icon = Icons.wb_sunny_rounded;
        title = 'Before College Hours';
        subtitle = info.message;
        break;
      case 'after_college':
        accentColor = AppTheme.textSecondary;
        icon = Icons.nights_stay_rounded;
        title = 'College Over';
        subtitle = info.message;
        break;
      case 'sunday':
        accentColor = AppTheme.accentPurple;
        icon = Icons.weekend_rounded;
        title = 'Sunday';
        subtitle = info.message;
        break;
      case 'no_class':
        accentColor = AppTheme.textSecondary;
        icon = Icons.event_busy_rounded;
        title = 'Free Period';
        subtitle = info.message;
        break;
      default:
        accentColor = AppTheme.textSecondary;
        icon = Icons.info_rounded;
        title = 'Loading...';
        subtitle = '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.15),
            accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.2),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTheme.headingSmall.copyWith(
                          color: accentColor,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (alreadyMarked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MARKED ✓',
                          style: TextStyle(
                            color: AppTheme.successGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.bodyMedium.copyWith(fontSize: 13),
                ),
                if (info.nextLectureTime != null && info.status != 'in_lecture')
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Next lecture at ${LectureSlot.formatTime(info.nextLectureTime!)}',
                      style: AppTheme.labelStyle.copyWith(
                        color: AppTheme.accentTeal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchSelector(
    AttendanceProvider attendance,
    List<LectureSlot> batchLectures,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT YOUR BATCH',
            style: AppTheme.labelStyle.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: batchLectures.map((lecture) {
              final isSelected = attendance.selectedBatch == lecture.batch;
              return GestureDetector(
                onTap: () => attendance.setSelectedBatch(lecture.batch),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentPurple.withOpacity(0.3)
                        : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentPurple
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        lecture.batch ?? '',
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.accentPurple
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lecture.subject} (${lecture.facultyInitials})',
                        style: AppTheme.labelStyle.copyWith(
                          fontSize: 11,
                          color: isSelected
                              ? AppTheme.accentPurple.withOpacity(0.8)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUI(
    AttendanceProvider attendance,
    bool alreadyMarked,
    LectureSlot? activeLecture,
  ) {
    IconData icon;
    Color color;
    String text;
    double size = 120;

    if (alreadyMarked) {
      icon = Icons.check_circle_rounded;
      color = AppTheme.successGreen;
      text =
          'Attendance Marked!\n${activeLecture?.subject ?? ''} (${activeLecture?.facultyInitials ?? ''})';
    } else if (attendance.currentLecture.status != 'in_lecture') {
      icon = Icons.schedule_rounded;
      color = AppTheme.textSecondary;
      text = 'Waiting for a lecture...';
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
