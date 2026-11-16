
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
        'name': name.trim(),
        'email': email.trim(),
        'address': address.trim(),
        'birthdate': birthdate.trim(),
        'phone': phone.trim(),
        'phoneVerificationRequired': true,
        'phoneVerified': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),

        // Name parts
        'lastName': lastName.trim(),
        'firstName': firstName.trim(),
        'middleName': middleName.trim(),
        'extension': extension.trim(),

        // Address parts
        'province': province,
        'provinceCode': provinceCode,
        'city': city,
        'cityCode': cityCode,
        'barangay': barangay,
        'barangayCode': barangayCode,

        // Street parts
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data();

      // Only newly registered accounts require phone verification.
      if (data?['phoneVerificationRequired'] == true &&
          data?['phoneVerified'] != true) {
        await _auth.signOut();
        return 'Please verify your phone number before logging in.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    } on FirebaseException catch (_) {
      await _auth.signOut();
      return 'Could not check your account verification. Please try again.';
    } catch (_) {
      await _auth.signOut();
      return 'Login failed. Please try again.';
    }
  }

  /// Sends an SMS verification code to the phone number.
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function() onVerified,
    required void Function(String message) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          final error = await _linkPhoneCredential(
            credential,
            phoneNumber.trim(),
          );

          if (error == null) {
            onVerified();
          } else {
            onError(error);
          }
        },
       verificationFailed: (FirebaseAuthException e) {
  debugPrint('PHONE VERIFICATION FAILED');
  debugPrint('Code: ${e.code}');
  debugPrint('Message: ${e.message}');
  onError(_message(e.code));
},
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      onError(_message(e.code));
    } catch (_) {
      onError('Could not send verification code. Try again.');
    }
  }

  /// Verifies the six-digit code and links the phone to the current account.
  Future<String?> verifyAndLinkPhone({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      return await _linkPhoneCredential(
        credential,
        phoneNumber.trim(),
      );
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    } catch (_) {
      return 'Could not verify phone number. Try again.';
    }
  }

  /// Links the verified phone number to the existing email/password account.
  Future<String?> _linkPhoneCredential(
    PhoneAuthCredential credential,
    String phoneNumber,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return 'error: not logged in.';

    try {
      await user.linkWithCredential(credential);

      await _db.collection('users').doc(user.uid).update({
        'phone': phoneNumber,
        'phoneVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    } catch (_) {
      return 'Could not save verified phone number. Try again.';
    }
  }

  Future<void> logout() => _auth.signOut();
  Future<String?> deleteIncompleteAccount() async {
  final user = _auth.currentUser;
  if (user == null) return null;

  try {
    final userDoc = _db.collection('users').doc(user.uid);

    await userDoc.delete();
    await user.delete();

    return null;
  } on FirebaseAuthException catch (e) {
    return _message(e.code);
  } on FirebaseException catch (e) {
    return 'Could not delete incomplete profile: ${e.code}';
  } catch (_) {
    return 'Could not delete incomplete account. Please try again.';
  }
}
/// Deletes an incomplete account when registration is cancelled.
/// 

  /// Sends a password reset link.
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

  /// Saves phone and address changes.
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

  /// Starts an email change using Firebase's verification link.
  Future<String?> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    final user = _auth.currentUser;
    final current = user?.email;

    if (user == null || current == null) {
      return 'error: not logged in.';
    }

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

    try {
      await user.reload();
      user = _auth.currentUser;
    } catch (_) {}

    if (user == null) return {};

    final ref = _db.collection('users').doc(user.uid);
    final data = Map<String, dynamic>.from(
      (await ref.get()).data() ?? {},
    );

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
