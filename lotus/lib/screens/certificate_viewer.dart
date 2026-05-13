import 'dart:io';

import 'package:flutter/material.dart';

import 'certificate_model.dart';

class CertificateViewerPage extends StatelessWidget {
  final Achievement achievement;

  const CertificateViewerPage({
    super.key,
    required this.achievement,
  });

  Widget infoTile(
      String title,
      String value,
      IconData icon,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(22),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF4F46E5),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,

                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        iconTheme:
        const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 260,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color:
                const Color(0xFF4F46E5).withValues(alpha: 0.1),
              ),

              child: achievement.filePath.isEmpty
                  ? const Icon(
                Icons.workspace_premium_rounded,
                size: 100,
                color: Color(0xFF4F46E5),
              )
                  : ClipRRect(
                borderRadius:
                BorderRadius.circular(30),

                child: Image.file(
                  File(achievement.filePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.redAccent,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              achievement.title,

              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 22),

            infoTile(
              "Issuer",
              achievement.issuer,
              Icons.business_rounded,
            ),

            infoTile(
              "Date",
              achievement.date,
              Icons.calendar_month_rounded,
            ),

            infoTile(
              "Category",
              achievement.category,
              Icons.category_rounded,
            ),

            const SizedBox(height: 20),

            const Text(
              "Description",

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              achievement.description,

              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.7,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}