class DocumentRequest {
  final String requestNo;
  final String documentType;
  final String purpose;
  final DateTime pickupDate;
  final DateTime createdAt;
  final String status; // Pending, Processing, Ready for Pickup, Released, Rejected, Cancelled
  final String? remarks;

  // Payment (demo)
  final int amount;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentRef;

  const DocumentRequest({
    required this.requestNo,
    required this.documentType,
    required this.purpose,
    required this.pickupDate,
    required this.createdAt,
    this.status = 'Pending',
    this.remarks,
    this.amount = 0,
    this.paymentMethod = 'None',
    this.paymentStatus = 'Not required',
    this.paymentRef,
  });
}