import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';
import '../widgets/address_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class EditInfoScreen extends StatefulWidget {
  const EditInfoScreen({super.key});

  @override
  State<EditInfoScreen> createState() => _EditInfoScreenState();
}

class _EditInfoScreenState extends State<EditInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Locked (display only)
  final _nameCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();

  // Editable
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _purokCtrl = TextEditingController();

  // Address cascade
  final _api = AddressService.instance;
  List<AddressItem> _places = [], _cities = [], _barangays = [];
  AddressItem? _place, _city, _barangay;
  bool _loadingAddr = false;
  String? _addrError;

  String _oldEmail = '';
  String _oldBarangayCode = '';
  bool _ready = false;
  bool _saving = false;
  bool _legacy = false; // account made before the new address fields

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _birthCtrl,
      _phoneCtrl,
      _emailCtrl,
      _houseCtrl,
      _streetCtrl,
      _purokCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    final p = await AuthService.instance.getProfile();
    String s(String k) => (p[k] as String?) ?? '';

    _nameCtrl.text = s('name');
    _birthCtrl.text = s('birthdate');
    _phoneCtrl.text = s('phone');
    _emailCtrl.text = s('email');
    _houseCtrl.text = s('houseNo');
    _streetCtrl.text = s('street');
    _purokCtrl.text = s('purok');
    _oldEmail = s('email');
    _oldBarangayCode = s('barangayCode');
    _legacy = s('barangayCode').isEmpty;

    if (!mounted) return;
    setState(() => _ready = true);

    await _restoreAddress(p);
  }

  AddressItem? _byCode(List<AddressItem> list, String code) {
    for (final i in list) {
      if (i.code == code) return i;
    }
    return null;
  }

  // Re-selects the saved province, city and barangay (if the account has them)
  Future<void> _restoreAddress(Map<String, dynamic> p) async {
    await _load(() async {
      _places = await _api.provincesAndNcr();

      final pc = (p['provinceCode'] as String?) ?? '';
      final cc = (p['cityCode'] as String?) ?? '';
      final bc = (p['barangayCode'] as String?) ?? '';
      if (pc.isEmpty) return;

      _place = _byCode(_places, pc);
      if (_place == null) return;
      _cities = await _api.cities(_place!);

      _city = _byCode(_cities, cc);
      if (_city == null) return;
      _barangays = await _api.barangays(_city!);

      _barangay = _byCode(_barangays, bc);
    });
  }

  Future<void> _load(Future<void> Function() task) async {
    setState(() {
      _loadingAddr = true;
      _addrError = null;
    });
    try {
      await task();
    } catch (_) {
      _addrError = 'Could not load addresses. Check your internet.';
    }
    if (mounted) setState(() => _loadingAddr = false);
  }

  void _onPlace(AddressItem? v) {
    setState(() {
      _place = v;
      _city = _barangay = null;
      _cities = _barangays = [];
    });
    if (v != null) _load(() async => _cities = await _api.cities(v));
  }

  void _onCity(AddressItem? v) {
    setState(() {
      _city = v;
      _barangay = null;
      _barangays = [];
    });
    if (v != null) _load(() async => _barangays = await _api.barangays(v));
  }

  String _fullAddress() {
    return '${_houseCtrl.text.trim()} ${_streetCtrl.text.trim()}, '
        'Purok ${_purokCtrl.text.trim()}, '
        'Brgy. ${_barangay!.name}, ${_city!.name}, ${_place!.name}';
  }

  Future<String?> _askPassword() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm your password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'For your security, enter your current password to change your email.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return (result == null || result.isEmpty) ? null : result;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final emailChanged =
        _emailCtrl.text.trim().toLowerCase() != _oldEmail.toLowerCase();
    final moving =
        _oldBarangayCode.isNotEmpty && _oldBarangayCode != _barangay!.code;

    if (moving) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Change barangay?'),
          content: const Text(
            'Staff will need to verify your new address again before you can request documents.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    String? password;
    if (emailChanged) {
      password = await _askPassword();
      if (password == null) return;
    }

    setState(() => _saving = true);

    final error = await AuthService.instance.updateInfo(
      phone: _phoneCtrl.text,
      address: _fullAddress(),
      houseNo: _houseCtrl.text,
      street: _streetCtrl.text,
      purok: _purokCtrl.text,
      province: _place!.name,
      provinceCode: _place!.code,
      city: _city!.name,
      cityCode: _city!.code,
      barangay: _barangay!.name,
      barangayCode: _barangay!.code,
    );

    if (error != null) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    var message = 'Info updated.';
    if (emailChanged) {
      final emailError = await AuthService.instance.changeEmail(
        newEmail: _emailCtrl.text,
        password: password!,
      );
      message = emailError != null
          ? 'Info saved, but your email was not changed: $emailError'
          : 'Info saved. We sent a link to your new email. Tap it to finish changing your email.';
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.pop(context, true);
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Info'),
        backgroundColor: Colors.white,
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_legacy)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Your account was created before we added the new address fields. Please choose your address below and save.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A6500),
                                ),
                              ),
                            ),

                          _heading('Locked Information'),
                          CustomTextField(
                            label: 'Full Name',
                            icon: Icons.lock_outline,
                            controller: _nameCtrl,
                            readOnly: true,
                          ),
                          gap,
                          CustomTextField(
                            label: 'Birthdate',
                            icon: Icons.lock_outline,
                            controller: _birthCtrl,
                            readOnly: true,
                          ),
                          const SizedBox(height: 6),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Name and birthdate are verified records. To correct them, please visit the barangay hall.',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),

                          const SizedBox(height: 10),
                          _heading('Contact'),
                          CustomTextField(
                            label: 'Contact Number',
                            icon: Icons.phone_outlined,
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                          ),
                          gap,
                          CustomTextField(
                            label: 'Email',
                            icon: Icons.email_outlined,
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.email,
                          ),

                          const SizedBox(height: 10),
                          _heading('Address'),
                          AddressDropdown(
                            label: 'Province / Metro Manila',
                            icon: Icons.map_outlined,
                            items: _places,
                            value: _place,
                            loading: _loadingAddr && _places.isEmpty,
                            onChanged: _onPlace,
                          ),
                          gap,
                          AddressDropdown(
                            label: 'City / Municipality',
                            icon: Icons.location_city,
                            items: _cities,
                            value: _city,
                            loading: _loadingAddr &&
                                _place != null &&
                                _cities.isEmpty,
                            onChanged: _onCity,
                          ),
                          gap,
                          AddressDropdown(
                            label: 'Barangay',
                            icon: Icons.holiday_village_outlined,
                            items: _barangays,
                            value: _barangay,
                            loading: _loadingAddr &&
                                _city != null &&
                                _barangays.isEmpty,
                            onChanged: (v) => setState(() => _barangay = v),
                          ),
                          if (_addrError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _addrError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB42318),
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),
                          _heading('Street Details'),
                          CustomTextField(
                            label: 'House No.',
                            icon: Icons.house_outlined,
                            controller: _houseCtrl,
                            validator: (v) =>
                                Validators.required(v, 'House No.'),
                          ),
                          gap,
                          CustomTextField(
                            label: 'Street',
                            icon: Icons.signpost_outlined,
                            controller: _streetCtrl,
                            validator: (v) => Validators.required(v, 'Street'),
                          ),
                          gap,
                          CustomTextField(
                            label: 'Purok / Zone (e.g. 3)',
                            icon: Icons.pin_drop_outlined,
                            controller: _purokCtrl,
                            validator: (v) => Validators.required(v, 'Purok'),
                          ),

                          const SizedBox(height: 22),
                          PrimaryButton(
                            text: 'Save Changes',
                            isLoading: _saving,
                            onPressed: _save,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}