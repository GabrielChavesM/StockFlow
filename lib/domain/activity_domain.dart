import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockflow/data/activity_data.dart';

// Domain Layer
class ActivityService {
  final ActivityRepository _activityRepository;

  ActivityService(this._activityRepository);

  Future<DocumentSnapshot> getUserDocument(String userId) {
    return _activityRepository.getUserDocument(userId);
  }

  Future<QuerySnapshot> getUserActivity(String userId, DateTime startDate) {
    return _activityRepository.getUserActivity(userId, startDate);
  }

  Future<void> logUserActivity(String userId, String action) {
    return _activityRepository.logUserActivity(userId, action);
  }
}