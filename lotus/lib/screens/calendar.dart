import 'dart:async';

import 'package:flutter/material.dart';

import 'data/calendar_repository.dart';
import 'models/calendar_event.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarRepository _repository = CalendarRepository();

  final Color primaryColor = const Color(0xFF4285F4);
  final Color greyColor = const Color(0xFF70757A);
  final Color gridLineColor = const Color(0xFFE8EAED);

  final List<String> months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> weekDays = const [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  int selectedMonthIndex = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  CalendarAudienceScope? currentAudience;
  List<CalendarEvent> events = const <CalendarEvent>[];
  bool isLoadingAudience = true;
  bool isLoadingEvents = true;
  String? error;

  StreamSubscription<CalendarAudienceScope>? _audienceSubscription;
  StreamSubscription<List<CalendarEvent>>? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    _watchAudience();
  }

  @override
  void dispose() {
    _audienceSubscription?.cancel();
    _eventsSubscription?.cancel();
    super.dispose();
  }

  void _watchAudience() {
    _audienceSubscription?.cancel();
    _audienceSubscription = _repository.watchCurrentAudienceScope().listen(
      (audience) {
        if (!mounted) return;

        setState(() {
          currentAudience = audience;
          isLoadingAudience = false;
          isLoadingEvents = true;
          error = null;
        });

        _watchEvents(audience);
      },
      onError: (Object e) {
        if (!mounted) return;

        setState(() {
          error = e.toString();
          isLoadingAudience = false;
          isLoadingEvents = false;
        });
      },
    );
  }

  void _watchEvents(CalendarAudienceScope audience) {
    _eventsSubscription?.cancel();
    _eventsSubscription = _repository
        .watchVisibleEvents(audience: audience)
        .listen(
          (list) {
            if (!mounted) return;

            setState(() {
              events = list;
              isLoadingEvents = false;
              error = null;
            });
          },
          onError: (Object e) {
            if (!mounted) return;

            setState(() {
              error = e.toString();
              isLoadingEvents = false;
            });
          },
        );
  }

  List<DateTime> getDaysInMonth() {
    final firstDay = DateTime(selectedYear, selectedMonthIndex, 1);
    final firstWeekday = firstDay.weekday;
    final startDate = firstDay.subtract(Duration(days: firstWeekday - 1));

    return List.generate(42, (index) => startDate.add(Duration(days: index)));
  }

  String formatDate(DateTime date) => formatCalendarDate(date);

  Map<String, List<CalendarEvent>> eventsByDate() {
    final grouped = <String, List<CalendarEvent>>{};

    for (final event in events) {
      grouped.putIfAbsent(event.dateKey, () => <CalendarEvent>[]).add(event);
    }

    return grouped;
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

  Color colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return primaryColor;
    return Color(parsed);
  }

  Future<void> _showDayEvents(
    DateTime day,
    List<CalendarEvent> dayEvents,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weekDays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}',
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
                        'No events scheduled for this day',
                        style: TextStyle(color: Color(0xFF70757A)),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: dayEvents.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _eventSheetTile(dayEvents[index]);
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _eventSheetTile(CalendarEvent event) {
    final eventColor = colorFromHex(event.colorHex);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: eventColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: eventColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: eventColor.withValues(alpha: 0.9),
                  ),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5F6368),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  event.audienceLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5F6368),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceStrip() {
    final audience = currentAudience;

    if (isLoadingAudience) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (audience == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF8FAFF),
      child: Row(
        children: [
          Icon(Icons.school_outlined, color: primaryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              audience.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF3C4043),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStrip() {
    final message = error;
    if (message == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8D3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB3261E),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = getDaysInMonth();
    final now = DateTime.now();
    final groupedEvents = eventsByDate();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: PopupMenuButton<int>(
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (int month) {
            setState(() {
              selectedMonthIndex = month;
            });
          },
          itemBuilder: (context) => months.asMap().entries.map((entry) {
            return PopupMenuItem<int>(
              value: entry.key + 1,
              child: Text(entry.value, style: const TextStyle(fontSize: 16)),
            );
          }).toList(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  '${months[selectedMonthIndex - 1]} $selectedYear',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3C4043),
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5F6368)),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left, color: Color(0xFF5F6368)),
            onPressed: previousMonth,
          ),
          IconButton(
            tooltip: 'Next month',
            icon: const Icon(Icons.chevron_right, color: Color(0xFF5F6368)),
            onPressed: nextMonth,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildAudienceStrip(),
          _buildErrorStrip(),
          if (isLoadingEvents) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: weekDays
                  .map(
                    (day) => Expanded(
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
                    ),
                  )
                  .toList(),
            ),
          ),
          Divider(height: 1, color: gridLineColor),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.62,
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                final isCurrentMonth = day.month == selectedMonthIndex;
                final isToday =
                    day.day == now.day &&
                    day.month == now.month &&
                    day.year == now.year;
                final dayEvents =
                    groupedEvents[formatDate(day)] ?? const <CalendarEvent>[];

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
                              color: isToday
                                  ? primaryColor
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: isToday
                                    ? Colors.white
                                    : isCurrentMonth
                                    ? const Color(0xFF3C4043)
                                    : const Color(
                                        0xFF70757A,
                                      ).withValues(alpha: 0.4),
                                fontSize: 13,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Column(
                            children: [
                              ...dayEvents.take(2).map((event) {
                                final eventColor = colorFromHex(event.colorHex);
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(
                                    bottom: 2,
                                    left: 2,
                                    right: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: eventColor.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    maxLines: 1,
                                  ),
                                );
                              }),
                              if (dayEvents.length > 2)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    top: 1,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '+${dayEvents.length - 2} more',
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
