import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../services/timetable_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/calendar_widget.dart';

class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({super.key});

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  final int _currentYear = DateTime.now().year;
  final int _currentMonth = DateTime.now().month;
  Map<String, String> _monthlyData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final attendance = Provider.of<AttendanceProvider>(context, listen: false);
    if (auth.user != null) {
      setState(() {
        _monthlyData = attendance.getMonthlyStatus(
          auth.user!.uid,
          auth.user!.classId,
          _currentYear,
          _currentMonth,
        );
      });
    }
  }

  void _showDayDetail(DateTime date) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final attendance = Provider.of<AttendanceProvider>(context, listen: false);
    final timetable = TimetableService();
    final user = auth.user;
    if (user == null) return;

    final weekday = date.weekday; // 1=Mon … 7=Sun
    final dateStr = Helpers.formatDate(date);
    final daySchedule = timetable.getDaySchedule(weekday);
    final dayRecords = attendance.getRecordsForDate(user.uid, user.classId, dateStr);

    // Map of lectureSlot -> AttendanceRecord for quick lookup
    final markedSlots = <int, String>{};
    for (final r in dayRecords) {
      markedSlots[r.lectureSlot] = r.status;
    }

    final dayName = TimetableService.dayName(weekday);
    final isToday = dateStr == Helpers.todayDate();
    final isFuture = date.isAfter(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF252540), Color(0xFF1A1A2E)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName,
                            style: AppTheme.headingSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Helpers.formatDisplayDate(date),
                            style: AppTheme.labelStyle.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.accentPurple.withOpacity(0.5)),
                        ),
                        child: Text('TODAY',
                            style: AppTheme.labelStyle
                                .copyWith(color: AppTheme.accentPurple)),
                      ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // Content
              Expanded(
                child: weekday == 7
                    ? _buildNoClassesView('Sunday — No Classes')
                    : daySchedule.isEmpty
                        ? _buildNoClassesView('No lectures scheduled')
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: daySchedule.length,
                            itemBuilder: (_, i) {
                              final slotGroup = daySchedule[i];
                              return _buildLectureCard(
                                slotGroup,
                                markedSlots,
                                isToday,
                                isFuture,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoClassesView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.weekend_rounded,
              size: 56, color: AppTheme.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(message, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildLectureCard(
    List<LectureSlot> slotGroup,
    Map<int, String> markedSlots,
    bool isToday,
    bool isFuture,
  ) {
    final isBatchSlot = slotGroup.length > 1;
    final first = slotGroup.first;
    final periodNum = first.periodNumber;

    // Determine attendance status for this slot
    final status = markedSlots[periodNum];
    final isPresent = status == 'present';
    final isAbsent = status == 'absent';
    final isMarked = status != null;

    // Status colors & icons
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isMarked) {
      statusColor = isPresent ? AppTheme.successGreen : AppTheme.errorRed;
      statusIcon = isPresent
          ? Icons.check_circle_rounded
          : Icons.cancel_rounded;
      statusText = isPresent ? 'Present' : 'Absent';
    } else if (isFuture) {
      statusColor = AppTheme.textSecondary;
      statusIcon = Icons.schedule_rounded;
      statusText = 'Upcoming';
    } else {
      statusColor = AppTheme.warningYellow;
      statusIcon = Icons.remove_circle_outline_rounded;
      statusText = 'Not Marked';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday && isMarked
              ? statusColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period number badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withOpacity(0.3),
                    AppTheme.accentBlue.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'P$periodNum',
                  style: AppTheme.labelStyle.copyWith(
                    color: AppTheme.accentPurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Lecture info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBatchSlot)
                    ...slotGroup.map((slot) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentTeal.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  slot.batch ?? '',
                                  style: AppTheme.labelStyle.copyWith(
                                    color: AppTheme.accentTeal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${slot.subject} (${slot.facultyInitials})',
                                  style: AppTheme.labelStyle.copyWith(
                                    color: AppTheme.textPrimary
                                        .withOpacity(0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                  else ...[
                    Text(
                      first.subject,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${first.facultyInitials}  •  ${first.room}',
                      style: AppTheme.labelStyle.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    first.timeRange,
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: AppTheme.labelStyle.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final attendance = Provider.of<AttendanceProvider>(context);
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();

    final stats = attendance.getMonthlyStats(
        user.uid, user.classId, _currentYear, _currentMonth);

    final present = stats['present'] ?? 0;
    final total = stats['total'] ?? 0;
    final monthPct = Helpers.attendancePercentage(present, total);

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
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Attendance Calendar', style: AppTheme.headingLarge),
              const SizedBox(height: 4),
              Text(user.classId, style: AppTheme.bodyMedium),
              const SizedBox(height: 24),

              // Calendar
              CalendarWidget(
                attendanceData: _monthlyData,
                onDayTap: (date) => _showDayDetail(date),
              ),
              const SizedBox(height: 20),

              // Monthly summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Summary', style: AppTheme.headingSmall),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _summaryItem(
                          'Present',
                          '$present',
                          AppTheme.successGreen,
                        ),
                        _summaryItem(
                          'Absent',
                          '${stats['absent'] ?? 0}',
                          AppTheme.errorRed,
                        ),
                        _summaryItem(
                          'Percentage',
                          Helpers.percentageText(monthPct),
                          monthPct >= 75
                              ? AppTheme.successGreen
                              : AppTheme.warningYellow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: total > 0 ? present / total : 0,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(
                          monthPct >= 75
                              ? AppTheme.successGreen
                              : monthPct >= 50
                                  ? AppTheme.warningYellow
                                  : AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.labelStyle),
        ],
      ),
    );
  }
}

