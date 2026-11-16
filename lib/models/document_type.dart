class Requirement {
  final String key; // saved in Firestore, don't rename later
  final String label;
  final String hint;

  const Requirement(this.key, this.label, this.hint);
}

class DocumentType {
  final String name;
  final String fee; // text shown to the resident
  final int? amount; // pesos; 0 = free; null = varies / pay at the hall
  final List<Requirement> requirements;

  const DocumentType(this.name, this.fee, this.requirements, {this.amount});

  bool get isFree => amount == 0;
  bool get canPayOnline => amount != null && amount! > 0;

  String get requirementsText => requirements.map((r) => r.label).join(', ');

  // ---- Requirement types ----
  static const validId = Requirement(
    'validId',
    'Valid ID',
    'Government-issued ID (front side). Clear and readable.',
  );
  static const residency = Requirement(
    'residency',
    'Proof of Residency',
    'Utility bill, lease, or any document showing your address.',
  );
  static const businessPermit = Requirement(
    'businessPermit',
    'Business Permit / DTI',
    'Business permit or DTI registration. Clear and readable.',
  );
  static const photo1x1 = Requirement(
    'photo1x1',
    '1x1 Photo',
    'Recent photo, plain background, face clearly visible.',
  );

  // ---- Documents (fees are samples; each barangay sets its own) ----
  static const all = [
    DocumentType('Barangay Clearance', '₱50', [validId, residency],
        amount: 50),
    DocumentType('Certificate of Indigency', 'Free', [validId, residency],
        amount: 0),
    DocumentType('Certificate of Residency', '₱30', [validId], amount: 30),
    DocumentType('Business Clearance', '₱200', [validId, businessPermit],
        amount: 200),
    DocumentType('Barangay ID', '₱100', [validId, photo1x1], amount: 100),
    DocumentType('Cedula', 'Based on income (pay at hall)', [validId]),
    DocumentType('Others', 'Varies', [validId]),
  ];
}