import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controller/auth_controller.dart';
import '../../controller/app_router.dart';
import '../../controller/user_service.dart'; // <-- Import this

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;
  final UserService _userService = UserService(); // <-- Add this

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _storeNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 1. Create Firebase Auth account
        User? user = await AuthController.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (mounted && user != null) {
          // 2. Save profile data to Firestore
          await _userService.saveUserProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            storeName: _storeNameController.text.trim(),
            email: _emailController.text.trim(),
          );
          if (mounted) {
          _showMessage('Account created successfully!', isError: false);
          AppRouter.navigateBasedOnRole(context, user);
        }
      }
      } on FirebaseAuthException catch (e) {
        _showMessage(e.message ?? 'Failed to create account', isError: true);
      } catch (e) {
        _showMessage('Error: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDCEEFF), Color(0xFFE8F0FE)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person_add_outlined, size: 24, color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 20),
                      const Text('Create an account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('Sign up with email and password', style: TextStyle(fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 28),
                      
                      // First Name & Last Name Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _firstNameController,
                              hint: 'First Name',
                              icon: Icons.person_outline,
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _lastNameController,
                              hint: 'Last Name',
                              icon: Icons.person_outline,
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Store Name
                      _buildField(
                        controller: _storeNameController,
                        hint: 'Store Name',
                        icon: Icons.store_outlined,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Email
                      _buildField(
                        controller: _emailController,
                        hint: 'Email',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Password
                      _buildField(
                        controller: _passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _hidePassword,
                        suffixIcon: IconButton(
                          icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                        ),
                        validator: (v) => v == null || v.length < 8 ? 'Min 8 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Confirm Password
                      _buildField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: _hideConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(_hideConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                          onPressed: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('or sign up with', style: TextStyle(color: Colors.black54, fontSize: 12))), Expanded(child: Divider())]),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_socialButton(Icons.g_mobiledata, Colors.red), const SizedBox(width: 16), _socialButton(Icons.facebook, Colors.blue), const SizedBox(width: 16), _socialButton(Icons.apple, Colors.black)]),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Already have an account?', style: TextStyle(color: Colors.black54, fontSize: 12)), TextButton(onPressed: () => Navigator.pop(context), child: const Text('Log In', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w600)))]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}