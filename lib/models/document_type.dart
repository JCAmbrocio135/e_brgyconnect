class Requirement {
  final String key; // saved in Firestore, don't rename later
  final String label;
  final String hint;

  const Requirement(this.key, this.label, this.hint);
}

class DocumentType {
  final String name;
  final String fee;
  final List<Requirement> requirements;

  const DocumentType(this.name, this.fee, this.requirements);

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
    DocumentType('Barangay Clearance', '₱50', [validId, residency]),
    DocumentType('Certificate of Indigency', 'Free', [validId, residency]),
    DocumentType('Certificate of Residency', '₱30', [validId]),
    DocumentType('Business Clearance', '₱200', [validId, businessPermit]),
    DocumentType('Barangay ID', '₱100', [validId, photo1x1]),
    DocumentType('Cedula', 'Based on income (pay at hall)', [validId]),
    DocumentType('Others', 'Varies', [validId]),
  ];
}