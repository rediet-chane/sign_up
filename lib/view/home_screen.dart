import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controller/auth_controller.dart';
import '../../controller/user_service.dart';
import 'auth/signin_screen.dart';
import '../view/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  String _displayName = 'User';
  bool _loadingName = true;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // ✅ Separate variable to avoid constant rebuilds

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final profile = await _userService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _displayName = profile?['firstName'] ?? 'User';
        _loadingName = false;
      });
    }
  }

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

  Widget _buildProductImage(String? imageData, {double height = 140}) {
    final bool isBase64 = imageData != null && imageData.isNotEmpty && !imageData.startsWith('http');
    
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: imageData != null && imageData.isNotEmpty
          ? (isBase64
              ? Image.memory(base64Decode(imageData), fit: BoxFit.contain)
              : Image.network(
                  imageData,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                ))
          : const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()),
             );
          }
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout),
          ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      _loadingName
                          ? const SizedBox(width: 100, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // ✅ OPTIMIZED SEARCH: Only updates _searchQuery, not entire widget tree
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              // ✅ Only update the search query variable, not rebuild everything
              onSubmitted: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allProducts = snapshot.data?.docs ?? [];
                
                // ✅ Filter using the stored _searchQuery
                final filteredProducts = allProducts.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final description = (data['description'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || description.contains(_searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          allProducts.isEmpty ? 'No products yet' : 'No products found for "$_searchQuery"',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final data = filteredProducts[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'No Name';
                    final price = data['price'] ?? 0;
                    final description = data['description'] ?? '';
                    final imageData = data['imageData'] as String?;
                    
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: _buildProductImage(imageData, height: 140),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name, 
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '\$${price.toStringAsFixed(2)}', 
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}