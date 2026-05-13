import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String sender;
  final String message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.sender,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor =
    Color(0xFF5B4CF0);

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        constraints:
        const BoxConstraints(
          maxWidth: 260,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? primaryColor
              : Colors.white,
          borderRadius:
          BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 4,
                ),
                child: Text(
                  sender,
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

            Text(
              message,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}