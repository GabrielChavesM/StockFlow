import 'package:cloud_firestore/cloud_firestore.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getUserDocument(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  Stream<QuerySnapshot> getProductsStream() {
    return _firestore.collection('products').snapshots();
  }

  Future<void> updateProductStock(String documentId, Map<String, dynamic> data) {
    return _firestore.collection('products').doc(documentId).update(data);
  }
}