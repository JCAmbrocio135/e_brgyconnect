import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/request_status.dart';
import '../models/document_request.dart';

class RequestService extends ChangeNotifier {
  RequestService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  static final instance = RequestService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<DocumentRequest> _requests = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<DocumentRequest> get requests => List.unmodifiable(_requests);

  DocumentRequest? get latest => _requests.isEmpty ? null : _requests.first;

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

  Future<DocumentRequest> submit({
    required String type,
    required String purpose,
    required DateTime pickupDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    final requestNo =
        'REQ-${(_requests.length + 1).toString().padLeft(3, '0')}';
    final now = DateTime.now();

    await _db.collection('requests').add({
      'uid': user.uid,
      'requestNo': requestNo,
      'documentType': type,
      'purpose': purpose,
      'pickupDate': Timestamp.fromDate(pickupDate),
      'createdAt': Timestamp.fromDate(now),
      'status': kStatusPending,
      'remarks': null,
    });

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

    // Find this resident's request by its number
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
    // No notifyListeners() needed: the Firestore listener updates the lists.
  }
}