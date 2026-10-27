/// Timetable service for 7th Semester IIoT
/// St. Vincent Pallotti College of Engineering and Technology, Nagpur
/// Academic Year: 2026–27 | Effective: 15 Sep 2026 | Version 6

class LectureSlot {
  final String startTime; // "09:00"
  final String endTime;   // "10:00"
  final int periodNumber; // 1–6
  final String subject;
  final String facultyInitials;
  final String room;
  final String? batch; // null for common lectures, "B1"/"B2"/"B3" for batches

  const LectureSlot({
    required this.startTime,
    required this.endTime,
    required this.periodNumber,
    required this.subject,
    required this.facultyInitials,
    required this.room,
    this.batch,
  });

  /// Human-readable label like "II&I4.0 (RS)"
  String get displayLabel {
    if (batch != null) {
      return '$subject ($batch) ($facultyInitials)';
    }
    return '$subject ($facultyInitials)';
  }

  /// Short label for the attendance record
  String get shortLabel => subject;

  /// Period label like "1st Lecture"
  String get periodLabel {
    const suffixes = ['st', 'nd', 'rd', 'th', 'th', 'th'];
    return '${periodNumber}${suffixes[periodNumber - 1]} Lecture';
  }

  /// Time range like "9:00 AM – 10:00 AM"
  String get timeRange {
    return '${formatTime(startTime)} – ${formatTime(endTime)}';
  }

  static String formatTime(String time24) {
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }
}

class CurrentLectureInfo {
  final LectureSlot? lecture;
  final List<LectureSlot>? batchLectures; // non-null if it's a batch slot
  final String status; // 'in_lecture', 'break', 'no_class', 'before_college', 'after_college', 'sunday'
  final String message;
  final String? nextLectureTime; // when does the next lecture start

  const CurrentLectureInfo({
    this.lecture,
    this.batchLectures,
    required this.status,
    required this.message,
    this.nextLectureTime,
  });

  bool get hasLecture => lecture != null || (batchLectures != null && batchLectures!.isNotEmpty);
}

class TimetableService {
  // ─── Lecture Time Definitions ────────────────────────────
  static const List<Map<String, String>> lectureTimings = [
    {'start': '09:00', 'end': '10:00', 'period': '1'},
    {'start': '10:00', 'end': '11:00', 'period': '2'},
    // Short Break: 11:00 – 11:15
    {'start': '11:15', 'end': '12:15', 'period': '3'},
    {'start': '12:15', 'end': '13:15', 'period': '4'},
    // Long Break: 13:15 – 14:15
    {'start': '14:15', 'end': '15:15', 'period': '5'},
    {'start': '15:15', 'end': '16:15', 'period': '6'},
  ];

