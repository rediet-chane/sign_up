import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

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
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  static Future<User?> signUpWithEmail(String email, String password) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // 🔄 CHANGED: Now reads role from Firestore instead of email
  static Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user == null) return 'customer';
    
    UserService userService = UserService();
    String? role = await userService.getCurrentUserRole();
    return role ?? 'customer';
  }
}