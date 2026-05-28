import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reference to the 'products' collection
  CollectionReference get productsRef => _firestore.collection('products');

  // 1. Add a Product
  Future<void> addProduct(String name, double price, String description) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await productsRef.add({
      'name': name,
      'price': price,
      'description': description,
      'vendorId': user.uid, // Save who created it
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Get All Products (Stream for real-time updates)
  Stream<QuerySnapshot> getProducts() {
    return productsRef.orderBy('createdAt', descending: true).snapshots();
  }

  // 3. Delete a Product
  Future<void> deleteProduct(String docId) async {
    await productsRef.doc(docId).delete();
  }
}