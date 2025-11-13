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

  @override
  void initState() {
    super.initState();
    recorder.init();
  }

  @override
  void dispose() {
    _tc.dispose();
    recorder.dispose();
    player.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// AUTO SCROLL TO BOTTOM
  void _goDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0.0,                                   // 👈 Because reversed = true
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// SEND TEXT
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

  /// START RECORDING
  Future<void> _startVoice() async {
    await recorder.start();
    setState(() => _isRecording = true);
  }

  /// STOP + UPLOAD
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

  /// MESSAGE BUBBLE
  Widget _messageItem(DocumentSnapshot doc, String uid) {
    final data = doc.data() as Map<String, dynamic>;
    final mine = data["fromId"] == uid;
    final isAudio = data["type"] == "audio";
    final audioUrl = data["audioUrl"];

    if (isAudio && audioUrl != null) {
      final isPlay = _currentUrl == audioUrl && _isPlaying;
      final isPause = _currentUrl == audioUrl && _isPaused;

      IconData icon = isPlay ? Icons.pause : Icons.play_arrow;

      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: const Text("Voice"),
          style: ElevatedButton.styleFrom(
            backgroundColor: mine ? Colors.green[300] : Colors.grey[400],
          ),
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
      );
    }

    /// TEXT MESSAGE
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: mine ? Colors.green[300] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(data["text"] ?? ""),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthService>(context).currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: "Audio Call",
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
            icon: const Icon(Icons.videocam),
            tooltip: "Video Call",
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
          /// CHAT LIST
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
                  reverse: true,                        // 👈 IMPORTANT
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10, top: 10),
                  itemCount: docs.length,
                  itemBuilder: (c, i) => _messageItem(docs[i], uid),
                );
              },
            ),
          ),

          /// INPUT BAR
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? Colors.red : Colors.black,
                  ),
                  onPressed: () async {
                    _isRecording ? await _stopVoice(uid) : await _startVoice();
                  },
                ),

                Expanded(
                  child: TextField(
                    controller: _tc,
                    decoration: const InputDecoration(
                      hintText: "Type message…",
                      border: InputBorder.none,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendText(uid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
