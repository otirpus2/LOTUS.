import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lotus/screens/certificate.dart';
import 'package:intl/intl.dart';

import 'attendance.dart';
import 'calendar.dart';
import 'notification.dart';
import 'profile.dart';
import 'community.dart';
import 'homework.dart';
import 'reports.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class Task {
  String id;
  String title;
  String dueDate;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.completed,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      dueDate: map['due_date'],
      completed: map['completed'],
    );
  }
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color accentColor = const Color(0xFFEEF2FF);

  String _greetingText = 'Hi, ...';

  int selectedIndex = 0;

  final PageController alertController =
  PageController(viewportFraction: 0.92);

  List<Map<String, dynamic>> alerts = [];

  bool loadingAlerts = true;

  int currentAlert = 0;

  RealtimeChannel? alertChannel;

  List<Task> tasks = [];

  RealtimeChannel? todoChannel;

  int unreadMessages = 0;
  int pendingFriendRequests = 0;
  int unreadSystemNotifications = 0;
  RealtimeChannel? notificationBadgeChannel;

  Future<void> _loadGreeting() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) return;

      final res = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();

      final username = (res?['username'] as String?)?.trim();

      if (username != null && username.isNotEmpty && mounted) {
        setState(() {
          _greetingText = 'Hi, $username';
        });
      }
    } catch (e) {
      debugPrint('Failed to load greeting: $e');
    }
  }

  Future<void> loadAlerts() async {
    try {
      final response = await Supabase.instance.client
          .from('alerts')
          .select()
          .order('created_at', ascending: false);

      final now = DateTime.now();

      final validAlerts = response.where((alert) {
        final createdAt = DateTime.parse(alert['created_at']);

        final int durationValue = alert['duration_value'];

        final String durationUnit = alert['duration_unit'];

        Duration duration;

        switch (durationUnit) {
          case 'day':
            duration = Duration(days: durationValue);
            break;

          case 'week':
            duration = Duration(days: durationValue * 7);
            break;

          case 'month':
            duration = Duration(days: durationValue * 30);
            break;

          default:
            duration = const Duration(days: 1);
        }

        final expiry = createdAt.add(duration);

        return expiry.isAfter(now);
      }).toList();

      if (mounted) {
        setState(() {
          alerts = List<Map<String, dynamic>>.from(validAlerts);
          loadingAlerts = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load alerts: $e');

      if (mounted) {
        setState(() {
          loadingAlerts = false;
        });
      }
    }
  }

  Future<void> loadTodos() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) return;

      final response = await Supabase.instance.client
          .from('todos')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          tasks = response
              .map<Task>(
                (task) => Task.fromMap(task),
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to load todos: $e');
    }
  }

  Future<void> _fetchUnreadCounts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Unread Direct Messages
      final msgRes = await Supabase.instance.client
          .from('direct_messages')
          .select('id')
          .eq('receiver_id', user.id)
          .eq('is_read', false);
      
      // 2. Pending Friend Requests (Incoming)
      final friendRes = await Supabase.instance.client
          .from('friendships')
          .select('id')
          .eq('receiver_id', user.id)
          .eq('status', 'pending');

      // 3. Unread System Notifications (Warnings, Results, etc.)
      final sysRes = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          unreadMessages = msgRes.length;
          pendingFriendRequests = friendRes.length;
          unreadSystemNotifications = sysRes.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching counts: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    _loadGreeting();

    loadAlerts();

    loadTodos();

    alertChannel = Supabase.instance.client
        .channel('alerts-channel')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'alerts',
      callback: (payload) async {
        await loadAlerts();
      },
    )
        .subscribe();

    todoChannel = Supabase.instance.client
        .channel('todos-channel')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'todos',
      callback: (payload) async {
        await loadTodos();
      },
    )
        .subscribe();

    _fetchUnreadCounts();

    notificationBadgeChannel = Supabase.instance.client
        .channel('badges-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'direct_messages',
          callback: (payload) => _fetchUnreadCounts(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          callback: (payload) => _fetchUnreadCounts(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) => _fetchUnreadCounts(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    alertChannel?.unsubscribe();
    todoChannel?.unsubscribe();
    notificationBadgeChannel?.unsubscribe();
    alertController.dispose();
    super.dispose();
  }

  void showAddTaskDialog() {
    final titleController = TextEditingController();
    final dueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Add Task',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Task Title',
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: accentColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dueController,
                    readOnly: true,
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: primaryColor,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          dueController.text =
                              DateFormat('dd MMM').format(picked);
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Select Due Date',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: Icon(Icons.calendar_today,
                          size: 16, color: primaryColor),
                      filled: true,
                      fillColor: accentColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final user = Supabase.instance.client.auth.currentUser;

                    if (user == null) return;

                    if (titleController.text.isEmpty ||
                        dueController.text.isEmpty) {
                      return;
                    }

                    await Supabase.instance.client.from('todos').insert({
                      'user_id': user.id,
                      'title': titleController.text,
                      'due_date': dueController.text,
                      'completed': false,
                    });

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget dashboardButton(
      IconData icon,
      String title, {
        VoidCallback? onTap,
        int? badgeCount,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

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
          color: active ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          size: 24,
          color: active ? Colors.white : Colors.black54,
        ),
      ),
    );
  }

  Widget homeScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greetingText,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),

            if (!loadingAlerts && alerts.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: PageView.builder(
                  controller: alertController,
                  itemCount: alerts.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentAlert = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final alert = alerts[index];

                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5B4CF0),
                            Color(0xFF4338F2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                            primaryColor.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Text(
                              alert['title'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alert['subtitle'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  alerts.length,
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin:
                    const EdgeInsets.symmetric(horizontal: 3),
                    height: 7,
                    width: currentAlert == index ? 18 : 7,
                    decoration: BoxDecoration(
                      color: currentAlert == index
                          ? primaryColor
                          : Colors.grey.shade300,
                      borderRadius:
                      BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  dashboardButton(
                    Icons.calendar_month_rounded,
                    'Attendance',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const AttendancePage(),
                        ),
                      );
                    },
                  ),
                  dashboardButton(
                    Icons.menu_book_rounded,
                    'H.W',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const HomeworkPage(),
                        ),
                      );
                    },
                  ),
                  dashboardButton(
                    Icons.people_rounded,
                    'Community',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommunityPage(),
                        ),
                      );
                    },
                    badgeCount: unreadMessages > 0 ? unreadMessages : null,
                  ),
                  dashboardButton(
                    Icons.workspace_premium_rounded,
                    'Achievements',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CertificatePage(),
                        ),
                      );
                    },
                  ),
                  dashboardButton(
                    Icons.bar_chart_rounded,
                    'Reports',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportsSection(),
                        ),
                      );
                    },
                    badgeCount: unreadSystemNotifications > 0 ? unreadSystemNotifications : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'To-Do List',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length} Tasks',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: tasks.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final task = tasks[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.85,
                        child: Checkbox(
                          activeColor: primaryColor,
                          value: task.completed,
                          onChanged: (value) async {
                            await Supabase.instance.client
                                .from('todos')
                                .update({
                                  'completed': value,
                                })
                                .eq('id', task.id);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${task.dueDate}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Supabase.instance.client
                              .from('todos')
                              .delete()
                              .eq('id', task.id);
                        },
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton.extended(
        backgroundColor: primaryColor,
        elevation: 6,
        onPressed: showAddTaskDialog,
        icon: const Icon(
          Icons.add,
          color: Colors.white,
          size: 18,
        ),
        label: const Text(
          'Add Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      )
          : null,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FF),
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            const Text(
              'LOTUS DEV.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
              if (pendingFriendRequests + unreadSystemNotifications > 0)
                Positioned(
                  right: 18,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 10,
                      minHeight: 10,
                    ),
                  ),
                ),
            ],
          ),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            navItem(Icons.home_rounded, 0),
            navItem(Icons.calendar_month_rounded, 1),
            navItem(Icons.person_outline_rounded, 2),
          ],
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          homeScreen(),
          const CalendarPage(),
          const ProfilePage(),
        ],
      ),
    );
  }
}