import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Data Layer
class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<DocumentSnapshot> getUserData(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  Future<void> saveUserData(String userId, String name, String storeNumber, String email) {
    return _firestore.collection('users').doc(userId).set(
      {
        'name': name,
        'storeNumber': storeNumber,
        'userId': userId,
        'userEmail': email,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteUser(String userId) {
    return _firestore.collection('users').doc(userId).delete();
  }

  Future<void> reauthenticateWithGoogle() async {
    GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    }
  }

  Future<void> reauthenticateWithEmail(String email, String password) {
    AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
    return _auth.currentUser!.reauthenticateWithCredential(credential);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}