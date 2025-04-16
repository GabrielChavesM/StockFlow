import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stockflow/data/account_settings_data.dart';

// Domain Layer
class UserService {
  final UserRepository _userRepository;

  UserService(this._userRepository);

  User? get currentUser => _userRepository.currentUser;

  Future<DocumentSnapshot> getUserData() {
    return _userRepository.getUserData(currentUser!.uid);
  }

  Future<void> saveUserData(String name, String storeNumber) {
    return _userRepository.saveUserData(currentUser!.uid, name, storeNumber, currentUser!.email!);
  }

  Future<void> sendPasswordResetEmail() {
    return _userRepository.sendPasswordResetEmail(currentUser!.email!);
  }

  Future<void> deleteUser() {
    return _userRepository.deleteUser(currentUser!.uid);
  }

  Future<void> reauthenticateWithGoogle() {
    return _userRepository.reauthenticateWithGoogle();
  }

  Future<void> reauthenticateWithEmail(String email, String password) {
    return _userRepository.reauthenticateWithEmail(email, password);
  }

  Future<void> signOut() {
    return _userRepository.signOut();
  }
}