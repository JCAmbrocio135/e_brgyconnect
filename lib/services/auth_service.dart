import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String address = '',
    String birthdate = '',
    String phone = '',
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'address': address.trim(),
        'birthdate': birthdate.trim(),
        'phone': phone.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    }
  }

  Future<void> logout() => _auth.signOut();

  User? get currentUser => _auth.currentUser;

  Future<String> getCurrentName() async {
    final user = _auth.currentUser;
    if (user == null) return '';
    final doc = await _db.collection('users').doc(user.uid).get();
    return (doc.data()?['name'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data() ?? {};
  }

  String _message(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'email already used.';
      case 'weak-password':
        return 'weak password (min. 6 characters).';
      case 'invalid-email':
        return 'email not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'wrong email or password.';
      default:
        return 'error: $code';
    }
  }
}