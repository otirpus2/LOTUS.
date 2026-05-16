import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_page.dart';
import 'models/server_model.dart';
import 'server_page.dart';
import 'widgets/dm_tile.dart';
import 'widgets/server_tile.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchServers();
    _fetchFriends();
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
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final response = await Supabase.instance.client
          .from('friendships')
          .select('*, sender:profiles!friendships_sender_id_fkey(id, first_name, last_name, student_id), receiver:profiles!friendships_receiver_id_fkey(id, first_name, last_name, student_id)')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .eq('status', 'accepted');
      
      if (mounted) {
        setState(() {
          dms = (response as List).map((row) {
            final isSender = row['sender_id'] == currentUserId;
            final friendProfile = isSender ? row['receiver'] : row['sender'];
            final firstName = friendProfile['first_name'] ?? 'Unknown';
            final lastName = friendProfile['last_name'] ?? '';
            return {
              "id": friendProfile['id'],
              "name": "$firstName $lastName".trim(),
              "student_id": friendProfile['student_id'] ?? '',
              "message": "Tap to chat",
              "time": "now",
              "online": true,
            };
          }).toList();
          isLoadingFriends = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingFriends = false);
    }
  }

  void _showAddFriendDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text(
            "Add New Friend",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter your friend's unique Student ID.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Student ID",
                  prefixIcon: const Icon(Icons.badge, color: Color(0xFF5B4CF0)),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFF5B4CF0), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Groups coming soon!"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text("New Group"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final studentId = nameController.text.trim();
                if (studentId.isNotEmpty) {
                  Navigator.pop(context);
                  final currentUserId = Supabase.instance.client.auth.currentUser!.id;
                  try {
                    final profileResponse = await Supabase.instance.client
                        .from('profiles')
                        .select('id')
                        .eq('student_id', studentId)
                        .maybeSingle();

                    if (profileResponse == null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Student ID not found")));
                      return;
                    }

                    await Supabase.instance.client.from('friendships').insert({
                      'sender_id': currentUserId,
                      'receiver_id': profileResponse['id'],
                      'status': 'accepted',
                    });
                    
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend added!")));
                    _fetchFriends();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error adding friend")));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4CF0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text("Add Friend", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
                          onTap: _showAddFriendDialog,
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_add,
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
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatPage(
                                            title: dm["name"],
                                            receiverId: dm["id"],
                                          ),
                                        ),
                                      );
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