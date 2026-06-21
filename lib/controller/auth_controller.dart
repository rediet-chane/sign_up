import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthController {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: '303868688064-2i82hffval6v5nvf3gbs83ffqi5jo9l6.apps.googleusercontent.com', 
  );

  static bool isUserSignedIn() => _auth.currentUser != null;
  static User? getCurrentUser() => _auth.currentUser;

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    return (await _auth.signInWithEmailAndPassword(email: email, password: password)).user;
  }

  static Future<User?> signUpWithEmail(String email, String password) async {
    return (await _auth.createUserWithEmailAndPassword(email: email, password: password)).user;
  }

  // ✅ v6.x: Simple signIn() method that opens popup
  static Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Starting Google Sign-In...');
      
      // Trigger Google sign-in (opens popup on web)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('⚠️ User cancelled sign-in');
        return null;
      }

      debugPrint('✅ Google user: ${googleUser.email}');

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // If new user, create profile
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