import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/user_avatar.dart';
import 'about_screen.dart';
import 'edit_info_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _future;
  bool _busyPhoto = false;

  @override
  void initState() {
    super.initState();
    _future = AuthService.instance.getProfile();
  }

  void _reload() {
    setState(() {
      _future = AuthService.instance.getProfile();
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (picked == null) return; // user cancelled

      final bytes = await picked.readAsBytes();

      setState(() => _busyPhoto = true);
      final error = await AuthService.instance.savePhoto(bytes);
      if (!mounted) return;
      setState(() => _busyPhoto = false);

      if (error != null) {
        _toast(error);
        return;
      }
      _toast('Photo updated.');
      _reload();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyPhoto = false);
      _toast('Could not open the photo picker.');
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _busyPhoto = true);
    final error = await AuthService.instance.removePhoto();
    if (!mounted) return;
    setState(() => _busyPhoto = false);

    if (error != null) {
      _toast(error);
      return;
    }
    _toast('Photo removed.');
    _reload();
  }

  void _photoOptions(bool hasPhoto) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Color(0xFFB42318)),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: Color(0xFFB42318)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditInfoScreen()),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: Color(0xFFB42318)),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await AuthService.instance.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      subtitle: Text(
        value.isEmpty ? '—' : value,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? {};
            final name = (data['name'] as String?) ?? '';
            final email = (data['email'] as String?) ?? '';
            final phone = (data['phone'] as String?) ?? '';
            final address = (data['address'] as String?) ?? '';
            final birthdate = (data['birthdate'] as String?) ?? '';
            final photo = (data['photoBase64'] as String?) ?? '';
            final isVerified = data['status'] == 'verified';

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          UserAvatar(
                            photoBase64: photo,
                            name: name,
                            radius: 44,
                          ),
                          if (_busyPhoto)
                            const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        avatar: Icon(
                          isVerified ? Icons.verified : Icons.hourglass_top,
                          size: 16,
                          color: isVerified ? AppColors.green : Colors.orange,
                        ),
                        label: Text(
                          isVerified
                              ? 'Verified Resident'
                              : 'Awaiting Verification',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _busyPhoto
                            ? null
                            : () => _photoOptions(photo.isNotEmpty),
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: Text(
                          photo.isEmpty ? 'Upload Photo' : 'Change Photo',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            _infoTile(Icons.email_outlined, 'Email', email),
                            _infoTile(
                                Icons.phone_outlined, 'Contact Number', phone),
                            _infoTile(Icons.home_outlined, 'Address', address),
                            _infoTile(
                                Icons.cake_outlined, 'Birthdate', birthdate),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _openEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Info'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('About & Support'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _confirmLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Log Out'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: const Color(0xFFB42318),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}