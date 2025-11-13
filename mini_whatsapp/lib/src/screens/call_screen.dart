// lib/screens/call_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../config/app_config.dart';

enum CallType { audio, video }

class CallScreen extends StatefulWidget {
  final String peerId;
  final String chatId;
  final CallType callType;

  const CallScreen({
    super.key,
    required this.peerId,
    required this.chatId,
    required this.callType,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late String userID;
  late String userName;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    userID = user?.uid ?? "guest_${DateTime.now().millisecondsSinceEpoch}";
    userName = user?.displayName ?? "User-${userID.substring(0, 6)}";
  }

  @override
  Widget build(BuildContext context) {
    final callID = "call_${widget.chatId}";

    final config = widget.callType == CallType.audio
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();

    // mic/cam settings
    config.turnOnCameraWhenJoining = widget.callType == CallType.video;
    config.turnOnMicrophoneWhenJoining = true;

    return Scaffold(
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: AppConfig.zegoAppID,
          appSign: AppConfig.zegoAppSign, // ✔ DIRECT APPSIGN
          userID: userID,
          userName: userName,
          callID: callID,
          config: config,
        ),
      ),
    );
  }
}
