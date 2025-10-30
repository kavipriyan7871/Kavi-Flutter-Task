import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallPage extends StatelessWidget {
  final String callID;
  final String userName;

  const CallPage({
    Key? key,
    required this.callID,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Each user must have a unique ID
    final String userID = userName; // or generate unique userID if needed

    return SafeArea(
      child: Scaffold(
        body: ZegoUIKitPrebuiltCall(
          appID: int.parse(dotenv.env['APP_ID']!), // ZEGOCLOUD App ID
          appSign: dotenv.env['APP_SIGN']!, // ZEGOCLOUD App Sign
          userID: userID, // must be unique per user
          userName: userName,
          callID: callID, // same callID connects both users
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            ..onOnlySelfInRoom = (context) {
              // Handle when the other user leaves
              debugPrint("You are alone in the room.");
            }
            ..onHangUp = () {
              Navigator.of(context).pop(); // exit to previous screen
            },
        ),
      ),
    );
  }
}

extension on ZegoUIKitPrebuiltCallConfig {
  set onHangUp(Null Function() onHangUp) {}

  set onOnlySelfInRoom(Null Function(dynamic context) onOnlySelfInRoom) {}
}
