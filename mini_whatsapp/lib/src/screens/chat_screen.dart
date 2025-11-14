import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/recorder.dart';
import 'call_screen.dart';
import 'image_view_screen.dart';
import 'video_view_screen.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String chatId;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.chatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _tc = TextEditingController();
  final firestore = FirestoreService();
  final storage = StorageService();
  final recorder = RecorderUtil();
  final player = AudioPlayer();
  final ScrollController _scroll = ScrollController();

  bool _isRecording = false;

  String peerName = "";

  // AUDIO playback state ----------------
  String? _currentUrl;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    recorder.init();
    loadPeerName();
  }

  Future<void> loadPeerName() async {
    final doc = await FirebaseFirestore.instance.collection("users").doc(widget.peerId).get();
    if (doc.exists) {
      setState(() => peerName = doc["displayName"] ?? "User");
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    recorder.dispose();
    player.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    });
  }

  // -------------------------------- SEND TEXT ----------------------------------
  Future<void> sendText(String uid) async {
    final msg = _tc.text.trim();
    if (msg.isEmpty) return;

    await firestore.sendMessage(
      chatId: widget.chatId,
      fromId: uid,
      toId: widget.peerId,
      type: "text",
      text: msg,
    );

    _tc.clear();
    scrollDown();
  }

  // -------------------------------- RECORD AUDIO ----------------------------------
  Future<void> startRecord() async {
    if (!await Permission.microphone.request().isGranted) return;

    await recorder.start();
    setState(() => _isRecording = true);
  }

  Future<void> stopRecord(String uid) async {
    final file = await recorder.stop();
    setState(() => _isRecording = false);

    if (file == null) return;

    final url = await storage.uploadVoiceFile(file, widget.chatId);

    await firestore.sendMessage(
      chatId: widget.chatId,
      fromId: uid,
      toId: widget.peerId,
      type: "audio",
      audioUrl: url,
      text: "",
      imageUrl: "",
      videoUrl: "",
    );

    scrollDown();
  }

  // -------------------------------- SEND IMAGE ----------------------------------
  Future<void> sendImage(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final url = await storage.uploadAnyFile(File(picked.path), widget.chatId);

    await firestore.sendMessage(
      chatId: widget.chatId,
      fromId: uid,
      toId: widget.peerId,
      type: "image",
      imageUrl: url,
      text: "",
      videoUrl: "",
      audioUrl: "",
    );

    scrollDown();
  }

  // -------------------------------- SEND VIDEO ----------------------------------
  Future<void> sendVideo(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    final url = await storage.uploadAnyFile(File(picked.path), widget.chatId);

    await firestore.sendMessage(
      chatId: widget.chatId,
      fromId: uid,
      toId: widget.peerId,
      type: "video",
      videoUrl: url,
      text: "",
      imageUrl: "",
      audioUrl: "",
    );

    scrollDown();
  }

  // ---------------------------- BUBBLES -------------------------------------

  Widget textBubble(bool mine, String text) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: mine ? Colors.green[300] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }

  Widget imageBubble(bool mine, String url) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ImageViewScreen(imageUrl: url)));
        },
        child: Hero(
          tag: url,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url,
                width: 230, height: 230, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget videoBubble(bool mine, String url) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VideoViewScreen(videoUrl: url)),
          );
        },
        child: Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black26,
          ),
          child: const Center(
            child: Icon(Icons.play_circle_fill,
                size: 70, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget audioBubble(bool mine, String url) {
    final isPlaying = _currentUrl == url && _isPlaying;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
            color: mine ? Colors.green[300] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () async {
                if (isPlaying) {
                  await player.pause();
                  setState(() => _isPlaying = false);
                } else {
                  await player.stop();
                  await player.setUrl(url);
                  await player.play();

                  setState(() {
                    _currentUrl = url;
                    _isPlaying = true;
                  });

                  player.playerStateStream.listen((state) {
                    if (state.processingState == ProcessingState.completed) {
                      setState(() {
                        _isPlaying = false;
                        _currentUrl = null;
                      });
                    }
                  });
                }
              },
            ),
            const Text("Voice message")
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------

  Widget messageItem(DocumentSnapshot doc, String uid) {
    final data = doc.data() as Map<String, dynamic>;
    final mine = data["fromId"] == uid;

    switch (data["type"]) {
      case "text":
        return textBubble(mine, data["text"]);
      case "image":
        return imageBubble(mine, data["imageUrl"]);
      case "video":
        return videoBubble(mine, data["videoUrl"]);
      case "audio":
        return audioBubble(mine, data["audioUrl"]);
      default:
        return const SizedBox();
    }
  }

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthService>(context).currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text(peerName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.messagesStream(widget.chatId),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                scrollDown();

                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) => messageItem(docs[i], uid),
                );
              },
            ),
          ),

          SafeArea(child: inputBar(uid)),
        ],
      ),
    );
  }

  Widget inputBar(String uid) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.photo),
              onPressed: () => sendImage(uid)),
          IconButton(
              icon: const Icon(Icons.video_library),
              onPressed: () => sendVideo(uid)),

          GestureDetector(
            onLongPressStart: (_) => startRecord(),
            onLongPressEnd: (_) => stopRecord(uid),
            child: CircleAvatar(
              backgroundColor: _isRecording ? Colors.red : Colors.blue,
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: _tc,
              decoration: const InputDecoration(
                hintText: "Type message...",
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(25))),
              ),
            ),
          ),

          CircleAvatar(
            backgroundColor: Colors.green,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => sendText(uid),
            ),
          ),
        ],
      ),
    );
  }
}
