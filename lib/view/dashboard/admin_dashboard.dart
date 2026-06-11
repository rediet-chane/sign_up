import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controller/auth_controller.dart';
import '../../controller/user_service.dart';
import '../auth/signin_screen.dart';
import '../profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final UserService _userService = UserService();

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthController.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showManageUserDialog(String userId, String currentRole, String currentStatus, String userName) {
    String selectedRole = currentRole.isNotEmpty ? currentRole : 'customer';
    String selectedStatus = currentStatus.isNotEmpty ? currentStatus : 'pending';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Manage: $userName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Role:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedRole = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Approval Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending Approval')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedStatus = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {'role': selectedRole, 'status': selectedStatus}),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result != null && result is Map) {
        await _userService.updateUserRoleAndStatus(
          userId, 
          result['role'] as String, 
          result['status'] as String
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User updated to ${result['role']} (${result['status']})'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  Color _roleColor(String role) {
    if (role == 'admin') return Colors.red;
    if (role == 'vendor') return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              if (mounted) {
                setState(() {});
              }
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _userService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data?.docs ?? [];

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(
                      'Total Users: ${users.length}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    final firstName = data['firstName'] ?? 'No Name';
                    final lastName = data['lastName'] ?? '';
                    final email = data['email'] ?? '';
                    final role = data['role'] ?? 'customer';
                    final status = data['status'] ?? 'pending';
                    final profilePicture = data['profilePicture'] as String?;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _roleColor(role),
                          backgroundImage: (profilePicture != null && profilePicture.isNotEmpty)
                              ? MemoryImage(base64Decode(profilePicture))
                              : null,
                          child: (profilePicture == null || profilePicture.isEmpty)
                              ? Text(firstName[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                              : null,
                        ),
                        title: Text('$firstName $lastName'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            Text(
                              'Role: $role | Status: $status',
                              style: TextStyle(
                                color: status == 'pending' ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.edit, color: Colors.grey),
                        onTap: () => _showManageUserDialog(userId, role, status, '$firstName $lastName'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}