class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;
  final bool isMe;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    required this.isMe,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final senderId = json['user_id'] ?? json['sender_id'];
    final profile = json['profiles'] as Map<String, dynamic>?;
    final fullName = profile?['full_name'] ?? profile?['username'] ?? 'Unknown';
    
    return MessageModel(
      id: json['id'] as String,
      senderId: senderId as String,
      senderName: fullName,
      message: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isMe: senderId == currentUserId,
    );
  }
}