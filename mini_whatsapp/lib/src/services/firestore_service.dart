import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final uuid = const Uuid();

  /// Ensure chat document exists
  Future<void> ensureChatExists({
    required String chatId,
    required List<String> participants,
  }) async {
    final chatRef = firestore.collection('chats').doc(chatId);
    final snap = await chatRef.get();

    if (!snap.exists) {
      await chatRef.set({
        'participants': participants,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastMessage': '',
        'lastTimestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await chatRef.set({
        'participants': participants,
      }, SetOptions(merge: true));
    }
  }

  /// Send a message (text or audio)
  Future<void> sendMessage({
    required String chatId,
    required String fromId,
    required String toId,
    String text = '',
    String? audioUrl,
  }) async {
    final participants = [fromId, toId]..sort();
    await ensureChatExists(chatId: chatId, participants: participants);

    final id = uuid.v4();

    // Auto detect message type
    final messageType = audioUrl != null ? "audio" : "text";

    final msg = {
      "id": id,
      "fromId": fromId,
      "toId": toId,
      "text": text,
      "audioUrl": audioUrl ?? "",
      "type": messageType,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    final msgRef = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(id);

    await msgRef.set(msg);

    /// Update last message
    await firestore.collection('chats').doc(chatId).set({
      'lastMessage': messageType == "text" ? text : "[Voice Message]",
      'lastTimestamp': msg["timestamp"],
    }, SetOptions(merge: true));
  }

  /// Live message stream
  Stream<QuerySnapshot> messagesStream(String chatId) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // FIXED
        .snapshots();
  }
}
