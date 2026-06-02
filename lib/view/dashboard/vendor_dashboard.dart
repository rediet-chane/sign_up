import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/auth_controller.dart';
import '../../controller/product_service.dart';
import '../auth/signin_screen.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  final ProductService _productService = ProductService();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  
  bool _isUploading = false;
  int _imageSourceTab = 0; 

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
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const SignInScreen()), (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog({Map<String, dynamic>? existingProduct, String? docId}) {
    final bool isEdit = existingProduct != null;
    
    // ✅ LOCAL variables for the dialog's internal state
    XFile? selectedImage;
    Uint8List? previewBytes;
    
    _nameController.text = isEdit ? existingProduct!['name'] : '';
    _priceController.text = isEdit ? existingProduct!['price'].toString() : '';
    _descController.text = isEdit ? existingProduct!['description'] : '';
    
    String currentImageData = isEdit ? (existingProduct!['imageData'] ?? '') : '';
    _urlController.text = currentImageData.startsWith('http') ? currentImageData : '';
    _imageSourceTab = currentImageData.startsWith('http') ? 1 : 0;
    _isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ToggleButtons(
                  isSelected: [_imageSourceTab == 0, _imageSourceTab == 1],
                  onPressed: (index) {
                    setDialogState(() {
                      _imageSourceTab = index;
                      if (index == 0) { 
                        selectedImage = null; 
                        previewBytes = null; 
                      } else { 
                        _urlController.clear(); 
                      }
                    });
                  },
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Upload File')), 
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Image URL'))
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_imageSourceTab == 0) ...[
                  GestureDetector(
                    // ✅ FIX: Handle picking INSIDE the StatefulBuilder so dialog updates instantly
                    onTap: _isUploading ? null : () async {
                      final XFile? image = await _productService.picker.pickImage(
                        source: ImageSource.gallery, 
                        imageQuality: 70,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setDialogState(() {
                          selectedImage = image;
                          previewBytes = bytes;
                          _urlController.clear();
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: previewBytes == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tap to add image')
                              ],
                            )
                          : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    previewBytes!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                                    onPressed: () {
                                      setDialogState(() {
                                        selectedImage = null;
                                        previewBytes = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(labelText: 'Paste Image URL', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link)),
                    onChanged: (val) => setDialogState(() {}), // ✅ Update preview as URL is typed
                  ),
                  if (_urlController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: Image.network(
                            _urlController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 150,
                              color: Colors.grey.shade200,
                              child: const Center(child: Text('Invalid URL')),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _isUploading ? null : () async {
                if (_nameController.text.isEmpty) return;
                setDialogState(() => _isUploading = true);

                String finalImageData = _urlController.text;
                if (_imageSourceTab == 0 && selectedImage != null) {
                  finalImageData = await _productService.compressAndEncodeImage(selectedImage!) ?? '';
                }

                if (isEdit && docId != null) {
                  await _productService.updateProduct(
                    docId: docId,
                    name: _nameController.text,
                    price: double.tryParse(_priceController.text) ?? 0.0,
                    description: _descController.text,
                    imageData: finalImageData,
                  );
                } else {
                  await _productService.addProduct(
                    name: _nameController.text,
                    price: double.tryParse(_priceController.text) ?? 0.0,
                    description: _descController.text,
                    imageData: finalImageData,
                  );
                }

                if (!mounted) return;
                Navigator.pop(context); 
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEdit ? 'Product updated!' : 'Product added!'), backgroundColor: Colors.green),
                );
              },
              child: _isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : Text(isEdit ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _productService.deleteProduct(docId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? vendorId = AuthController.getCurrentUser()?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'), 
        backgroundColor: Colors.orange, 
        automaticallyImplyLeading: false, 
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout)]
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                const Text('My Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(onPressed: () => _showProductDialog(), icon: const Icon(Icons.add), label: const Text('Add Product')),
              ]
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: vendorId != null ? _productService.getVendorProducts(vendorId) : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final products = snapshot.data?.docs ?? [];
                if (products.isEmpty) return const Center(child: Text('No products yet. Add one!'));

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final data = product.data() as Map<String, dynamic>;
                    final imageData = data['imageData'] as String?;
                    final bool isBase64 = imageData != null && !imageData.startsWith('http');

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageData != null && imageData.isNotEmpty
                              ? (isBase64 
                                  ? Image.memory(base64Decode(imageData), width: 60, height: 60, fit: BoxFit.cover) 
                                  : Image.network(imageData, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 60)))
                              : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                        ),
                        title: Text(data['name'] ?? 'No Name'),
                        subtitle: Text('\$${data['price']} - ${data['description']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductDialog(existingProduct: data, docId: product.id)), 
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(product.id)),
                          ],
                        ),
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