  // ─── Full Timetable Data ────────────────────────────────
  // Day index: 1=Monday, 2=Tuesday, ... 6=Saturday, 7=Sunday
  static final Map<int, List<List<LectureSlot>>> _timetable = {
    // ── Monday ──
    1: [
      [
        const LectureSlot(
          startTime: '09:00', endTime: '10:00', periodNumber: 1,
          subject: 'II&I4.0', facultyInitials: 'RS', room: 'BF-10',
        ),
      ],
      [
        const LectureSlot(
          startTime: '10:00', endTime: '11:00', periodNumber: 2,
          subject: 'CC', facultyInitials: 'SS', room: 'BF-10',
        ),
      ],
      [
        const LectureSlot(
          startTime: '11:15', endTime: '12:15', periodNumber: 3,
          subject: 'PROJECT-II', facultyInitials: '-', room: 'S-10',
        ),
      ],
      // No 4th lecture on Monday
      [
        const LectureSlot(
          startTime: '14:15', endTime: '15:15', periodNumber: 5,
          subject: 'PROJECT-II', facultyInitials: '-', room: 'S-10',
        ),
      ],
      [
        // Batch slot
        const LectureSlot(
          startTime: '15:15', endTime: '16:15', periodNumber: 6,
          subject: 'IIOT Lab', facultyInitials: 'TA', room: 'Lab',
          batch: 'B1',
        ),
        const LectureSlot(
          startTime: '15:15', endTime: '16:15', periodNumber: 6,
          subject: 'CC', facultyInitials: 'SS', room: 'Lab',
          batch: 'B2',
        ),
        const LectureSlot(
          startTime: '15:15', endTime: '16:15', periodNumber: 6,
          subject: 'PROJECT-II', facultyInitials: 'MAH', room: 'Lab',
          batch: 'B3',
        ),
      ],
    ],

    // ── Tuesday ──
    2: [
      [
        const LectureSlot(
          startTime: '09:00', endTime: '10:00', periodNumber: 1,
          subject: 'MDM-V', facultyInitials: 'TA', room: 'S-01 B',
        ),
      ],
      [
        const LectureSlot(
          startTime: '10:00', endTime: '11:00', periodNumber: 2,
          subject: 'SP', facultyInitials: 'VP', room: 'S-01 B',
        ),
      ],
      [
        const LectureSlot(
          startTime: '11:15', endTime: '12:15', periodNumber: 3,
          subject: 'PROJECT-II', facultyInitials: '-', room: 'S-03/S-04/S-05',
        ),
      ],
      [
        const LectureSlot(
          startTime: '12:15', endTime: '13:15', periodNumber: 4,
          subject: 'PROJECT-II', facultyInitials: '-', room: 'S-03/S-04/S-05',
        ),
      ],
      [
        const LectureSlot(
          startTime: '14:15', endTime: '15:15', periodNumber: 5,
          subject: 'CC', facultyInitials: 'SS', room: 'S-06',
        ),
      ],
      [
        const LectureSlot(
          startTime: '15:15', endTime: '16:15', periodNumber: 6,
          subject: 'PE-III', facultyInitials: 'TA', room: 'S-10',
        ),
      ],
    ],

    // ── Wednesday ──
    3: [
      [
        const LectureSlot(
          startTime: '09:00', endTime: '10:00', periodNumber: 1,
          subject: 'CC', facultyInitials: 'SS', room: 'S-01 B',
        ),
      ],
      [
        const LectureSlot(
          startTime: '10:00', endTime: '11:00', periodNumber: 2,
          subject: 'MDM-V', facultyInitials: 'TA', room: 'S-01 B',
        ),
      ],
      [
        const LectureSlot(
          startTime: '11:15', endTime: '12:15', periodNumber: 3,
          subject: 'II&I4.0', facultyInitials: 'RS', room: 'S-06',
        ),
      ],
      [
        const LectureSlot(
          startTime: '12:15', endTime: '13:15', periodNumber: 4,
          subject: 'SP', facultyInitials: 'VP', room: 'S-06',
        ),
      ],
      [
        const LectureSlot(
          startTime: '14:15', endTime: '15:15', periodNumber: 5,
          subject: 'PE-III', facultyInitials: 'TA', room: 'S-10',
        ),
      ],
      [
        const LectureSlot(
          startTime: '15:15', endTime: '16:15', periodNumber: 6,
          subject: 'Mentoring', facultyInitials: '-', room: 'S-10',
        ),
      ],
    ],

    // ── Thursday ──
    4: [
      [
        const LectureSlot(
          startTime: '09:00', endTime: '10:00', periodNumber: 1,
          subject: 'II&I4.0', facultyInitials: 'RS', room: 'BF-11',
        ),
      ],
      [
        const LectureSlot(
          startTime: '10:00', endTime: '11:00', periodNumber: 2,
          subject: 'MDM-V', facultyInitials: 'TA', room: 'BF-11',
        ),
      ],
      [
        const LectureSlot(
          startTime: '11:15', endTime: '12:15', periodNumber: 3,
          subject: 'SP', facultyInitials: 'VP', room: 'S-06',
        ),
      ],
      [
        const LectureSlot(
          startTime: '12:15', endTime: '13:15', periodNumber: 4,
          subject: 'PE-II', facultyInitials: 'TA', room: 'S-06',
        ),
      ],
      [
        // Batch slot
        const LectureSlot(
          startTime: '14:15', endTime: '15:15', periodNumber: 5,
          subject: 'IIOT Lab', facultyInitials: 'TA', room: 'Lab',
          batch: 'B2',
        ),
        const LectureSlot(
          startTime: '14:15', endTime: '15:15', periodNumber: 5,
          subject: 'CC', facultyInitials: 'SS', room: 'Lab',
          batch: 'B3',
        ),
        const LectureSlot(
          startTime: '14:15', endTime: '15:15', periodNumber: 5,
          subject: 'PROJECT-II', facultyInitials: 'VP', room: 'Lab',
          batch: 'B1',
        ),
      ],
      // No 6th lecture on Thursday
    ],

    // ── Friday ──
    5: [
      [
        const LectureSlot(
          startTime: '09:00', endTime: '10:00', periodNumber: 1,
          subject: 'PROJECT-II', facultyInitials: '-', room: 'S-03/S-04/S-05',
        ),
      ],
      // No 2nd lecture on Friday
      [
        const LectureSlot(
          startTime: '11:15', endTime: '12:15', periodNumber: 3,
          subject: 'II&I4.0', facultyInitials: 'RS', room: 'S-06',
        ),
      ],
      [
        const LectureSlot(
          startTime: '12:15', endTime: '13:15', periodNumber: 4,
          subject: 'PE-III', facultyInitials: 'TA', room: 'S-06',
        ),
      ],
      [
        // Batch slot
        const LectureSlot(
          startTime: '14:15', endTime: '15:15', periodNumber: 5,
          subject: 'IIOT Lab', facultyInitials: 'TA', room: 'Lab',
          batch: 'B3',
        ),
        const LectureSlot(
          startTime: '14:15', endTime: '15:15', periodNumber: 5,
          subject: 'CC', facultyInitials: 'SS', room: 'Lab',
          batch: 'B1',
        ),
        const LectureSlot(
          startTime: '14:15', endTime: '15:15', periodNumber: 5,
          subject: 'PROJECT-II', facultyInitials: 'RS', room: 'Lab',
          batch: 'B2',
        ),
      ],
      [
        const LectureSlot(
          startTime: '15:15', endTime: '16:15', periodNumber: 6,
          subject: 'Mentoring', facultyInitials: '-', room: '-',
        ),
      ],
    ],

    // ── Saturday ──
    6: [
      [
        const LectureSlot(
          startTime: '09:00', endTime: '10:00', periodNumber: 1,
          subject: 'PE-III', facultyInitials: 'TA', room: 'S-01 B',
        ),
      ],
      [
        const LectureSlot(
          startTime: '10:00', endTime: '11:00', periodNumber: 2,
          subject: 'CC', facultyInitials: 'SS', room: 'S-01 B',
        ),
      ],
      [
        const LectureSlot(
          startTime: '11:15', endTime: '12:15', periodNumber: 3,
          subject: 'Library', facultyInitials: '-', room: 'Library',
        ),
      ],
      [
        const LectureSlot(
          startTime: '12:15', endTime: '13:15', periodNumber: 4,
          subject: 'CC Activity', facultyInitials: '-', room: '-',
        ),
      ],
      [
        const LectureSlot(
          startTime: '14:15', endTime: '15:15', periodNumber: 5,
          subject: 'CC Activity', facultyInitials: '-', room: '-',
        ),
      ],
      [
        const LectureSlot(
          startTime: '15:15', endTime: '16:15', periodNumber: 6,
          subject: 'CC Activity', facultyInitials: '-', room: '-',
        ),
      ],
    ],

    // ── Sunday — No classes ──
    7: [],
  };

