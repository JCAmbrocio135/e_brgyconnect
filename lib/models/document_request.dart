class DocumentRequest {
  final String requestNo;
  final String documentType;
  final String purpose;
  final DateTime pickupDate;
  final DateTime createdAt;
  final String status; // Pending, Processing, Ready for Pickup, Released, Rejected
  final String? remarks;

  const DocumentRequest({
    required this.requestNo,
    required this.documentType,
    required this.purpose,
    required this.pickupDate,
    required this.createdAt,
    this.status = 'Pending',
    this.remarks,
  });
}