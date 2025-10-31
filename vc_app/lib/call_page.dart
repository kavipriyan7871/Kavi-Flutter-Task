import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:uuid/uuid.dart';

class CallPage extends StatelessWidget {
  final String callID;
  final String userName;

  const CallPage({
    super.key,
    required this.callID,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // Use a guaranteed unique userID (prevents disconnects)
    final String userID = const Uuid().v4();

    return SafeArea(
      child: Scaffold(
        body: ZegoUIKitPrebuiltCall(
          appID: int.parse(dotenv.env['APP_ID'] ?? '0'),
          appSign: dotenv.env['APP_SIGN'] ?? '',
          userID: userID,
          userName: userName,
          callID: callID,
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        ),
      ),
    );
  }
}
