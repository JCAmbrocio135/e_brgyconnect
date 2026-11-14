import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';
import '../widgets/address_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Name parts
  final _lastCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _middleCtrl = TextEditingController();
  String _ext = 'None';
  static const _extensions = ['None', 'Jr.', 'Sr.', 'II', 'III', 'IV', 'V'];

  final _houseCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _purokCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  // Address cascade: Province/NCR -> City -> Barangay
  final _api = AddressService.instance;
  List<AddressItem> _places = [], _cities = [], _barangays = [];
  AddressItem? _place, _city, _barangay;
  bool _loadingAddr = false;
  String? _addrError;

  @override
  void initState() {
    super.initState();
    _load(() async => _places = await _api.provincesAndNcr());
  }

  @override
  void dispose() {
    for (final c in [
      _lastCtrl,
      _firstCtrl,
      _middleCtrl,
      _houseCtrl,
      _streetCtrl,
      _purokCtrl,
      _birthCtrl,
      _phoneCtrl,
      _emailCtrl,
      _passCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Runs an API call with loading and error handling
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

  Future<void> _pickBirthdate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _birthCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  // Combines the parts into one clean full name: First Middle Last Ext.
  String _fullName() {
    final parts = [
      _firstCtrl.text,
      _middleCtrl.text,
      _lastCtrl.text,
      _ext == 'None' ? '' : _ext,
    ]
        .map((s) => s.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((s) => s.isNotEmpty);
    return parts.join(' ');
  }

  // Combines all address parts into one line for the profile
  String _fullAddress() {
    return '${_houseCtrl.text.trim()} ${_streetCtrl.text.trim()}, '
        'Purok ${_purokCtrl.text.trim()}, '
        'Brgy. ${_barangay!.name}, ${_city!.name}, ${_place!.name}';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final error = await AuthService.instance.register(
      name: _fullName(),
      email: _emailCtrl.text,
      password: _passCtrl.text,
      address: _fullAddress(),
      birthdate: _birthCtrl.text,
      phone: _phoneCtrl.text,
      lastName: _lastCtrl.text,
      firstName: _firstCtrl.text,
      middleName: _middleCtrl.text,
      extension: _ext == 'None' ? '' : _ext,
      province: _place!.name,
      provinceCode: _place!.code,
      city: _city!.name,
      cityCode: _city!.code,
      barangay: _barangay!.name,
      barangayCode: _barangay!.code,
      houseNo: _houseCtrl.text,
      street: _streetCtrl.text,
      purok: _purokCtrl.text,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    await AuthService.instance.logout();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Registered! Please wait for staff verification.',
        ),
      ),
    );

    Navigator.pop(context);
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
        title: const Text('Create Account'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _heading('Personal Information'),
                    CustomTextField(
                      label: 'Last Name',
                      icon: Icons.person_outline,
                      controller: _lastCtrl,
                      validator: (v) => Validators.name(v, 'Last name'),
                    ),
                    gap,
                    CustomTextField(
                      label: 'First Name',
                      icon: Icons.person_outline,
                      controller: _firstCtrl,
                      validator: (v) => Validators.name(v, 'First name'),
                    ),
                    gap,
                    CustomTextField(
                      label: 'Middle Name (optional)',
                      icon: Icons.person_outline,
                      controller: _middleCtrl,
                      validator: Validators.optionalName,
                    ),
                    gap,
                    DropdownButtonFormField<String>(
                      initialValue: _ext,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Extension (Jr., Sr., III...)',
                        prefixIcon: const Icon(Icons.badge_outlined,
                            color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _extensions
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _ext = v ?? 'None'),
                    ),
                    gap,
                    CustomTextField(
                      label: 'Birthdate',
                      icon: Icons.cake_outlined,
                      controller: _birthCtrl,
                      readOnly: true,
                      onTap: _pickBirthdate,
                      validator: (v) => Validators.required(v, 'Birthdate'),
                    ),
                    gap,
                    CustomTextField(
                      label: 'Contact Number',
                      icon: Icons.phone_outlined,
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
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
                      loading:
                          _loadingAddr && _place != null && _cities.isEmpty,
                      onChanged: _onCity,
                    ),
                    gap,
                    AddressDropdown(
                      label: 'Barangay',
                      icon: Icons.holiday_village_outlined,
                      items: _barangays,
                      value: _barangay,
                      loading:
                          _loadingAddr && _city != null && _barangays.isEmpty,
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
                      TextButton(
                        onPressed: () => _load(() async {
                          if (_places.isEmpty) {
                            _places = await _api.provincesAndNcr();
                          } else if (_barangays.isEmpty && _city != null) {
                            _barangays = await _api.barangays(_city!);
                          } else if (_cities.isEmpty && _place != null) {
                            _cities = await _api.cities(_place!);
                          }
                        }),
                        child: const Text('Retry'),
                      ),
                    ],

                    const SizedBox(height: 10),
                    _heading('Street Details'),
                    CustomTextField(
                      label: 'House No.',
                      icon: Icons.house_outlined,
                      controller: _houseCtrl,
                      validator: (v) => Validators.required(v, 'House No.'),
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

                    const SizedBox(height: 10),
                    _heading('Account'),
                    CustomTextField(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    gap,
                    CustomTextField(
                      label: 'Password',
                      icon: Icons.lock_outline,
                      controller: _passCtrl,
                      isPassword: true,
                      validator: Validators.password,
                    ),
                    gap,
                    CustomTextField(
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      controller: _confirmCtrl,
                      isPassword: true,
                      validator: (v) =>
                          v != _passCtrl.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      text: 'Register',
                      isLoading: _loading,
                      onPressed: _register,
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