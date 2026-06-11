import 'dart:convert';
import 'package:flutter/material.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  Widget build(BuildContext context) {
    final name = productData['name'] ?? 'No Name';
    final price = productData['price'] ?? 0;
    final description = productData['description'] ?? '';
    final imageData = productData['imageData'] as String?;
    final bool isBase64 = imageData != null && imageData.isNotEmpty && !imageData.startsWith('http');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            flexibleSpace: FlexibleSpaceBar(
              background: imageData != null && imageData.isNotEmpty
                  ? (isBase64
                      ? Image.memory(base64Decode(imageData), fit: BoxFit.cover)
                      : Image.network(
                          imageData, 
                          fit: BoxFit.cover, 
                          errorBuilder: (c,e,s) => Container(color: Colors.grey, child: const Center(child: Icon(Icons.broken_image, size: 50)))
                        ))
                  : Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    description.isEmpty ? 'No description provided.' : description, 
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart! (Coming in next step)'), backgroundColor: Colors.green),
                );
              },
              icon: const Icon(Icons.shopping_cart, size: 24),
              label: const Text('Add to Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}