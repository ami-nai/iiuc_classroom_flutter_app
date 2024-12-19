import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> login(String email, String password) async {
  final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  if (userCredential.user != null && userCredential.user!.emailVerified) {
    return userCredential.user;
  } else {
    throw Exception('Please verify your email before logging in.');
  }
}


Future<void> logout() async {
  await _auth.signOut();
}


Future<bool> verifyRole(String email) async{
  final doc = await _firestore.collection('users').doc(email).get();
  return doc.exists;
}

Future<void> register(String email, String password, String role) async {
  final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
    );
    await _firestore.collection('users').doc(email).set({
      'email': email,
      'role': role,
    });
  }

Future<bool> checkIfLogedIn(User? user) async{
  if(user != null) return Future<bool>.value(true);
  else return Future<bool>.value(false);
}

}