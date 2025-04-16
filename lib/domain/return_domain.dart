import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/return_data.dart';

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

  Future<void> updateProductStock(String documentId, Map<String, dynamic> data) {
    return _productRepository.updateProductStock(documentId, data);
  }

  Future<void> addBreakageRecord(Map<String, dynamic> data) {
    return _productRepository.addBreakageRecord(data);
  }
}