  /// Get the current lecture info based on the current time
  CurrentLectureInfo getCurrentLecture({DateTime? overrideTime}) {
    final now = overrideTime ?? DateTime.now();
    final dayOfWeek = now.weekday; // 1=Mon … 7=Sun
    final currentMinutes = now.hour * 60 + now.minute;

    // Sunday check
    if (dayOfWeek == 7) {
      return const CurrentLectureInfo(
        status: 'sunday',
        message: 'No classes on Sunday',
      );
    }

    // Before college
    if (currentMinutes < 9 * 60) {
      final daySlots = _timetable[dayOfWeek] ?? [];
      final firstSubject = daySlots.isNotEmpty ? daySlots.first.first.displayLabel : 'class';
      return CurrentLectureInfo(
        status: 'before_college',
        message: 'College starts at 9:00 AM',
        nextLectureTime: '09:00',
      );
    }

    // After college
    if (currentMinutes >= 16 * 60 + 15) {
      return const CurrentLectureInfo(
        status: 'after_college',
        message: 'College hours are over for today',
      );
    }

    // Get today's schedule
    final daySlots = _timetable[dayOfWeek] ?? [];
    if (daySlots.isEmpty) {
      return const CurrentLectureInfo(
        status: 'no_class',
        message: 'No classes scheduled today',
      );
    }

    // Check if we're in a break
    // Short break: 11:00 – 11:15
    if (currentMinutes >= 11 * 60 && currentMinutes < 11 * 60 + 15) {
      return const CurrentLectureInfo(
        status: 'break',
        message: 'Short Break (11:00 – 11:15 AM)',
        nextLectureTime: '11:15',
      );
    }
    // Long break: 1:15 PM – 2:15 PM
    if (currentMinutes >= 13 * 60 + 15 && currentMinutes < 14 * 60 + 15) {
      return const CurrentLectureInfo(
        status: 'break',
        message: 'Lunch Break (1:15 – 2:15 PM)',
        nextLectureTime: '14:15',
      );
    }

    // Find which lecture slot we're currently in
    for (final slotGroup in daySlots) {
      final first = slotGroup.first;
      final startParts = first.startTime.split(':');
      final endParts = first.endTime.split(':');
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      if (currentMinutes >= startMin && currentMinutes < endMin) {
        if (slotGroup.length == 1) {
          // Single lecture
          return CurrentLectureInfo(
            lecture: slotGroup.first,
            status: 'in_lecture',
            message: slotGroup.first.displayLabel,
          );
        } else {
          // Batch lectures — return all, user picks their batch
          return CurrentLectureInfo(
            batchLectures: slotGroup,
            status: 'in_lecture',
            message: 'Batch Lecture — Select your batch',
          );
        }
      }
    }

    // We're within college hours but between lectures (free period)
    // Find the next upcoming lecture
    String? nextTime;
    for (final slotGroup in daySlots) {
      final first = slotGroup.first;
      final startParts = first.startTime.split(':');
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      if (startMin > currentMinutes) {
        nextTime = first.startTime;
        break;
      }
    }

    return CurrentLectureInfo(
      status: 'no_class',
      message: 'Free period — No lecture right now',
      nextLectureTime: nextTime,
    );
  }

