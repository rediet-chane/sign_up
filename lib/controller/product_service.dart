import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker picker = ImagePicker();

  CollectionReference get productsRef => _firestore.collection('products');

  // 1. Compress image and convert to Base64
  Future<String?> compressAndEncodeImage(XFile imageFile) async {
    try {
      Uint8List fileBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(fileBytes);
      if (originalImage == null) return null;

      img.Image resized = img.copyResize(
        originalImage,
        width: 400,
        interpolation: img.Interpolation.linear,
      );

      Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: 70),
      );

      return base64Encode(compressedBytes);
    } catch (e) {
      return null;
    }
  }

  // 2. Add a Product
  Future<void> addProduct({
    required String name,
    required double price,
    required String description,
    String? imageBase64,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await productsRef.add({
      'name': name,
      'price': price,
      'description': description,
      'imageBase64': imageBase64 ?? '',
      'vendorId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Get All Products
  Stream<QuerySnapshot> getProducts() {
    return productsRef.orderBy('createdAt', descending: true).snapshots();
  }

  // 4. Delete a Product
  Future<void> deleteProduct(String docId) async {
    await productsRef.doc(docId).delete();
  }
}