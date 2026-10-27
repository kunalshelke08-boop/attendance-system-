import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../services/timetable_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/sync_indicator.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final TimetableService _timetable = TimetableService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final attendance = Provider.of<AttendanceProvider>(context, listen: false);
    final session = Provider.of<SessionProvider>(context, listen: false);
    if (auth.user != null) {
      attendance.loadTodayRecords(auth.user!.classId);
      session.checkActiveSession(auth.user!.classId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final attendance = Provider.of<AttendanceProvider>(context);
    final session = Provider.of<SessionProvider>(context);
    final connectivity = Provider.of<ConnectivityProvider>(context);
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();

    final todayRecords = attendance.todayRecords;
    final presentCount =
        todayRecords.where((r) => r.status == 'present').length;
    final currentLecture = _timetable.getCurrentLecture();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _loadData(),
            color: AppTheme.accentPurple,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Helpers.greetingMessage(),
                              style: AppTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            user.name,
                            style: AppTheme.headingLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const SyncIndicator(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(user.classId,
                          style: AppTheme.labelStyle.copyWith(
                              color: AppTheme.accentPurple,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    if (user.subject.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentTeal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(user.subject,
                            style: AppTheme.labelStyle.copyWith(
                                color: AppTheme.accentTeal,
                                fontWeight: FontWeight.w700)),
                      ),
                    const Spacer(),
                    Text(
                      Helpers.formatDisplayDate(DateTime.now()),
                      style: AppTheme.labelStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Current lecture info
                _buildCurrentLectureCard(currentLecture),
                const SizedBox(height: 16),

                // Active session card
                if (session.hasActiveSession) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.successGreen.withOpacity(0.2),
                          AppTheme.accentTeal.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.successGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_rounded,
                            color: AppTheme.successGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Session Active',
                                style: TextStyle(
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Time remaining: ${session.remainingText}',
                                style: AppTheme.labelStyle,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => session.stopSession(),
                          icon: const Icon(
                            Icons.stop_circle_rounded,
                            color: AppTheme.errorRed,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassCard,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.textSecondary.withOpacity(0.6),
                            size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No active session. Start one to begin taking attendance.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Present Today',
                        value: '$presentCount',
                        icon: Icons.people_rounded,
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Total Records',
                        value: '${todayRecords.length}',
                        icon: Icons.assignment_rounded,
                        color: AppTheme.accentPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Pi Status',
                        value:
                            connectivity.isPiReachable ? 'Online' : 'Offline',
                        icon: connectivity.isPiReachable
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        color: connectivity.isPiReachable
                            ? AppTheme.accentTeal
                            : AppTheme.errorRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Internet',
                        value:
                            connectivity.isOnline ? 'Connected' : 'No Net',
                        icon: connectivity.isOnline
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: connectivity.isOnline
                            ? AppTheme.successGreen
                            : AppTheme.warningYellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Today's attendance list
                Text('Today\'s Attendance', style: AppTheme.headingSmall),
                const SizedBox(height: 12),

                if (todayRecords.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.glassCard,
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.group_off_rounded,
                              size: 48,
                              color:
                                  AppTheme.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text('No attendance marked yet.',
                              style: AppTheme.bodyMedium),
                        ],
                      ),
                    ),
                  )
                else
                  ...todayRecords.map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: AppTheme.glassCard,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  r.name.isNotEmpty
                                      ? r.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name,
                                      style: AppTheme.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (r.subject.isNotEmpty) ...[
                                        Text(
                                          '${r.subject} · P${r.lectureSlot}',
                                          style: AppTheme.labelStyle.copyWith(
                                              color: AppTheme.accentTeal),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('·',
                                            style: AppTheme.labelStyle),
                                        const SizedBox(width: 6),
                                      ],
                                      Flexible(
                                        child: Text(
                                          Helpers.formatTimestamp(
                                              r.timestamp),
                                          style: AppTheme.labelStyle,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: AppTheme.statusBadge(
                                r.status == 'present'
                                    ? AppTheme.successGreen
                                    : AppTheme.errorRed,
                              ),
                              child: Text(
                                r.status.toUpperCase(),
                                style: AppTheme.labelStyle.copyWith(
                                  color: r.status == 'present'
                                      ? AppTheme.successGreen
                                      : AppTheme.errorRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLectureCard(CurrentLectureInfo info) {
    Color statusColor;
    IconData statusIcon;

    switch (info.status) {
      case 'in_lecture':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.menu_book_rounded;
        break;
      case 'break':
        statusColor = AppTheme.warningYellow;
        statusIcon = Icons.coffee_rounded;
        break;
      default:
        statusColor = AppTheme.textSecondary;
        statusIcon = Icons.schedule_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.15),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.status == 'in_lecture' ? 'Current Lecture' : 'Status',
                  style: AppTheme.labelStyle.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.message,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (info.hasLecture && info.lecture != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${info.lecture!.timeRange} · ${info.lecture!.room}',
                    style: AppTheme.labelStyle,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
