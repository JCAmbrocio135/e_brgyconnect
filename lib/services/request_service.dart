import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
          status: (d['status'] as String?) ?? 'Pending',
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
      'status': 'Pending',
      'remarks': null,
    });

    return DocumentRequest(
      requestNo: requestNo,
      documentType: type,
      purpose: purpose,
      pickupDate: pickupDate,
      createdAt: now,
      status: 'Pending',
    );
  }
}