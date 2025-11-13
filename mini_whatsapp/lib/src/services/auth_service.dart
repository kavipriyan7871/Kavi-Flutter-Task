import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userChanges => _auth.authStateChanges();

  /// Login with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Register new user (with display name & mobile number)
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String displayName,
    String mobile,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name locally
      await cred.user!.updateDisplayName(displayName);

      // Save user info to Firestore (merge to avoid overwriting future fields)
      final userDocRef = _firestore.collection('users').doc(cred.user!.uid);

      // Only write if not exists (optional)
      final doc = await userDocRef.get();
      if (!doc.exists) {
        await userDocRef.set({
          'uid': cred.user!.uid,
          'email': email,
          'displayName': displayName,
          'mobile': mobile,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      } else {
        // If doc exists, merge mobile/displayName in case of social sign-in flows
        await userDocRef.set({
          'displayName': displayName,
          'mobile': mobile,
        }, SetOptions(merge: true));
      }

      notifyListeners();
      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update mobile for current user
  Future<void> updateMobile(String mobile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final userDocRef = _firestore.collection('users').doc(user.uid);
    await userDocRef.set({'mobile': mobile, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
        SetOptions(merge: true));
    notifyListeners();
  }

  /// Get user document (convenience)
  Future<DocumentSnapshot> getUserDoc(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }
}