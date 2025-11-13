class MessageModel {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final String? audioUrl;
  final int timestamp;

  MessageModel({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    this.audioUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fromId': fromId,
        'toId': toId,
        'text': text,
        'audioUrl': audioUrl,
        'timestamp': timestamp,
      };

  static MessageModel fromMap(Map<String, dynamic> m) {
    return MessageModel(
      id: m['id'] ?? '',
      fromId: m['fromId'] ?? '',
      toId: m['toId'] ?? '',
      text: m['text'] ?? '',
      audioUrl: m['audioUrl'],
      timestamp: m['timestamp'] ?? 0,
    );
  }
}