  /// Get the full day's schedule for a given weekday (1=Mon … 7=Sun)
  List<List<LectureSlot>> getDaySchedule(int weekday) {
    return _timetable[weekday] ?? [];
  }

  /// Get today's full schedule
  List<List<LectureSlot>> getTodaySchedule() {
    return getDaySchedule(DateTime.now().weekday);
  }

  /// Get the day name
  static String dayName(int weekday) {
    const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday];
  }

  /// Get the lecture for a specific period on a specific day
  List<LectureSlot>? getLectureAt(int weekday, int periodNumber) {
    final daySlots = _timetable[weekday] ?? [];
    for (final slotGroup in daySlots) {
      if (slotGroup.first.periodNumber == periodNumber) {
        return slotGroup;
      }
    }
    return null;
  }

  /// Check if a specific subject has a lecture today
  bool hasSubjectToday(String subject) {
    final today = DateTime.now().weekday;
    final daySlots = _timetable[today] ?? [];
    for (final slotGroup in daySlots) {
      for (final slot in slotGroup) {
        if (slot.subject == subject) return true;
      }
    }
    return false;
  }

  /// Get all unique subjects from the timetable
  List<String> get allSubjects {
    final subjects = <String>{};
    for (final daySlots in _timetable.values) {
      for (final slotGroup in daySlots) {
        for (final slot in slotGroup) {
          if (slot.subject != 'Library' &&
              slot.subject != 'CC Activity' &&
              slot.subject != 'Mentoring') {
            subjects.add(slot.subject);
          }
        }
      }
    }
    return subjects.toList()..sort();
  }
}
