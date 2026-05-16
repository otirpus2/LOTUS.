import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/message_model.dart';
import 'widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String title;
  final String? channelId;
  final String? receiverId;

  const ChatPage({
    super.key,
    required this.title,
    this.channelId,
    this.receiverId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller = TextEditingController();
  List<MessageModel> messages = [];
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  final String currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _setupMessageStream();
  }

  void _setupMessageStream() {
    if (widget.channelId != null) {
      _messagesSubscription = Supabase.instance.client
          .from('channel_messages')
          .stream(primaryKey: ['id'])
          .eq('channel_id', widget.channelId!)
          .order('created_at', ascending: false)
          .listen((data) {
        _fetchProfilesAndMap(data);
      });
    } else if (widget.receiverId != null) {
      _messagesSubscription = Supabase.instance.client
          .from('direct_messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((data) {
        final filteredData = data.where((msg) {
          final sId = msg['sender_id'];
          final rId = msg['receiver_id'];
          return (sId == currentUserId && rId == widget.receiverId) ||
                 (sId == widget.receiverId && rId == currentUserId);
        }).toList();
        _fetchProfilesAndMap(filteredData);
      });
    }
  }

  Future<void> _fetchProfilesAndMap(List<Map<String, dynamic>> rawData) async {
    // Collect all unique user IDs
    final userIds = rawData.map((e) => (e['user_id'] ?? e['sender_id']) as String).toSet().toList();
    
    if (userIds.isEmpty) {
      if (mounted) setState(() => messages = []);
      return;
    }

    // Fetch profiles for these users
    final profilesResponse = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, username')
        .inFilter('id', userIds);
        
    final profilesMap = {for (var item in profilesResponse) item['id']: item};

    if (mounted) {
      setState(() {
        messages = rawData.map((e) {
          final senderId = e['user_id'] ?? e['sender_id'];
          e['profiles'] = profilesMap[senderId];
          return MessageModel.fromJson(e, currentUserId);
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final content = controller.text.trim();
    controller.clear();

    try {
      if (widget.channelId != null) {
        await Supabase.instance.client.from('channel_messages').insert({
          'channel_id': widget.channelId,
          'user_id': currentUserId,
          'content': content,
        });
      } else if (widget.receiverId != null) {
        await Supabase.instance.client.from('direct_messages').insert({
          'sender_id': currentUserId,
          'receiver_id': widget.receiverId,
          'content': content,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Latest messages at the bottom
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return MessageBubble(
                  sender: msg.senderName,
                  message: msg.message,
                  isMe: msg.isMe,
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Message",
                      filled: true,
                      fillColor: const Color(0xFFEEF2FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B4CF0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}