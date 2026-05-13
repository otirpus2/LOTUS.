import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final Color primaryColor = const Color(0xFF4285F4); // Google Blue
  final Color greyColor = const Color(0xFF70757A);
  final Color gridLineColor = const Color(0xFFE8EAED);

  final List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ];

  final List<String> weekDays = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

  int selectedMonthIndex = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Mock events with colors
  Map<String, List<Map<String, dynamic>>> events = {
    "2026-05-09": [
      {"title": "Physics Assignment", "color": Color(0xFF4285F4)},
      {"title": "Math Homework", "color": Color(0xFF34A853)},
      {"title": "Chemistry Viva", "color": Color(0xFFFBBC05)},
    ],
    "2026-05-15": [
      {"title": "PTM Meeting", "color": Color(0xFFEA4335)},
    ],
    "2026-05-27": [
      {"title": "Bakrid Holiday", "color": Color(0xFFA142F4)},
    ],
  };

  List<DateTime> getDaysInMonth() {
    final firstDay = DateTime(selectedYear, selectedMonthIndex, 1);
    final firstWeekday = firstDay.weekday;
    // Adjusting to start from Monday
    final startDate = firstDay.subtract(Duration(days: firstWeekday - 1));

    return List.generate(42, (index) => startDate.add(Duration(days: index)));
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void nextMonth() {
    setState(() {
      if (selectedMonthIndex == 12) {
        selectedMonthIndex = 1;
        selectedYear++;
      } else {
        selectedMonthIndex++;
      }
    });
  }

  void previousMonth() {
    setState(() {
      if (selectedMonthIndex == 1) {
        selectedMonthIndex = 12;
        selectedYear--;
      } else {
        selectedMonthIndex--;
      }
    });
  }

  void _showDayEvents(DateTime day, List<Map<String, dynamic>> dayEvents) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${weekDays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3C4043),
                ),
              ),
              const SizedBox(height: 20),
              if (dayEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "No events scheduled for this day",
                      style: TextStyle(color: Color(0xFF70757A)),
                    ),
                  ),
                )
              else
                ...dayEvents.map((event) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (event['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (event['color'] as Color).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: event['color'] as Color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              event['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: (event['color'] as Color).withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = getDaysInMonth();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: PopupMenuButton<int>(
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (int month) {
            setState(() {
              selectedMonthIndex = month;
            });
          },
          itemBuilder: (context) => months.asMap().entries.map((entry) {
            return PopupMenuItem<int>(
              value: entry.key + 1,
              child: Text(
                entry.value,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${months[selectedMonthIndex - 1]} $selectedYear",
                style: const TextStyle(
                  color: Color(0xFF3C4043),
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5F6368)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF5F6368)),
            onPressed: previousMonth,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF5F6368)),
            onPressed: nextMonth,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Weekday labels
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: weekDays.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: greyColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          Divider(height: 1, color: gridLineColor),
          // Calendar Grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.62, // Taller cells to avoid overflow
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                final bool isCurrentMonth = day.month == selectedMonthIndex;
                final bool isToday = day.day == now.day && day.month == now.month && day.year == now.year;
                final dayEvents = events[formatDate(day)] ?? [];

                return GestureDetector(
                  onTap: () => _showDayEvents(day, dayEvents),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: gridLineColor, width: 0.5),
                        bottom: BorderSide(color: gridLineColor, width: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 6),
                        Center(
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isToday ? primaryColor : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "${day.day}",
                              style: TextStyle(
                                color: isToday
                                    ? Colors.white
                                    : isCurrentMonth
                                        ? const Color(0xFF3C4043)
                                        : const Color(0xFF70757A).withValues(alpha: 0.4),
                                fontSize: 13,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Column(
                            children: [
                              ...dayEvents.take(2).map((event) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 2, left: 2, right: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (event['color'] as Color).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  event['title'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 1,
                                ),
                              )),
                              if (dayEvents.length > 2)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, top: 1),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "+${dayEvents.length - 2} more",
                                      style: TextStyle(
                                        color: greyColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
