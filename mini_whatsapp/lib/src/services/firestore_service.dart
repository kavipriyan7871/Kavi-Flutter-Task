import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final uuid = const Uuid();

  /// Ensure chat exists
  Future<void> ensureChatExists({
    required String chatId,
    required List<String> participants,
  }) async {
    final chatRef = firestore.collection('chats').doc(chatId);
    final snap = await chatRef.get();

    if (!snap.exists) {
      await chatRef.set({
        "participants": participants,
        "createdAt": DateTime.now().millisecondsSinceEpoch,
        "lastMessage": "",
        "lastTimestamp": DateTime.now().millisecondsSinceEpoch
      });
    } else {
      await chatRef.set({
        "participants": participants,
      }, SetOptions(merge: true));
    }
  }

  /// --------------------------------------------------------------
  /// ⭐ SEND MESSAGE (TEXT / IMAGE / VIDEO / AUDIO)
  /// --------------------------------------------------------------
  Future<void> sendMessage({
    required String chatId,
    required String fromId,
    required String toId,
    required String type,      // "text", "image", "video", "audio"

    String text = "",
    String imageUrl = "",
    String videoUrl = "",
    String audioUrl = "",
  }) async {
    final participants = [fromId, toId]..sort();
    await ensureChatExists(chatId: chatId, participants: participants);

    final id = uuid.v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // -------------------------
    // Build message data
    // -------------------------
    final msg = {
      "id": id,
      "fromId": fromId,
      "toId": toId,
      "type": type,            // IMPORTANT
      "text": text,
      "imageUrl": imageUrl,
      "videoUrl": videoUrl,
      "audioUrl": audioUrl,
      "timestamp": timestamp,
    };

    // Save message
    await firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(id)
        .set(msg);

    // -------------------------
    // Update last message summary
    // -------------------------
    String lastMsg = "";

    if (type == "text") lastMsg = text;
    if (type == "image") lastMsg = "📷 Photo";
    if (type == "video") lastMsg = "🎬 Video";
    if (type == "audio") lastMsg = "🎤 Voice Message";

    await firestore.collection("chats").doc(chatId).set({
      "lastMessage": lastMsg,
      "lastTimestamp": timestamp,
      "participants": participants,
    }, SetOptions(merge: true));
  }

  /// --------------------------------------------------------------
  /// ⭐ Stream messages
  /// --------------------------------------------------------------
  Stream<QuerySnapshot> messagesStream(String chatId) {
    return firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }
}
