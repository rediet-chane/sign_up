import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthController {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: '303868688064-2i82hffval6v5nvf3gbs83ffqi5jo9l6.apps.googleusercontent.com',
  );

  static bool isUserSignedIn() => _auth.currentUser != null;
  static User? getCurrentUser() => _auth.currentUser;

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⚠️ Google sign out timed out');
          return null;
        },
      );
    } catch (e) {
      debugPrint('⚠️ Google sign out error: $e');
    }

    try {
      await _auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Firebase sign out error: $e');
      rethrow;
    }
  }

  // ✅ NEW: Delete account method
  static Future<bool> deleteAccount() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      final uid = user.uid;
      
      // 1. Delete Firestore document
      await _firestore.collection('users').doc(uid).delete();
      debugPrint('✅ Deleted Firestore document for $uid');
      
      // 2. Delete Firebase Auth user
      await user.delete();
      debugPrint('✅ Deleted Firebase Auth user for $uid');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting account: $e');
      
      // If re-authentication is needed
      if (e.toString().contains('requires-recent-login')) {
        debugPrint('⚠️ Re-authentication required');
        // You may need to show a dialog asking user to re-login
      }
      return false;
    }
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    return (await _auth.signInWithEmailAndPassword(email: email, password: password)).user;
  }

  static Future<User?> signUpWithEmail(String email, String password) async {
    return (await _auth.createUserWithEmailAndPassword(email: email, password: password)).user;
  }

  static Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('⚠️ User cancelled sign-in');
        return null;
      }

      debugPrint('✅ Google user: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await UserService().saveUserProfile(
          firstName: googleUser.displayName?.split(' ').first ?? 'User',
          lastName: googleUser.displayName?.split(' ').last ?? '',
          storeName: '${googleUser.displayName}\'s Store',
          email: googleUser.email,
          role: 'customer',
        );
      }
      
      debugPrint('🎉 Firebase auth successful: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      debugPrint('❌ Google Sign-In Error: $e');
      return null;
    }
  }

  static Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user == null) return 'customer';
    return (await UserService().getCurrentUserRole()) ?? 'customer';
  }
}