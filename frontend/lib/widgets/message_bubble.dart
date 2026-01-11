import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Mesaj balonu widget'ı - WhatsApp benzeri tasarım
class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMine;
  final DateTime timestamp;
  final bool isRead;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.timestamp,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMine ? 64 : 0,
          right: isMine ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF667eea) : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMine
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isMine
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    color: isMine ? Colors.white70 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead ? Colors.blue[300] : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dt.year, dt.month, dt.day);

    if (messageDate == today) {
      // Bugün - sadece saat
      return DateFormat('HH:mm').format(dt);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Dün
      return 'Dün ${DateFormat('HH:mm').format(dt)}';
    } else {
      // Diğer günler
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    }
  }
}
