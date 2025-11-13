import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _mobileController = TextEditingController();

  static const skyBlue = Color(0xFF0A99FF);
  static const darkBg = Color(0xFF021F39);

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  /// Generate Chat ID
  String chatIdFor(String a, String b) {
    final list = [a, b]..sort();
    return "${list[0]}_${list[1]}";
  }

  /// Add Contact by Mobile
  Future<void> _addContactByMobile(BuildContext context, String uid) async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) return;

    final firestore = FirebaseFirestore.instance;

    final query = await firestore
        .collection("users")
        .where("mobile", isEqualTo: mobile)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user found with this mobile number")),
      );
      return;
    }

    final otherUser = query.docs.first;
    final otherUid = otherUser.id;

    if (otherUid == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot add yourself")),
      );
      return;
    }

    final data = otherUser.data() as Map<String, dynamic>;

    await firestore
        .collection("users")
        .doc(uid)
        .collection("contacts")
        .doc(otherUid)
        .set({
      "uid": otherUid,
      "displayName": data["displayName"] ?? "Unknown",
      "mobile": data["mobile"],
      "addedAt": DateTime.now().millisecondsSinceEpoch,
    });

    _mobileController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${data['displayName']} added to contacts")),
    );
  }

  /// Logout Confirmation
  Future<void> _confirmLogout(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, color: skyBlue, size: 60),
              const SizedBox(height: 12),
              const Text(
                "Logout?",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to exit?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    child: const Text("Cancel", style: TextStyle(color: skyBlue)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skyBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await auth.signOut();
                    },
                    child: const Text("Logout",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final uid = auth.currentUser!.uid;

    final contactsRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("contacts")
        .orderBy("addedAt", descending: true);

    return Scaffold(
      backgroundColor: darkBg,

      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        title: const Text(
          "Contacts",
          style: TextStyle(
            color: skyBlue,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: skyBlue, size: 30),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),

      body: Column(
        children: [
          // Add Contact Box
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: skyBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Add contact by mobile number",
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skyBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _addContactByMobile(context, uid),
                    child: const Text("Add"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // CONTACTS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: contactsRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: skyBlue));
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No contacts yet.\nAdd one using mobile number.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.white24, height: 1),

                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final otherUid = data["uid"];
                    final name = data["displayName"] ?? "Unknown";

                    final chatId = chatIdFor(uid, otherUid);

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("chats")
                          .doc(chatId)
                          .collection("messages")
                          .orderBy("timestamp", descending: true)
                          .limit(1)
                          .snapshots(),

                      builder: (context, msgSnap) {
                        String preview = "No messages yet";

                        if (msgSnap.hasData &&
                            msgSnap.data!.docs.isNotEmpty) {
                          final lastMsg = msgSnap.data!.docs.first.data()
                              as Map<String, dynamic>;

                          if (lastMsg["type"] == "text") {
                            preview = lastMsg["text"] ?? "";
                          } else if (lastMsg["type"] == "audio") {
                            preview = "🎤 Voice message";
                          } else if (lastMsg["type"] == "image") {
                            preview = "📷 Photo";
                          } else {
                            preview = "New message";
                          }
                        }

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  peerId: otherUid,
                                  chatId: chatId,
                                ),
                              ),
                            );
                          },

                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),

                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: skyBlue.withOpacity(0.55),
                              child: const Icon(Icons.person,
                                  size: 28, color: Colors.white),
                            ),

                            title: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            subtitle: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 14),
                            ),

                            trailing: const Icon(
                              Icons.chat_bubble_rounded,
                              color: skyBlue,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
