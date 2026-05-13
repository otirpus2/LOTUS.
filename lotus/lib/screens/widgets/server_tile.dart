import 'package:flutter/material.dart';

class ServerTile extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const ServerTile({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor =
    Color(0xFF5B4CF0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: active
              ? primaryColor
              : const Color(0xFFEEF2FF),
          borderRadius:
          BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: active
              ? Colors.white
              : primaryColor,
        ),
      ),
    );
  }
}