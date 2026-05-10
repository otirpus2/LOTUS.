import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color backgroundColor = const Color(0xFFF5F7FF);

  int selectedDay = 12;

  final List<Map<String, dynamic>> events = [
    {
      'day': 12,
      'title': 'Science Exhibition',
      'time': '10:00 AM',
      'type': 'Event',
    },
    {
      'day': 12,
      'title': 'Math Homework Submission',
      'time': '11:59 PM',
      'type': 'Homework',
    },
    {
      'day': 15,
      'title': 'Independence Day',
      'time': 'Holiday',
      'type': 'Holiday',
    },
  ];

  void showAddEventDialog() {
    final titleController = TextEditingController();
    final timeController = TextEditingController();

    String selectedType = 'Event';
    int selectedEventDay = selectedDay;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: const Text(
                'Add Event',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Event Title',
                        filled: true,
                        fillColor:
                        primaryColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        hintText: 'Time',
                        filled: true,
                        fillColor:
                        primaryColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                        primaryColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        'Event',
                        'Holiday',
                        'Homework',
                      ]
                          .map(
                            (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedType = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      value: selectedEventDay,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                        primaryColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: List.generate(
                        31,
                            (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('May ${index + 1}'),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedEventDay = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      events.add({
                        'day': selectedEventDay,
                        'title': titleController.text,
                        'time': timeController.text,
                        'type': selectedType,
                      });
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget calendarDay(int day) {
    final bool isSelected = selectedDay == day;

    final bool hasEvent = events.any(
          (event) => event['day'] == day,
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDay = day;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color:
          isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (hasEvent)
              Positioned(
                bottom: 8,
                child: Container(
                  height: 6,
                  width: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color getTypeColor(String type) {
    switch (type) {
      case 'Holiday':
        return Colors.redAccent;

      case 'Homework':
        return Colors.orange;

      default:
        return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = events
        .where((event) => event['day'] == selectedDay)
        .toList();

    return Scaffold(
      backgroundColor: backgroundColor,

      floatingActionButton:
      FloatingActionButton.extended(
        backgroundColor: primaryColor,
        elevation: 10,
        onPressed: showAddEventDialog,

        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),

        label: const Text(
          'Add Event',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,

        centerTitle: true,

        title: const Text(
          'Calendar',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(18),
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),

              boxShadow: [
                BoxShadow(
                  color:
                  Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

                  children: [
                    const Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        Text(
                          'May 2026',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'School Schedule',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),

                    Container(
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: primaryColor.withValues(
                          alpha: 0.08,
                        ),

                        borderRadius:
                        BorderRadius.circular(18),
                      ),

                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,

                  children: const [
                    Text('S'),
                    Text('M'),
                    Text('T'),
                    Text('W'),
                    Text('T'),
                    Text('F'),
                    Text('S'),
                  ],
                ),

                const SizedBox(height: 18),

                GridView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),

                  itemCount: 31,

                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),

                  itemBuilder: (context, index) {
                    return calendarDay(index + 1);
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        'Agenda • May $selectedDay',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        '${selectedEvents.length} Events',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: selectedEvents.isEmpty
                        ? Center(
                      child: Text(
                        'No events scheduled',
                        style: TextStyle(
                          color:
                          Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                    )
                        : ListView.builder(
                      itemCount:
                      selectedEvents.length,

                      itemBuilder:
                          (context, index) {
                        final event =
                        selectedEvents[index];

                        return Container(
                          margin:
                          const EdgeInsets.only(
                            bottom: 18,
                          ),

                          padding:
                          const EdgeInsets.all(
                            18,
                          ),

                          decoration:
                          BoxDecoration(
                            color: Colors.white,

                            borderRadius:
                            BorderRadius
                                .circular(
                              26,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(
                                  alpha:
                                  0.04,
                                ),
                                blurRadius:
                                14,
                                offset:
                                const Offset(
                                  0,
                                  8,
                                ),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              Container(
                                height: 56,
                                width: 56,

                                decoration:
                                BoxDecoration(
                                  color: getTypeColor(
                                    event[
                                    'type'],
                                  ).withValues(
                                    alpha:
                                    0.12,
                                  ),

                                  borderRadius:
                                  BorderRadius.circular(
                                    18,
                                  ),
                                ),

                                child: Icon(
                                  event['type'] ==
                                      'Holiday'
                                      ? Icons
                                      .beach_access_rounded
                                      : event['type'] ==
                                      'Homework'
                                      ? Icons
                                      .menu_book_rounded
                                      : Icons
                                      .event_rounded,

                                  color:
                                  getTypeColor(
                                    event[
                                    'type'],
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 16,
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                                  children: [
                                    Text(
                                      event[
                                      'title'],
                                      style:
                                      const TextStyle(
                                        fontSize:
                                        17,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 6,
                                    ),

                                    Text(
                                      event['time'],
                                      style:
                                      TextStyle(
                                        color: Colors
                                            .grey
                                            .shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}