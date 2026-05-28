import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool isUserSignedIn() {
    return _auth.currentUser != null;
  }
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user!;
    } catch (e) {
       rethrow;
    }
   }
   static Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user!;
    } catch (e) {
      rethrow;
    }
}
static String getUserRole(User? user) {
  if (user == null) return 'guest';
  String email = user.email ??'';
  if (email.contains('admin')) return 'admin';
  if (email.contains('vendor')) return 'vendor';
 
  return 'user';
}
}