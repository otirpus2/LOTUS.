import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'models/server_model.dart';

class ServerPage extends StatelessWidget {
  final ServerModel server;

  const ServerPage({
    super.key,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          server.name,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: server.channels.length,
        itemBuilder: (context, index) {
          final channel =
          server.channels[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    title: "# $channel",
                  ),
                ),
              );
            },

            child: Container(
              margin:
              const EdgeInsets.only(
                bottom: 12,
              ),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(
                    18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag),

                  const SizedBox(width: 10),

                  Text(
                    channel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}