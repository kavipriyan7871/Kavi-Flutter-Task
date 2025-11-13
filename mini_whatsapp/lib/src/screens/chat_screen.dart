import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/recorder.dart';
import 'call_screen.dart';

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

  String? _currentUrl;
  bool _isPlaying = false;
  bool _isPaused = false;

  String peerName = "";
  String lastSeen = "Loading…";

  @override
  void initState() {
    super.initState();
    recorder.init();
    _loadPeerDetails();
  }

  Future<void> _loadPeerDetails() async {
    final doc = await FirebaseFirestore.instance.collection("users").doc(widget.peerId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        peerName = data["displayName"] ?? "Unknown";
      });

      _loadLastSeen();
    }
  }

  /// LAST SEEN READER
  void _loadLastSeen() {
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.peerId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      final data = doc.data()!;
      final last = data["lastSeen"];

      if (last == null) {
        setState(() => lastSeen = "Offline");
        return;
      }

      final dt = DateTime.fromMillisecondsSinceEpoch(last);
      setState(() {
        lastSeen = "Last seen: ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
      });
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    recorder.dispose();
    player.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _goDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText(String uid) async {
    final msg = _tc.text.trim();
    if (msg.isEmpty) return;

    await firestore.sendMessage(
      chatId: widget.chatId,
      fromId: uid,
      toId: widget.peerId,
      text: msg,
    );

    _tc.clear();
    _goDown();
  }

  Future<void> _startVoice() async {
    await recorder.start();
    setState(() => _isRecording = true);
  }

  Future<void> _stopVoice(String uid) async {
    final file = await recorder.stop();
    setState(() => _isRecording = false);

    if (file == null) return;

    final url = await storage.uploadVoiceFile(file, widget.chatId);

    await firestore.sendMessage(
      chatId: widget.chatId,
      fromId: uid,
      toId: widget.peerId,
      audioUrl: url,
    );

    _goDown();
  }

  /// AUDIO BUBBLE UI
  Widget _audioBubble(bool mine, String audioUrl) {
    final isPlay = _currentUrl == audioUrl && _isPlaying;
    final isPause = _currentUrl == audioUrl && _isPaused;

    IconData icon = isPlay ? Icons.pause : Icons.play_arrow;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: mine ? Colors.green[300] : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(icon, size: 26, color: Colors.black87),
            onPressed: () async {
              if (_currentUrl == audioUrl) {
                if (isPlay) {
                  await player.pause();
                  setState(() {
                    _isPlaying = false;
                    _isPaused = true;
                  });
                  return;
                }
                if (isPause) {
                  await player.play();
                  setState(() {
                    _isPlaying = true;
                    _isPaused = false;
                  });
                  return;
                }
              }

              await player.stop();
              await player.setUrl(audioUrl);
              await player.play();

              setState(() {
                _currentUrl = audioUrl;
                _isPlaying = true;
                _isPaused = false;
              });

              player.playerStateStream.listen((state) {
                if (state.processingState == ProcessingState.completed) {
                  setState(() {
                    _isPlaying = false;
                    _isPaused = false;
                    _currentUrl = null;
                  });
                }
              });
            },
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Voice message",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// TEXT BUBBLE UI
  Widget _textBubble(bool mine, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: BoxDecoration(
        color: mine ? Colors.green[300] : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  /// BUILD MESSAGE TILE
  Widget _messageItem(DocumentSnapshot doc, String uid) {
    final data = doc.data() as Map<String, dynamic>;
    final mine = data["fromId"] == uid;
    final isAudio = data["type"] == "audio";

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: isAudio
          ? _audioBubble(mine, data["audioUrl"])
          : _textBubble(mine, data["text"] ?? ""),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthService>(context).currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),

      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        titleSpacing: 0,

        title: Row(
          children: [
            const SizedBox(width: 5),
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  lastSeen,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    peerId: widget.peerId,
                    chatId: widget.chatId,
                    callType: CallType.audio,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    peerId: widget.peerId,
                    chatId: widget.chatId,
                    callType: CallType.video,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          /// MESSAGES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.messagesStream(widget.chatId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                _goDown();

                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) => _messageItem(docs[i], uid),
                );
              },
            ),
          ),

          /// INPUT BAR
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  /// Mic Button
                  GestureDetector(
                    onLongPressStart: (_) => _startVoice(),
                    onLongPressEnd: (_) => _stopVoice(uid),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          _isRecording ? Colors.red : Colors.blueAccent,
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// Input box
                  Expanded(
                    child: TextField(
                      controller: _tc,
                      decoration: InputDecoration(
                        hintText: "Type message…",
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// Send button
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendText(uid),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
