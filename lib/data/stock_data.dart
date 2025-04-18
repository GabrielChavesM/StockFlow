import 'package:cloud_firestore/cloud_firestore.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getUserDocument(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  Stream<QuerySnapshot> getProductsStream({
    required String storeNumber,
    String? name,
    String? brand,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) {
    Query query = _firestore.collection('products');

    // Filtros aplicados direto no servidor:
    query = query.where('storeNumber', isEqualTo: storeNumber);

    if (minPrice != null) {
      query = query.where('salePrice', isGreaterThanOrEqualTo: minPrice);
    }

    if (maxPrice != null && maxPrice < double.infinity) {
      query = query.where('salePrice', isLessThanOrEqualTo: maxPrice);
    }

    // LIMIT opcional para performance:
    query = query.limit(5);

    return query.snapshots();
  }

  Future<void> updateProductStock(String documentId, Map<String, dynamic> data) {
    return _firestore.collection('products').doc(documentId).update(data);
  }
}