enum PayMethod { gcash, maya, hall }

extension PayMethodX on PayMethod {
  String get label => switch (this) {
        PayMethod.gcash => 'GCash (Demo)',
        PayMethod.maya => 'Maya (Demo)',
        PayMethod.hall => 'Pay at Barangay Hall',
      };
}

class PaymentInfo {
  final String method;
  final String status; // Paid (Demo) / Unpaid / Not required
  final int amount;
  final String? reference;
  final DateTime? paidAt;

  const PaymentInfo({
    required this.method,
    required this.status,
    required this.amount,
    this.reference,
    this.paidAt,
  });

  factory PaymentInfo.notRequired() =>
      const PaymentInfo(method: 'None', status: 'Not required', amount: 0);

  factory PaymentInfo.payAtHall([int amount = 0]) => PaymentInfo(
        method: PayMethod.hall.label,
        status: 'Unpaid',
        amount: amount,
      );

  factory PaymentInfo.demoPaid({
    required PayMethod method,
    required int amount,
    required String reference,
  }) =>
      PaymentInfo(
        method: method.label,
        status: 'Paid (Demo)',
        amount: amount,
        reference: reference,
        paidAt: DateTime.now(),
      );
}