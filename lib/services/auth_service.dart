import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';

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
    String lastName = '',
    String firstName = '',
    String middleName = '',
    String extension = '',
    String province = '',
    String provinceCode = '',
    String city = '',
    String cityCode = '',
    String barangay = '',
    String barangayCode = '',
    String houseNo = '',
    String street = '',
    String purok = '',
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        // existing fields (unchanged)
        'name': name.trim(), // full name, for display
        'email': email.trim(),
        'address': address.trim(), // full address line, for display
        'birthdate': birthdate.trim(),
        'phone': phone.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),

        // name parts
        'lastName': lastName.trim(),
        'firstName': firstName.trim(),
        'middleName': middleName.trim(),
        'extension': extension.trim(),

        // address parts (codes let the web dashboard filter by barangay)
        'province': province,
        'provinceCode': provinceCode,
        'city': city,
        'cityCode': cityCode,
        'barangay': barangay,
        'barangayCode': barangayCode,

        // street parts
        'houseNo': houseNo.trim(),
        'street': street.trim(),
        'purok': purok.trim(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    } catch (_) {
      return 'error: could not save your profile. Try again.';
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

  /// Sends a password reset link. Returns an error message, or null on success.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    } catch (_) {
      return 'error: could not send the email. Try again.';
    }
  }

  /// Saves phone and address changes. Returns an error message, or null on success.
  Future<String?> updateInfo({
    required String phone,
    required String address,
    required String houseNo,
    required String street,
    required String purok,
    required String province,
    required String provinceCode,
    required String city,
    required String cityCode,
    required String barangay,
    required String barangayCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'error: not logged in.';

    try {
      final ref = _db.collection('users').doc(user.uid);
      final old = (await ref.get()).data() ?? {};
      final oldCode = (old['barangayCode'] as String?) ?? '';

      // Moving to a different barangay needs staff to verify again.
      // (Old accounts with no barangay yet are just completing their profile.)
      final moved = oldCode.isNotEmpty && oldCode != barangayCode;

      await ref.update({
        'phone': phone.trim(),
        'address': address.trim(),
        'houseNo': houseNo.trim(),
        'street': street.trim(),
        'purok': purok.trim(),
        'province': province,
        'provinceCode': provinceCode,
        'city': city,
        'cityCode': cityCode,
        'barangay': barangay,
        'barangayCode': barangayCode,
        'updatedAt': FieldValue.serverTimestamp(),
        if (moved) 'status': 'pending',
      });
      return null;
    } on FirebaseException catch (e) {
      return 'error: ${e.code}';
    } catch (_) {
      return 'error: could not save changes. Try again.';
    }
  }

  /// Starts an email change. Firebase emails a verification link to the NEW
  /// address, and the login email only changes after that link is tapped.
  Future<String?> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    final user = _auth.currentUser;
    final current = user?.email;
    if (user == null || current == null) return 'error: not logged in.';

    try {
      final cred =
          EmailAuthProvider.credential(email: current, password: password);
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(newEmail.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    } catch (_) {
      return 'error: could not change the email. Try again.';
    }
  }

  /// Saves a small, already-compressed photo inside the user's document.
  Future<String?> savePhoto(Uint8List bytes) async {
    final user = _auth.currentUser;
    if (user == null) return 'error: not logged in.';
    if (bytes.length > 300 * 1024) {
      return 'error: the photo is too large. Try a smaller one.';
    }

    try {
      await _db.collection('users').doc(user.uid).update({
        'photoBase64': base64Encode(bytes),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      return 'error: ${e.code}';
    } catch (_) {
      return 'error: could not save the photo. Try again.';
    }
  }

  /// Removes the display photo.
  Future<String?> removePhoto() async {
    final user = _auth.currentUser;
    if (user == null) return 'error: not logged in.';

    try {
      await _db.collection('users').doc(user.uid).update({
        'photoBase64': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      return 'error: ${e.code}';
    } catch (_) {
      return 'error: could not remove the photo. Try again.';
    }
  }

  User? get currentUser => _auth.currentUser;

  Future<String> getCurrentName() async {
    final user = _auth.currentUser;
    if (user == null) return '';
    final doc = await _db.collection('users').doc(user.uid).get();
    return (doc.data()?['name'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> getProfile() async {
    var user = _auth.currentUser;
    if (user == null) return {};

    // Refresh the login info (picks up a verified email change)
    try {
      await user.reload();
      user = _auth.currentUser;
    } catch (_) {}
    if (user == null) return {};

    final ref = _db.collection('users').doc(user.uid);
    final data = Map<String, dynamic>.from((await ref.get()).data() ?? {});

    final authEmail = user.email ?? '';
    if (authEmail.isNotEmpty && data['email'] != authEmail) {
      try {
        await ref.update({'email': authEmail});
        data['email'] = authEmail;
      } catch (_) {}
    }
    return data;
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
      case 'too-many-requests':
        return 'too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'no internet connection.';
      case 'requires-recent-login':
        return 'please log in again, then retry.';
      default:
        return 'error: $code';
    }
  }
}