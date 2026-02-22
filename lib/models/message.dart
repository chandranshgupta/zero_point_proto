class Message {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final Duration? selfDestruct;

  Message({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.selfDestruct,
  });
}