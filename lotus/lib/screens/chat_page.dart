import 'package:flutter/material.dart';

import 'models/message_model.dart';
import 'widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String title;

  const ChatPage({
    super.key,
    required this.title,
  });

  @override
  State<ChatPage> createState() =>
      _ChatPageState();
}

class _ChatPageState
    extends State<ChatPage> {
  final TextEditingController controller =
  TextEditingController();

  List<MessageModel> messages = [
    MessageModel(
      sender: "Aryan",
      message:
      "Bro send physics notes",
      isMe: false,
    ),
    MessageModel(
      sender: "You",
      message: "wait sending",
      isMe: true,
    ),
  ];

  void sendMessage() {
    if (controller.text.trim().isEmpty) {
      return;
    }

    setState(() {
      messages.add(
        MessageModel(
          sender: "You",
          message: controller.text,
          isMe: true,
        ),
      );
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FF),

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
              padding:
              const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder:
                  (context, index) {
                final msg =
                messages[index];

                return MessageBubble(
                  sender: msg.sender,
                  message: msg.message,
                  isMe: msg.isMe,
                );
              },
            ),
          ),

          Container(
            padding:
            const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration:
                    InputDecoration(
                      hintText: "Message",
                      filled: true,
                      fillColor:
                      const Color(
                          0xFFEEF2FF),
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(16),
                        borderSide:
                        BorderSide.none,
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
                      color:
                      const Color(
                          0xFF5B4CF0),
                      borderRadius:
                      BorderRadius
                          .circular(16),
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