class UserProfile {
  final String fullName;
  final String email;
  final String contactNo;
  final String address;
  final String birthdate;
  final bool isVerified;

  const UserProfile({
    required this.fullName,
    required this.email,
    required this.contactNo,
    required this.address,
    required this.birthdate,
    this.isVerified = true,
  });
}