import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4F46E5);
    const Color backgroundColor = Color(0xFFF7F5FA);

    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Homework Reminder',
        'subtitle': 'Math assignment due tomorrow',
        'icon': Icons.menu_book_rounded,
      },
      {
        'title': 'Attendance Updated',
        'subtitle': 'Your attendance is now 92%',
        'icon': Icons.calendar_month_rounded,
      },
      {
        'title': 'New Community Post',
        'subtitle': 'Someone posted in Class 12 group',
        'icon': Icons.people_alt_rounded,
      },
      {
        'title': 'Certificate Generated',
        'subtitle': 'Science Olympiad certificate available',
        'icon': Icons.workspace_premium_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,

        centerTitle: true,

        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Row(
              children: [
                Container(
                  height: 58,
                  width: 58,

                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Icon(
                    item['icon'],
                    color: primaryColor,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        item['subtitle'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}