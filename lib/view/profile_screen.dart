import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/user_service.dart';
import '../../controller/product_service.dart'; // Reusing our image compression!

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ProductService _productService = ProductService(); // For compression
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  
  String? _profilePictureBase64;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profile = await _userService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _firstNameController.text = profile?['firstName'] ?? '';
        _lastNameController.text = profile?['lastName'] ?? '';
        _storeNameController.text = profile?['storeName'] ?? '';
        _profilePictureBase64 = profile?['profilePicture']; // Load picture
        _isLoading = false;
      });
    }
  }

  // 1. PICK PROFILE PICTURE
  Future<void> _pickProfilePicture() async {
    final XFile? image = await _productService.picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _isPickingImage = true);
      // Compress to Base64 so it's free and fits in Firestore
      final compressed = await _productService.compressAndEncodeImage(image);
      if (mounted) {
        setState(() {
          _profilePictureBase64 = compressed;
          _isPickingImage = false;
        });
      }
    }
  }

  // 2. SAVE PROFILE & GO BACK
  Future<void> _saveProfile() async {
    if (_firstNameController.text.isEmpty || _storeNameController.text.isEmpty) {
      _showMessage('First name and store name cannot be empty', isError: true);
      return;
    } 
    
    setState(() => _isSaving = true);
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic> updateData = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'storeName': _storeNameController.text.trim(),
        };
        
        // Only update picture if a new one was picked
        if (_profilePictureBase64 != null) {
          updateData['profilePicture'] = _profilePictureBase64;
        }
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);
      
        if (mounted) {
          _showMessage('Profile updated successfully', isError: false);
          // ✅ AUTO-NAVIGATE BACK TO HOME/DASHBOARD
          Navigator.pop(context); 
        }
      }
    } catch (e) {
      if (mounted) {  
        _showMessage('Failed to update profile: $e', isError: true);
      } 
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // 3. SMART PASSWORD CHANGE
  void _changePassword() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password (min 6 chars)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newPassController.text.length < 6) {
                _showMessage('New password must be at least 6 characters', isError: true);
                return;
              }
              // ✅ CHECK IF PASSWORDS ARE THE SAME
              if (currentPassController.text == newPassController.text) {
                _showMessage('New password cannot be the same as the old password', isError: true);
                return;
              }
              
              Navigator.pop(ctx); // Close dialog
              
              try {
                final user = _auth.currentUser;
                if (user != null && user.email != null) {
                  // Re-authenticate user for security
                  final cred = EmailAuthProvider.credential(
                    email: user.email!, 
                    password: currentPassController.text
                  );
                  await user.reauthenticateWithCredential(cred);
                  
                  // Update to new password
                  await user.updatePassword(newPassController.text);
                  
                  if (mounted) {
                    _showMessage('Password changed successfully!', isError: false);
                  }
                }
              } catch (e) {
                if (mounted) {
                  _showMessage('Failed. Did you enter the correct current password?', isError: true);
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.blue),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4. PROFILE PICTURE WITH CAMERA BUTTON
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue,
                          // Show the Base64 image if it exists
                          backgroundImage: _profilePictureBase64 != null && _profilePictureBase64!.isNotEmpty
                              ? MemoryImage(base64Decode(_profilePictureBase64!))
                              : null,
                          // Show default icon if no image
                          child: _profilePictureBase64 == null || _profilePictureBase64!.isEmpty
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        if (_isPickingImage)
                          const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                        // Camera Icon Overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickProfilePicture,
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.camera_alt, size: 20, color: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Account Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField(_firstNameController, 'First Name', Icons.person_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_lastNameController, 'Last Name', Icons.person_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_storeNameController, 'Store Name', Icons.store_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(
                    TextEditingController(text: _auth.currentUser?.email ?? ''),
                    'Email',
                    Icons.email_outlined,
                    enabled: false,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Change Password'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ], 
              ), 
            ), 
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
      ),
    );
  }
}