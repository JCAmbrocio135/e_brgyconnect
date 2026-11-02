class DocumentType {
  final String name;
  final String fee;
  final String requirements;

  const DocumentType(
    this.name,
    this.fee,
    this.requirements,
  );

  static const all = [
    DocumentType(
      'Barangay Clearance',
      '₱50',
      'Valid ID, proof of residency',
    ),
    DocumentType(
      'Certificate of Indigency',
      'Free',
      'Valid ID, proof of residency',
    ),
    DocumentType(
      'Certificate of Residency',
      '₱30',
      'Valid ID',
    ),
    DocumentType(
      'Business Clearance',
      '₱200',
      'Valid ID, business permit/DTI',
    ),
    DocumentType(
      'Barangay ID',
      '₱100',
      'Valid ID, 1x1 photo',
    ),
    DocumentType(
      'Cedula',
      'Based on income (pay at hall)',
      'Valid ID',
    ),
    DocumentType(
      'Others',
      'Varies',
      'Specify in the purpose field',
    ),
  ];
}