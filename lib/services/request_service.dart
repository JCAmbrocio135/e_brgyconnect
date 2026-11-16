import 'dart:async';
import 'dart:convert';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/request_status.dart';
import '../models/document_request.dart';
import '../models/upload_file.dart';

class RequestService extends ChangeNotifier {
  RequestService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  static final instance = RequestService._();

  /// Largest allowed image, in bytes (before base64).
  static const maxImageBytes = 500 * 1024;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<DocumentRequest> _requests = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<DocumentRequest> get requests => List.unmodifiable(_requests);

  DocumentRequest? get latest => _requests.isEmpty ? null : _requests.first;

  // Detects the real image type from the first bytes of the file
  static String? _mimeOf(Uint8List b) {
    if (b.length < 12) return null;
    if (b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      return 'image/png';
    }
    if (b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  static bool isSupportedImage(Uint8List bytes) => _mimeOf(bytes) != null;

  void _onAuthChanged(User? user) {
    _sub?.cancel();
    _requests.clear();
    notifyListeners();

    if (user == null) return;

    _sub = _db
        .collection('requests')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      final items = snapshot.docs.map((doc) {
        final d = doc.data();
        final created = d['createdAt'];
        final pickup = d['pickupDate'];
        return DocumentRequest(
          requestNo: (d['requestNo'] as String?) ?? '',
          documentType: (d['documentType'] as String?) ?? '',
          purpose: (d['purpose'] as String?) ?? '',
          pickupDate: pickup is Timestamp ? pickup.toDate() : DateTime.now(),
          createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
          status: normalizeStatus(d['status']),
          remarks: d['remarks'] as String?,
        );
      }).toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _requests
        ..clear()
        ..addAll(items);
      notifyListeners();
    });
  }

  /// Saves the request and its uploaded images together (all or nothing).
  Future<DocumentRequest> submit({
    required String type,
    required String purpose,
    required DateTime pickupDate,
    required List<UploadFile> files,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    // Check every image before sending anything
    for (final f in files) {
      if (!isSupportedImage(f.bytes)) {
        throw Exception('${f.label}: please use a JPG or PNG photo.');
      }
      if (f.bytes.length > maxImageBytes) {
        throw Exception('${f.label}: the photo is too large. Choose a smaller one.');
      }
    }

    // Copy the resident's name and barangay onto the request for staff
    final profile =
        (await _db.collection('users').doc(user.uid).get()).data() ?? {};

    final requestNo =
        'REQ-${(_requests.length + 1).toString().padLeft(3, '0')}';
    final now = DateTime.now();

    final requestRef = _db.collection('requests').doc();
    final batch = _db.batch();

    batch.set(requestRef, {
      'uid': user.uid,
      'requestNo': requestNo,
      'documentType': type,
      'purpose': purpose,
      'pickupDate': Timestamp.fromDate(pickupDate),
      'createdAt': Timestamp.fromDate(now),
      'status': kStatusPending,
      'remarks': null,
      'residentName': (profile['name'] as String?) ?? '',
      'barangayCode': (profile['barangayCode'] as String?) ?? '',
      'attachmentKeys': files.map((f) => f.key).toList(),
    });

    for (final f in files) {
      batch.set(requestRef.collection('attachments').doc(f.key), {
        'uid': user.uid,
        'key': f.key,
        'label': f.label,
        'mime': _mimeOf(f.bytes),
        'size': f.bytes.length,
        'dataBase64': base64Encode(f.bytes),
        'uploadedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit().timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw Exception(
        'This is taking too long. Check your internet connection and try again.',
      ),
    );

    return DocumentRequest(
      requestNo: requestNo,
      documentType: type,
      purpose: purpose,
      pickupDate: pickupDate,
      createdAt: now,
      status: kStatusPending,
    );
  }

  /// Cancels a request, but only while it is still Pending.
  /// Runs as a transaction so it can't overwrite a staff status change.
  Future<void> cancel(String requestNo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    final found = await _db
        .collection('requests')
        .where('uid', isEqualTo: user.uid)
        .where('requestNo', isEqualTo: requestNo)
        .limit(1)
        .get();

    if (found.docs.isEmpty) {
      throw Exception('Request not found.');
    }

    final ref = found.docs.first.reference;

    await _db.runTransaction((tx) async {
      final fresh = await tx.get(ref);
      final status = normalizeStatus(fresh.data()?['status']);

      if (status != kStatusPending) {
        throw Exception(
          'This request is already being processed and cannot be cancelled.',
        );
      }

      tx.update(ref, {
        'status': kStatusCancelled,
        'remarks': 'Cancelled by resident.',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    });
  }
}