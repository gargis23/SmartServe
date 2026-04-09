import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error sending reset email: $e");
      rethrow; // Pass error to UI to show a SnackBar
    }
  }

  // Register
  Future<UserCredential?> registerUser(String email, String password, String name, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Create a new document for the user in Firestore
        await _db.collection('users').doc(user.uid).set(
          UserModel(uid: user.uid, email: email, name: name, role: role).toMap()
        );
      }
      return result;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Login
  Future<UserCredential?> loginUser(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
     }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}