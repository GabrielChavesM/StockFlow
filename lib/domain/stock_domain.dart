import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockflow/data/stock_data.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProductService(ProductRepository productRepository);

  Future<DocumentSnapshot> getUserDocument(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  Future<void> updateProductStock(String documentId, Map<String, dynamic> data) {
    return _firestore.collection('products').doc(documentId).update(data);
  }

  Stream<QuerySnapshot<Object?>> getProductsStream({
    required String storeNumber,
    String? name,
    String? brand,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) {
    Query query = _firestore.collection('products').where('storeNumber', isEqualTo: storeNumber);

    if (name != null && name.isNotEmpty) {
      query = query.where('name', isGreaterThanOrEqualTo: name).where('name', isLessThanOrEqualTo: '$name\uf8ff');
    }

    if (brand != null && brand.isNotEmpty) {
      query = query.where('brand', isGreaterThanOrEqualTo: brand).where('brand', isLessThanOrEqualTo: '$brand\uf8ff');
    }

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isGreaterThanOrEqualTo: category).where('category', isLessThanOrEqualTo: '$category\uf8ff');
    }

    return query.snapshots();
  }
}
