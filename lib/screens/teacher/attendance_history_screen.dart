import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/local_storage_service.dart';
import '../../services/timetable_service.dart';
import '../../models/attendance_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import 'edit_attendance_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<AttendanceRecord> _records = [];
  final TimetableService _timetable = TimetableService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecords());
  }

  void _loadRecords() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final localStorage =
        Provider.of<LocalStorageService>(context, listen: false);
    if (auth.user != null) {
      setState(() {
        _records = localStorage.getRecordsByDate(
          auth.user!.classId,
          Helpers.formatDate(_selectedDate),
        );
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentPurple,
              surface: AppTheme.cardDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadRecords();
    }
  }

  /// Group records by lecture slot
  Map<int, List<AttendanceRecord>> _groupByLecture() {
    final map = <int, List<AttendanceRecord>>{};
    for (final r in _records) {
      final slot = r.lectureSlot > 0 ? r.lectureSlot : 0;
      map.putIfAbsent(slot, () => []).add(r);
    }
    // Sort by slot number
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _records.where((r) => r.status == 'present').length;
    final absentCount = _records.where((r) => r.status == 'absent').length;
    final grouped = _groupByLecture();
    final weekday = _selectedDate.weekday;
    final daySchedule = _timetable.getDaySchedule(weekday);

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance History',
                        style: AppTheme.headingLarge),
                    const SizedBox(height: 16),

                    // Date picker
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: AppTheme.glassCard,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppTheme.accentPurple, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Helpers.formatDisplayDate(_selectedDate),
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    TimetableService.dayName(weekday),
                                    style: AppTheme.labelStyle,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Summary chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _summaryChip(
                            '$presentCount Present', AppTheme.successGreen),
                        _summaryChip(
                            '$absentCount Absent', AppTheme.errorRed),
                        _summaryChip(
                            '${_records.length} Total', AppTheme.accentPurple),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),

              // Records list — grouped by lecture
              Expanded(
                child: _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded,
                                size: 56,
                                color: AppTheme.textSecondary
                                    .withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'No records for this date',
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final entry = grouped.entries.elementAt(index);
                          final slot = entry.key;
                          final slotRecords = entry.value;
                          return _buildLectureGroup(
                              slot, slotRecords, daySchedule);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      // FAB to edit attendance
      floatingActionButton: _records.isNotEmpty
          ? FloatingActionButton.small(
              onPressed: () => _showEditDialog(),
              backgroundColor: AppTheme.accentPurple,
              child: const Icon(Icons.edit_rounded, size: 20),
            )
          : null,
    );
  }

  Widget _buildLectureGroup(
    int slot,
    List<AttendanceRecord> records,
    List<List<LectureSlot>> daySchedule,
  ) {
    // Find the matching timetable entry for this slot
    String lectureTitle;
    String lectureSubtitle = '';
    if (slot == 0) {
      lectureTitle = 'Unassigned';
      lectureSubtitle = 'Records without a lecture slot';
    } else {
      // Try to find from records first (they have subject info)
      final firstWithSubject = records.firstWhere(
        (r) => r.subject.isNotEmpty,
        orElse: () => records.first,
      );
      if (firstWithSubject.subject.isNotEmpty) {
        lectureTitle =
            'P$slot · ${firstWithSubject.subject} (${firstWithSubject.facultyInitials})';
      } else {
        // Fallback to timetable
        LectureSlot? timetableSlot;
        for (final group in daySchedule) {
          if (group.first.periodNumber == slot) {
            timetableSlot = group.first;
            break;
          }
        }
        if (timetableSlot != null) {
          lectureTitle =
              'P$slot · ${timetableSlot.subject} (${timetableSlot.facultyInitials})';
          lectureSubtitle = timetableSlot.timeRange;
        } else {
          lectureTitle = 'Period $slot';
        }
      }
    }

    final presentInSlot = records.where((r) => r.status == 'present').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lecture header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentPurple.withOpacity(0.15),
                  AppTheme.accentBlue.withOpacity(0.08),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: AppTheme.accentPurple, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lectureTitle,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (lectureSubtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(lectureSubtitle, style: AppTheme.labelStyle),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$presentInSlot / ${records.length}',
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Student list for this lecture
          ...records.map((r) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
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
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name & time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${Helpers.formatTimestamp(r.timestamp)} · via ${r.markedVia}',
                            style: AppTheme.labelStyle.copyWith(
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
    );
  }

  Widget _summaryChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTheme.labelStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showEditDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAttendanceScreen(
          classId: auth.user!.classId,
          date: Helpers.formatDate(_selectedDate),
        ),
      ),
    );
  }
}
