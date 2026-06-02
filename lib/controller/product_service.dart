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

  Future<String?> compressAndEncodeImage(XFile imageFile) async {
    try {
      Uint8List fileBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(fileBytes);
      if (originalImage == null) return null;

      img.Image resized = img.copyResize(originalImage, width: 400, interpolation: img.Interpolation.linear);
      Uint8List compressedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
      return base64Encode(compressedBytes);
    } catch (e) {
      return null;
    }
  }

  Future<void> addProduct({
    required String name,
    required double price,
    required String description,
    String? imageData,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await productsRef.add({
      'name': name,
      'price': price,
      'description': description,
      'imageData': imageData ?? '',
      'vendorId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ FIX: ALL parameters are explicitly named to prevent any linter confusion
  Future<void> updateProduct({
    required String docId,
    required String name,
    required double price,
    required String description,
    required String imageData,
  }) async {
    await productsRef.doc(docId).update({
      'name': name,
      'price': price,
      'description': description,
      'imageData': imageData,
    });
  }

  Stream<QuerySnapshot> getVendorProducts(String vendorId) {
    return productsRef.where('vendorId', isEqualTo: vendorId).orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getAllProducts() {
    return productsRef.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> deleteProduct(String docId) async {
    await productsRef.doc(docId).delete();
  }
}