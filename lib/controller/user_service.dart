import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveUserProfile({
    required String firstName,
    required String lastName,
    required String storeName,
    required String email,
    required String role,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String initialStatus = (role == 'vendor') ? 'pending' : 'approved';

    await _firestore.collection('users').doc(user.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'storeName': storeName,
      'email': email,
      'role': role,
      'status': initialStatus,
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  Future<String?> getCurrentUserRole() async {
    final profile = await getCurrentUserProfile();
    return profile?['role'] ?? 'customer';
  }

  Future<String?> getCurrentUserStatus() async {
    final profile = await getCurrentUserProfile();
    return profile?['status'] ?? 'pending';
  }

  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  // THIS IS THE METHOD THAT WAS MISSING
  Future<void> updateUserRoleAndStatus(String userId, String newRole, String newStatus) async {
    await _firestore.collection('users').doc(userId).update({
      'role': newRole,
      'status': newStatus,
    });
  }
}