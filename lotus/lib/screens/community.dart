import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'chat_page.dart';
import 'models/server_model.dart';
import 'server_page.dart';
import 'widgets/dm_tile.dart';
import 'widgets/server_tile.dart';
import 'friends_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() =>
      _CommunityPageState();
}

class _CommunityPageState
    extends State<CommunityPage> {
  int selectedServer = 0;
  bool isLoadingServers = true;
  bool isLoadingFriends = true;
  List<ServerModel> servers = [];
  List<Map<String, dynamic>> dms = [];
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchServers();
    _fetchFriends();
    _setupRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    _realtimeChannel = Supabase.instance.client
        .channel('public:direct_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'direct_messages',
          callback: (payload) {
            _fetchFriends();
          },
        )
        .subscribe();
  }

  Future<void> _fetchServers() async {
    try {
      final response = await Supabase.instance.client
          .from('servers')
          .select()
          .order('created_at');
      
      if (mounted) {
        setState(() {
          servers = (response as List).map((e) => ServerModel.fromJson(e)).toList();
          isLoadingServers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingServers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading servers: $e')),
        );
      }
    }
  }

  Future<void> _fetchFriends() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final currentUserId = user.id;
    
    try {
      final response = await Supabase.instance.client
          .from('friendships')
          .select('*, sender:profiles!friendships_sender_id_fkey(id, full_name, username, student_id), receiver:profiles!friendships_receiver_id_fkey(id, full_name, username, student_id)')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .eq('status', 'accepted');
      
      final List<Map<String, dynamic>> friendList = [];
      
      for (var row in (response as List)) {
        final isSender = row['sender_id'] == currentUserId;
        final friendProfile = isSender ? row['receiver'] : row['sender'];
        
        if (friendProfile == null) continue;

        // Fetch unread messages count for this specific friend
        final unreadRes = await Supabase.instance.client
            .from('direct_messages')
            .select('id')
            .eq('sender_id', friendProfile['id'])
            .eq('receiver_id', currentUserId)
            .eq('is_read', false);

        // Fetch last message for snippet
        final lastMsgRes = await Supabase.instance.client
            .from('direct_messages')
            .select('content, created_at')
            .or('and(sender_id.eq.$currentUserId,receiver_id.eq.${friendProfile['id']}),and(sender_id.eq.${friendProfile['id']},receiver_id.eq.$currentUserId)')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        final fullName = friendProfile['username'] ?? friendProfile['full_name'] ?? 'Unknown';
        final lastMsg = lastMsgRes?['content'] ?? "Tap to chat";
        final lastTime = lastMsgRes != null 
            ? DateFormat('hh:mm a').format(DateTime.parse(lastMsgRes['created_at']))
            : "now";

        friendList.add({
          "id": friendProfile['id'],
          "name": fullName,
          "student_id": friendProfile['student_id'] ?? '',
          "message": lastMsg,
          "time": lastTime,
          "online": true, // In a real app, you'd check presence
          "unreadCount": unreadRes.length,
        });
      }

      // Sort by unread first, then last active
      friendList.sort((a, b) => (b['unreadCount'] as int).compareTo(a['unreadCount'] as int));

      if (mounted) {
        setState(() {
          dms = friendList;
          isLoadingFriends = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching friends: $e');
      if (mounted) setState(() => isLoadingFriends = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FF),

      body: SafeArea(
        child: Row(
          children: [
            // ================= SERVER BAR =================

            Container(
              width: 72,
              color: Colors.white,

              child: Column(
                children: [
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedServer = 0;
                      });
                    },

                    child: Container(
                      margin:
                      const EdgeInsets.only(
                        bottom: 14,
                      ),
                      height: 52,
                      width: 52,
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                            0xFF5B4CF0),
                        borderRadius:
                        BorderRadius
                            .circular(
                            18),
                      ),
                      child: const Icon(
                        Icons.message,
                        color:
                        Colors.white,
                      ),
                    ),
                  ),

                  Expanded(
                    child: isLoadingServers
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B4CF0)))
                        : ListView.builder(
                            itemCount: servers.length,
                            itemBuilder: (context, index) {
                              return ServerTile(
                                icon: Icons.school,
                                active: selectedServer == index + 1,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ServerPage(
                                        server: servers[index],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),

                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Under Development"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFF5B4CF0),
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= DMS =================

            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.all(
                        18),

                    child: Row(
                      children: [
                        const Text(
                          "Messages",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),

                        const Spacer(),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FriendsPage(),
                              ),
                            );
                          },
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.people_alt_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),

                    child: TextField(
                      decoration:
                      InputDecoration(
                        hintText:
                        "Search",
                        prefixIcon:
                        const Icon(
                          Icons.search,
                        ),
                        filled: true,
                        fillColor:
                        Colors.white,
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                              18),
                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: isLoadingFriends
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B4CF0)))
                        : dms.isEmpty
                            ? const Center(child: Text("No friends yet. Add one using their Student ID!", style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: dms.length,
                                itemBuilder: (context, index) {
                                  final dm = dms[index];
                                  return DmTile(
                                    name: dm["name"],
                                    message: dm["message"],
                                    time: dm["time"],
                                    online: dm["online"],
                                    badgeCount: dm["unreadCount"] ?? 0,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatPage(
                                            title: dm["name"],
                                            receiverId: dm["id"],
                                          ),
                                        ),
                                      );
                                      _fetchFriends(); // Refresh when returning from chat
                                    },
                                  );
                                },
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
}