import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controller/auth_controller.dart';
import '../../controller/app_router.dart';
import '../../controller/user_service.dart';

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
  String _selectedRole = 'customer';
  final UserService _userService = UserService();

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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      User? user = await AuthController.signUpWithEmail(
        _emailController.text.trim(), 
        _passwordController.text.trim(),
      );

      if (mounted && user != null) {
        await _userService.saveUserProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          storeName: _storeNameController.text.trim(),
          email: _emailController.text.trim(),
          role: _selectedRole,
        );

        if (_selectedRole == 'vendor') {
          try {
            await _userService.createVendorSignupNotification(
              user.uid,
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
              _emailController.text.trim(),
            );
          } catch (e) {
            debugPrint('⚠️ Notification failed: $e');
          }
        }

        if (mounted) {
          _showMessage('Account created!', isError: false);
          AppRouter.navigateBasedOnRole(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Sign up failed', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      User? user = await AuthController.signInWithGoogle();
      if (mounted && user != null) {
        _showMessage('Signed in successfully!', isError: false);
        AppRouter.navigateBasedOnRole(context);
      } else if (mounted) {
        _showMessage('Sign-in cancelled', isError: false);
      }
    } catch (e) {
      if (mounted) _showMessage('Google Sign-In failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Widget _buildField({
    required TextEditingController c, 
    required String h, 
    required IconData i, 
    TextInputType? kt, 
    bool obs = false, 
    Widget? suf, 
    String? Function(String?)? v
  }) {
    return TextFormField(
      controller: c, 
      keyboardType: kt, 
      obscureText: obs, 
      validator: v, 
      decoration: InputDecoration(
        hintText: h, 
        prefixIcon: Icon(i, color: Colors.grey), 
        suffixIcon: suf, 
        filled: true, 
        fillColor: const Color(0xFFFAFAFA), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), 
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12)
      )
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
            colors: [Color(0xFFDCEEFF), Color(0xFFE8F0FE)]
          )
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 32)]
                ), 
                child: Form(
                  key: _formKey, 
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      const Icon(Icons.person_add_outlined, size: 40), 
                      const SizedBox(height: 16),
                      const Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      
                      Row(children: [
                        Expanded(child: _buildField(c: _firstNameController, h: 'First Name', i: Icons.person, v: (v) => v!.isEmpty ? 'Required' : null)), 
                        const SizedBox(width: 12), 
                        Expanded(child: _buildField(c: _lastNameController, h: 'Last Name', i: Icons.person, v: (v) => v!.isEmpty ? 'Required' : null))
                      ]),
                      const SizedBox(height: 12),
                      _buildField(c: _storeNameController, h: 'Store Name', i: Icons.store, v: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 12),
                      _buildField(c: _emailController, h: 'Email', i: Icons.mail, kt: TextInputType.emailAddress, v: (v) => !v!.contains('@') ? 'Invalid email' : null),
                      const SizedBox(height: 12),
                      _buildField(
                        c: _passwordController, h: 'Password', i: Icons.lock, obs: _hidePassword, 
                        suf: IconButton(icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _hidePassword = !_hidePassword)), 
                        v: (v) => v!.length < 8 ? 'Min 8 chars' : null
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        c: _confirmPasswordController, h: 'Confirm Password', i: Icons.lock, obs: _hideConfirmPassword, 
                        suf: IconButton(icon: Icon(_hideConfirmPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword)), 
                        v: (v) => v != _passwordController.text ? 'Passwords mismatch' : null
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole, 
                        decoration: InputDecoration(prefixIcon: const Icon(Icons.badge), filled: true, fillColor: const Color(0xFFFAFAFA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), 
                        items: const [DropdownMenuItem(value: 'customer', child: Text('Customer')), DropdownMenuItem(value: 'vendor', child: Text('Vendor'))], 
                        onChanged: (v) => setState(() => _selectedRole = v!)
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity, height: 48, 
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp, 
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign Up', style: TextStyle(color: Colors.white))
                        )
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            const Expanded(child: Divider(thickness: 1, color: Color(0xFFE8E8E8))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ),
                            const Expanded(child: Divider(thickness: 1, color: Color(0xFFE8E8E8))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ✅ FIXED: Use Flexible to prevent overflow
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _signInWithGoogle, 
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFDADCE0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.g_mobiledata, color: Color(0xFF4285F4), size: 24),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Continue with Google',
                                  style: const TextStyle(
                                    color: Color(0xFF3C4043), 
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Have an account? '), TextButton(onPressed: () => Navigator.pop(context), child: const Text('Log In'))])
                    ]
                  )
                )
              )
            )
          )
        )
      ),
    );
  }
}