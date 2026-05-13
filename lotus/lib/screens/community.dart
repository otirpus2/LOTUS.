import 'package:flutter/material.dart';

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

  final List<ServerModel> servers = [
    ServerModel(
      name: "12A",
      channels: [
        "general",
        "homework",
        "announcements",
        "doubts",
      ],
    ),

    ServerModel(
      name: "IIT Club",
      channels: [
        "jee",
        "resources",
        "tests",
      ],
    ),
  ];

  List<Map<String, dynamic>> dms = [
    {
      "name": "Aryan Sharma",
      "message": "send notes pls",
      "time": "2m",
      "online": true,
    },
    {
      "name": "Riya Verma",
      "message": "teacher uploaded pdf",
      "time": "5m",
      "online": false,
    },
  ];

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
                "Enter your friend's name to start a conversation.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Full Name",
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF5B4CF0)),
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
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    dms.insert(0, {
                      "name": nameController.text.trim(),
                      "message": "Hey! Let's chat.",
                      "time": "now",
                      "online": true,
                    });
                  });
                  Navigator.pop(context);
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
                    child: ListView.builder(
                      itemCount:
                      servers.length,

                      itemBuilder:
                          (context, index) {
                        return ServerTile(
                          icon:
                          Icons.school,
                          active:
                          selectedServer ==
                              index +
                                  1,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ServerPage(
                                      server:
                                      servers[
                                      index],
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
                    child: ListView.builder(
                      itemCount:
                      dms.length,

                      itemBuilder:
                          (context, index) {
                        final dm =
                        dms[index];

                        return DmTile(
                          name: dm["name"],
                          message:
                          dm["message"],
                          time: dm["time"],
                          online:
                          dm["online"],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChatPage(
                                      title:
                                      dm["name"],
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