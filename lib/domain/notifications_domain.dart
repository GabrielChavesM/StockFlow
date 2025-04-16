import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/notifications_data.dart';

class NotificationService {
  final NotificationRepository _notificationRepository;

  NotificationService(this._notificationRepository);

  bool isNotificationExpired(Timestamp timestamp) {
    final notificationTime = timestamp.toDate();
    final currentTime = DateTime.now();
    final difference = currentTime.difference(notificationTime);
    return difference.inDays >= 3;
  }

  Stream<List<Map<String, dynamic>>> fetchNotificationsStream(String storeNumber) {
    return _notificationRepository.fetchNotificationsStream(storeNumber).map((querySnapshot) {
      final notifications = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      final expiredDocs = querySnapshot.docs.where((doc) => isNotificationExpired(doc['timestamp'])).toList();
      _notificationRepository.deleteExpiredNotifications(expiredDocs);

      return notifications.where((n) => !isNotificationExpired(n['timestamp'])).toList();
    });
  }

  Future<String?> getUserStoreNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc = await _notificationRepository.getUserDocument(user.uid);
    final data = userDoc.data() as Map<String, dynamic>?;
    return data?['storeNumber'] as String?;
  }

  String getTimeAgo(DateTime notificationTime) {
    final currentTime = DateTime.now();
    final difference = currentTime.difference(notificationTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Less than a minute ago';
    }
  }
}