import '../models/user_profile.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  UserProfile? currentUser;

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // fake; Supabase later
    currentUser = UserProfile(
      fullName: 'Juan Dela Cruz',
      email: email,
      contactNo: '09123456789',
      address: 'Purok 3, Brgy. San Isidro',
      birthdate: 'Jan 11, 2000',
    );
  }

  void logout() => currentUser = null;
}