import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  /// ======================================================
  /// DUMMY DATA
  /// ======================================================

  int totalWorkingDays = 220;
  int attendedDays = 192;
  int absentDays = 28;

  File? medicalCertificate;

  final TextEditingController leaveTitleController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  DateTime? leaveFromDate;
  DateTime? leaveToDate;

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  /// ABSENT DAYS
  final List<DateTime> absentDates = [
    DateTime(2026, 5, 4),
    DateTime(2026, 5, 9),
    DateTime(2026, 5, 16),
    DateTime(2026, 5, 22),
  ];

  /// HOLIDAYS
  final List<DateTime> holidays = [
    DateTime(2026, 5, 1),
    DateTime(2026, 5, 15),
    DateTime(2026, 5, 27),
  ];

  /// APPROVED MEDICAL LEAVE
  final List<DateTime> approvedMedicalLeave = [
    DateTime(2026, 5, 10),
    DateTime(2026, 5, 11),
    DateTime(2026, 5, 12),
  ];

  bool isAbsent(DateTime day) {
    return absentDates.any(
          (date) =>
      date.year == day.year &&
          date.month == day.month &&
          date.day == day.day,
    );
  }

  bool isHoliday(DateTime day) {
    return holidays.any(
          (date) =>
      date.year == day.year &&
          date.month == day.month &&
          date.day == day.day,
    );
  }

  bool isApprovedMedicalLeave(DateTime day) {
    return approvedMedicalLeave.any(
          (date) =>
      date.year == day.year &&
          date.month == day.month &&
          date.day == day.day,
    );
  }

  Future<void> uploadMedicalCertificate() async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
      ],
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        medicalCertificate =
            File(result.files.single.path!);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Medical Certificate Uploaded",
          ),
        ),
      );
    }
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange:
      leaveFromDate != null &&
          leaveToDate != null
          ? DateTimeRange(
        start: leaveFromDate!,
        end: leaveToDate!,
      )
          : null,
    );

    if (picked != null) {
      setState(() {
        leaveFromDate = picked.start;
        leaveToDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double attendancePercentage =
        (attendedDays / totalWorkingDays) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Attendance",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            /// ======================================================
            /// ATTENDANCE OVERVIEW
            /// ======================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Attendance Overview",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 220,
                    width: 220,

                    child: Stack(
                      alignment: Alignment.center,

                      children: [
                        SizedBox(
                          height: 220,
                          width: 220,

                          child:
                          CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 18,
                            backgroundColor:
                            Colors.transparent,
                            valueColor:
                            AlwaysStoppedAnimation(
                              Colors.grey.shade200,
                            ),
                          ),
                        ),

                        SizedBox(
                          height: 220,
                          width: 220,

                          child:
                          CircularProgressIndicator(
                            value:
                            attendancePercentage /
                                100,
                            strokeWidth: 18,
                            strokeCap:
                            StrokeCap.round,
                            backgroundColor:
                            Colors.transparent,
                            valueColor:
                            const AlwaysStoppedAnimation(
                              Colors.green,
                            ),
                          ),
                        ),

                        Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Text(
                              "${attendancePercentage.toStringAsFixed(0)}%",
                              style:
                              const TextStyle(
                                fontSize: 38,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Attendance",
                              style: TextStyle(
                                color: Colors
                                    .grey.shade600,
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                    children: [
                      _attendanceStat(
                        "Present",
                        attendedDays.toString(),
                        Colors.green,
                      ),

                      _attendanceStat(
                        "Absent",
                        absentDays.toString(),
                        Colors.redAccent,
                      ),

                      _attendanceStat(
                        "Total",
                        totalWorkingDays.toString(),
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// ======================================================
            /// FILE MEDICAL LEAVE
            /// ======================================================

            const Text(
              "File Medical Leave",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  /// TITLE
                  TextField(
                    controller:
                    leaveTitleController,
                    decoration: InputDecoration(
                      hintText: "Leave Title",
                      filled: true,
                      fillColor:
                      const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// DESCRIPTION
                  TextField(
                    controller:
                    descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                      "Describe your medical issue...",
                      filled: true,
                      fillColor:
                      const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// DATE RANGE
                  GestureDetector(
                    onTap: pickDateRange,
                    child: Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFFF5F6FA),
                        borderRadius:
                        BorderRadius.circular(18),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons.date_range_rounded,
                            color:
                            Color(0xFF5B5BD6),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Text(
                              leaveFromDate ==
                                  null
                                  ? "Select Leave Dates"
                                  : "${leaveFromDate!.day}/${leaveFromDate!.month}/${leaveFromDate!.year}  →  ${leaveToDate!.day}/${leaveToDate!.month}/${leaveToDate!.year}",
                              style:
                              const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// FILE PREVIEW
                  if (medicalCertificate != null)
                    Container(
                      padding:
                      const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green
                            .withValues(alpha: 0.1),
                        borderRadius:
                        BorderRadius.circular(
                            14),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              medicalCertificate!
                                  .path
                                  .split('/')
                                  .last,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (medicalCertificate != null)
                    const SizedBox(height: 18),

                  /// UPLOAD BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,

                    child: ElevatedButton.icon(
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(
                            0xFF5B5BD6),
                        foregroundColor:
                        Colors.white,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              18),
                        ),
                      ),

                      onPressed:
                      uploadMedicalCertificate,

                      icon: const Icon(
                        Icons.upload_file_rounded,
                      ),

                      label: const Text(
                        "Upload Medical Certificate",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,

                    child: ElevatedButton(
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.green,
                        foregroundColor:
                        Colors.white,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              18),
                        ),
                      ),

                      onPressed: () {
                        ScaffoldMessenger.of(
                            context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Medical Leave Submitted",
                            ),
                          ),
                        );
                      },

                      child: const Text(
                        "Submit Leave Request",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// ======================================================
            /// CALENDAR
            /// ======================================================

            const Text(
              "Attendance Calendar",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                children: [
                  TableCalendar(
                    focusedDay: focusedDay,
                    firstDay: DateTime(2024),
                    lastDay: DateTime(2030),

                    selectedDayPredicate: (day) {
                      return isSameDay(
                        selectedDay,
                        day,
                      );
                    },

                    onDaySelected:
                        (selected, focused) {
                      setState(() {
                        selectedDay = selected;
                        focusedDay = focused;
                      });
                    },

                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,

                      todayDecoration:
                      const BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),

                      selectedDecoration:
                      const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),

                      defaultDecoration:
                      const BoxDecoration(
                        shape: BoxShape.circle,
                      ),

                      weekendTextStyle:
                      const TextStyle(
                        color: Colors.black87,
                      ),

                      defaultTextStyle:
                      const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    calendarBuilders:
                    CalendarBuilders(
                      defaultBuilder:
                          (context,
                          day,
                          focusedDay) {
                        /// FUTURE DAYS
                        if (day.isAfter(
                            DateTime.now())) {
                          return Center(
                            child: Text(
                              '${day.day}',
                              style:
                              const TextStyle(
                                color:
                                Colors.black87,
                                fontWeight:
                                FontWeight
                                    .w500,
                              ),
                            ),
                          );
                        }

                        /// MEDICAL LEAVE
                        if (isApprovedMedicalLeave(
                            day)) {
                          return _calendarDay(
                            day.day.toString(),
                            Colors.blue,
                          );
                        }

                        /// ABSENT
                        if (isAbsent(day)) {
                          return _calendarDay(
                            day.day.toString(),
                            Colors.redAccent,
                          );
                        }

                        /// HOLIDAY
                        if (isHoliday(day)) {
                          return _calendarDay(
                            day.day.toString(),
                            Colors.orange,
                          );
                        }

                        /// PRESENT
                        return _calendarDay(
                          day.day.toString(),
                          Colors.green,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  Wrap(
                    spacing: 18,
                    runSpacing: 14,
                    children: [
                      _legendItem(
                        Colors.green,
                        "Present",
                      ),

                      _legendItem(
                        Colors.redAccent,
                        "Absent",
                      ),

                      _legendItem(
                        Colors.orange,
                        "Holiday",
                      ),

                      _legendItem(
                        Colors.blue,
                        "Medical Leave",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _attendanceStat(
      String title,
      String value,
      Color color,
      ) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _calendarDay(
      String text,
      Color color,
      ) {
    return Center(
      child: Container(
        width: 34,
        height: 34,

        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),

        alignment: Alignment.center,

        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(
      Color color,
      String title,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
