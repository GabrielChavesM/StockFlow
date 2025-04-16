import 'package:cloud_firestore/cloud_firestore.dart';

// Data Layer
class ActivityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getUserDocument(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  Future<QuerySnapshot> getUserActivity(String userId, DateTime startDate) {
    return _firestore
        .collection('user_activity')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('timestamp', descending: true)
        .get();
  }

  Future<void> logUserActivity(String userId, String action) {
    return _firestore.collection('user_activity').add({
      'userId': userId,
      'action': action,
      'timestamp': Timestamp.now(),
    });
  }
}