import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

    await _firestore.collection('users').doc(user.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'storeName': storeName,
      'email': email,
      'role': role,
      'status': role == 'vendor' ? 'pending' : 'approved',
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveFCMToken(String token) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // set(merge:true) instead of update() — update() throws if the user
    // document doesn't exist yet, which can happen if the token save races
    // ahead of saveUserProfile() right after signup.
    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
    debugPrint('✅ Saved FCM token for ${user.uid}');
  }

  // This now only tells the Render server "a vendor signed up" — it does
  // NOT read or send any admin's fcmToken itself. The server looks up
  // admins and their tokens using its own Firebase Admin credentials,
  // and also writes the Firestore notification doc. This is why
  // firestore.rules now blocks the client from creating notification
  // docs directly (allow create: if false) — only the server does that.
  Future<void> createVendorSignupNotification(
      String vendorId, String name, String email) async {
    const String renderUrl =
        'https://fcm-notification-server-yupr.onrender.com/vendor-signup-notification';

    try {
      final response = await http.post(
        Uri.parse(renderUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vendorId': vendorId,
          'vendorName': name,
          'vendorEmail': email,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Vendor signup notification triggered: ${response.body}');
      } else {
        debugPrint('❌ Notification server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error calling notification server: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    var doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  Future<String?> getCurrentUserRole() async =>
      (await getCurrentUserProfile())?['role'] as String?;

  Future<String?> getCurrentUserStatus() async =>
      (await getCurrentUserProfile())?['status'] as String?;

  Stream<QuerySnapshot> getAllUsers() => _firestore.collection('users').snapshots();

  Future<void> updateUserRoleAndStatus(String uid, String role, String status) async {
    debugPrint('🔵 Updating user $uid to role: $role, status: $status');

    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'status': status,
      });
      debugPrint('✅ User $uid updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user $uid: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getAdminNotifications() {
    User? u = _auth.currentUser;
    if (u == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('adminId', isEqualTo: u.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markNotificationRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({'read': true});
  }

  Stream<int> getUnreadNotificationCount() {
    User? u = _auth.currentUser;
    if (u == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('adminId', isEqualTo: u.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }
}