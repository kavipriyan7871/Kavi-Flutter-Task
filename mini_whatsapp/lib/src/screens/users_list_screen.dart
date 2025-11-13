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

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  /// Generate chat ID from both user IDs (sorted alphabetically)
  String chatIdFor(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// 🔹 Add contact by mobile number
  Future<void> _addContactByMobile(BuildContext context, String uid) async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final query = await firestore.collection('users').where('mobile', isEqualTo: mobile).limit(1).get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found with that mobile number')),
      );
      return;
    }

    final otherUser = query.docs.first;
    final otherUid = otherUser.id;
    if (otherUid == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot add yourself as a contact')),
      );
      return;
    }

    final otherData = otherUser.data() as Map<String, dynamic>;
    final contactRef = firestore.collection('users').doc(uid).collection('contacts').doc(otherUid);

    // ✅ Save contact to logged-in user’s contact list
    await contactRef.set({
      'uid': otherUid,
      'displayName': otherData['displayName'] ?? 'Unknown',
      'mobile': otherData['mobile'] ?? '',
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${otherData['displayName']} to your contacts')),
    );

    _mobileController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final uid = auth.currentUser!.uid;

    // 🔹 Stream only the current user’s contacts
    final contactsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .orderBy('addedAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contacts'),
        actions: [
          IconButton(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Search/Add by mobile
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _mobileController,
                  decoration: const InputDecoration(
                    hintText: 'Enter mobile number to add contact',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addContactByMobile(context, uid),
                child: const Text('Add'),
              ),
            ]),
          ),
          const Divider(),

          // 🔹 Show only user’s added contacts
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: contactsRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No contacts found.\nAdd a contact by mobile number.'));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data() as Map<String, dynamic>;
                    final otherUid = data['uid'] ?? '';
                    final name = data['displayName'] ?? 'Unknown';
                    final mobile = data['mobile'] ?? '';

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(name),
                      subtitle: Text('Mobile: $mobile'),
                      onTap: () {
                        final chatId = chatIdFor(uid, otherUid);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(peerId: otherUid, chatId: chatId),
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
