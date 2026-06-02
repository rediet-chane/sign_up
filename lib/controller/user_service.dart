import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save user profile data when they sign up
  Future<void> saveUserProfile({
    required String firstName,
    required String lastName,
    required String storeName,
    required String email,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'storeName': storeName,
      'email': email,
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user profile data by UID
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  // Get current user's profile (convenience method)
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }
}