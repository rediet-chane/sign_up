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
    
    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
    debugPrint('✅ Saved FCM token for ${user.uid}');
  }

  Future<void> sendPushNotificationToAdmin({
    required String title,
    required String body,
  }) async {
    try {
      var admins = await _firestore.collection('users').where('role', isEqualTo: 'admin').get();
      
      if (admins.docs.isEmpty) {
        debugPrint('⚠️ No admin users found');
        return;
      }

      for (var adminDoc in admins.docs) {
        final adminData = adminDoc.data();
        final fcmToken = adminData['fcmToken'];
        
        if (fcmToken != null && fcmToken.toString().isNotEmpty) {
          await _sendFCMMessage(token: fcmToken, title: title, body: body);
        } else {
          debugPrint('⚠️ Admin ${adminDoc.id} has no FCM token');
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending push notification: $e');
    }
  }

  // ✅ UPDATED: Now calls your Render Backend using V1 API
  Future<void> _sendFCMMessage({
    required String token,
    required String title,
    required String body,
  }) async {
    const String renderUrl = 'https://fcm-notification-server-yupr.onrender.com/send-notification';

    final Map<String, dynamic> message = {
      'token': token,
      'title': title,
      'body': body,
    };

    try {
      final response = await http.post(
        Uri.parse(renderUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Push notification sent successfully via Render V1 API');
      } else {
        debugPrint('❌ Failed to send push notification: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error calling notification service: $e');
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

  Stream<QuerySnapshot> getAllUsers() => 
      _firestore.collection('users').snapshots();

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

  Future<void> createVendorSignupNotification(String vendorId, String name, String email) async {
    debugPrint('🔵 Creating notification for vendor: $vendorId');
    
    var admins = await _firestore.collection('users').where('role', isEqualTo: 'admin').get();
    
    if (admins.docs.isEmpty) {
      debugPrint('⚠️ No admin users found in database');
      return;
    }

    for (var adminDoc in admins.docs) {
      await _firestore.collection('notifications').add({
        'adminId': adminDoc.id,
        'vendorId': vendorId,
        'vendorName': name,
        'vendorEmail': email,
        'type': 'vendor_signup',
        'message': 'New vendor $name wants to join',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Notification document created for admin: ${adminDoc.id}');
      
      await sendPushNotificationToAdmin(
        title: 'New Vendor Signup!',
        body: '$name ($email) wants to join as a vendor',
      );
    }
  }

  Stream<QuerySnapshot> getAdminNotifications() {
    User? u = _auth.currentUser;
    if (u == null) return const Stream.empty();
    
    return _firestore.collection('notifications')
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
    
    return _firestore.collection('notifications')
        .where('adminId', isEqualTo: u.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }
}