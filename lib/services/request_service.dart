import 'package:flutter/foundation.dart';
import '../models/document_request.dart';

class RequestService extends ChangeNotifier {
  RequestService._();

  static final instance = RequestService._();

  final List<DocumentRequest> _requests = [
    DocumentRequest(
      requestNo: 'REQ-003',
      documentType: 'Barangay Clearance',
      purpose: 'Employment',
      pickupDate: DateTime.now().add(const Duration(days: 3)),
      createdAt: DateTime.now(),
    ),
    DocumentRequest(
      requestNo: 'REQ-002',
      documentType: 'Certificate of Residency',
      purpose: 'School enrollment',
      pickupDate: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Ready for Pickup',
    ),
    DocumentRequest(
      requestNo: 'REQ-001',
      documentType: 'Business Clearance',
      purpose: 'Store permit',
      pickupDate: DateTime.now().subtract(const Duration(days: 8)),
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      status: 'Rejected',
      remarks:
          'Business permit photo is blurry. Please upload a clearer copy.',
    ),
  ];

  List<DocumentRequest> get requests => List.unmodifiable(_requests);

  DocumentRequest? get latest =>
      _requests.isEmpty ? null : _requests.first;

  Future<DocumentRequest> submit({
    required String type,
    required String purpose,
    required DateTime pickupDate,
  }) async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // fake; Supabase later

    final req = DocumentRequest(
      requestNo:
          'REQ-${(_requests.length + 1).toString().padLeft(3, '0')}',
      documentType: type,
      purpose: purpose,
      pickupDate: pickupDate,
      createdAt: DateTime.now(),
    );

    _requests.insert(0, req);
    notifyListeners();

    return req;
  }
}