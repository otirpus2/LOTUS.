class MessageModel {
  final String sender;
  final String message;
  final bool isMe;

  MessageModel({
    required this.sender,
    required this.message,
    required this.isMe,
  });
}