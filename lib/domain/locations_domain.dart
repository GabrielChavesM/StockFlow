import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/locations_data.dart';

// Domain Layer
class ProductService {
  final ProductRepository _productRepository;

  ProductService(this._productRepository);

  Future<DocumentSnapshot> getUserDocument(String userId) {
    return _productRepository.getUserDocument(userId);
  }

  Stream<QuerySnapshot> getProductsStream() {
    return _productRepository.getProductsStream();
  }

  Future<void> updateProductLocation(String documentId, String location) async {
    if (documentId.isEmpty) {
      throw ArgumentError('Document ID cannot be empty.');
    }

    await FirebaseFirestore.instance
        .collection('products')
        .doc(documentId)
        .update({'productLocation': location});
  }
}