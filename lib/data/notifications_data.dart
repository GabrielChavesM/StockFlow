import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> fetchNotificationsStream(String storeNumber) {
    return _firestore
        .collection('notifications')
        .where('storeNumber', isEqualTo: storeNumber)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> deleteExpiredNotifications(List<DocumentSnapshot> docs) async {
    final batch = _firestore.batch();
    for (var doc in docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<DocumentSnapshot> getUserDocument(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }
}