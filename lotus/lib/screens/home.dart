import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color bgColor = const Color(0xFFF5F7FF);
  final Color primaryColor = const Color(0xFF4F46E5);

  int selectedIndex = 1;
  int selectedDay = 10;

  final List<Map<String, dynamic>> events = [
    {
      "day": 1,
      "title": "Buddha Purnima",
      "color": Colors.teal,
    },
    {
      "day": 9,
      "title": "Birthday",
      "color": Colors.teal,
    },
    {
      "day": 27,
      "title": "Bakrid",
      "color": Colors.teal,
    },
  ];

  Widget navItem(
      IconData icon,
      int index,
      ) {
    final bool active = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: active
              ? primaryColor
              : Colors.transparent,

          borderRadius: BorderRadius.circular(18),
        ),

        child: Icon(
          icon,
          size: 24,
          color: active
              ? Colors.white
              : Colors.black54,
        ),
      ),
    );
  }

  Widget calendarTile(int day) {
    final bool isSelected = selectedDay == day;

    final event = events.where(
          (e) => e["day"] == day,
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDay = day;
        });
      },

      child: Container(
        padding: const EdgeInsets.all(8),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),

          border: isSelected
              ? Border.all(
            color: primaryColor,
            width: 2,
          )
              : null,

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : Colors.transparent,

                  borderRadius:
                  BorderRadius.circular(30),
                ),

                child: Text(
                  "$day",
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.black,

                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            if (event.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: event.first["color"]
                      .withValues(alpha: 0.12),

                  borderRadius:
                  BorderRadius.circular(10),
                ),

                child: Text(
                  event.first["title"],

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: event.first["color"],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun",
    ];

    return Scaffold(
      backgroundColor: bgColor,

      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        elevation: 10,

        onPressed: () {},

        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 34,
        ),
      ),

      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,

        toolbarHeight: 85,

        title: Row(
          children: [
            const Text(
              "May",
              style: TextStyle(
                color: Colors.black,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(width: 6),

            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade700,
              size: 30,
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search_rounded,
              color: Colors.black87,
              size: 32,
            ),
          ),

          const SizedBox(width: 6),

          CircleAvatar(
            radius: 22,
            backgroundColor:
            primaryColor.withValues(alpha: 0.15),

            child: const Icon(
              Icons.person,
              color: Colors.black87,
            ),
          ),

          const SizedBox(width: 18),
        ],
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(18),

        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(32),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,

          children: [
            navItem(Icons.home_rounded, 0),
            navItem(Icons.calendar_month_rounded, 1),
            navItem(Icons.person_outline_rounded, 2),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),

        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: 10,
                left: 6,
                right: 6,
              ),

              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceAround,

                children: days.map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,

                        style: TextStyle(
                          color: day == "Sun"
                              ? primaryColor
                              : Colors.black54,

                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: GridView.builder(
                physics:
                const BouncingScrollPhysics(),

                itemCount: 35,

                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.72,
                ),

                itemBuilder: (context, index) {
                  int day = index + 1;

                  if (day > 31) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                        BorderRadius.circular(18),
                      ),
                    );
                  }

                  return calendarTile(day);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}