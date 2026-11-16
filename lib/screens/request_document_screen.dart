import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import '../core/format.dart';
import '../core/validators.dart';
import '../models/document_type.dart';
import '../models/payment_info.dart';
import '../models/upload_file.dart';
import '../services/request_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/primary_button.dart';
import '../widgets/requirement_upload_tile.dart';
import 'demo_checkout_screen.dart';
import 'request_details_screen.dart';

class RequestDocumentScreen extends StatefulWidget {
  const RequestDocumentScreen({super.key});

  @override
  State<RequestDocumentScreen> createState() => _RequestDocumentScreenState();
}

class _RequestDocumentScreenState extends State<RequestDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  DocumentType? _selected;
  DateTime? _pickupDate;
  bool _loading = false;
  bool _showErrors = false;

  // Picked images, by requirement key
  final Map<String, Uint8List> _files = {};

  // Payment
  PayMethod? _method;
  PaymentInfo? _paid; // demo payment already done (kept if a submit is retried)

  @override
  void dispose() {
    _purposeCtrl.dispose();
    _pickupCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onTypeChanged(DocumentType? v) {
    setState(() {
      _selected = v;
      _showErrors = false;
      _method = null;
      _paid = null;
      // Keep images that still apply (e.g. the Valid ID), drop the rest
      if (v != null) {
        _files.removeWhere((key, _) => !v.requirements.any((r) => r.key == key));
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      _pickupDate = picked;
      _pickupCtrl.text = formatDate(picked);
    }
  }

  Future<void> _pickImage(Requirement r, ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
      );
      if (picked == null) return; // user cancelled

      final bytes = await picked.readAsBytes();

      if (!RequestService.isSupportedImage(bytes)) {
        _toast('Please use a JPG or PNG photo.');
        return;
      }
      if (bytes.length > RequestService.maxImageBytes) {
        _toast('That photo is too large. Choose a smaller one or retake it.');
        return;
      }

      setState(() => _files[r.key] = bytes);
    } catch (_) {
      _toast('Could not open the photo picker.');
    }
  }

  void _imageOptions(Requirement r) {
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
                _pickImage(r, ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(r, ImageSource.camera);
                },
              ),
            if (_files.containsKey(r.key))
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Color(0xFFB42318)),
                title: const Text(
                  'Remove',
                  style: TextStyle(color: Color(0xFFB42318)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _files.remove(r.key));
                },
              ),
          ],
        ),
      ),
    );
  }

  // Returns the payment to save, or null if the resident backed out.
  Future<PaymentInfo?> _resolvePayment() async {
    final t = _selected!;

    if (t.isFree) return PaymentInfo.notRequired();
    if (!t.canPayOnline) return PaymentInfo.payAtHall();

    final m = _method;
    if (m == null) {
      _toast('Please choose a payment option.');
      return null;
    }
    if (m == PayMethod.hall) return PaymentInfo.payAtHall(t.amount!);

    // Already paid in this session (the submit failed and is being retried)
    if (_paid != null && _paid!.method == m.label) return _paid;

    final result = await Navigator.push<PaymentInfo>(
      context,
      MaterialPageRoute(
        builder: (_) => DemoCheckoutScreen(type: t, method: m),
      ),
    );
    if (result != null) _paid = result;
    return result;
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _showErrors = true);
    if (!valid) return;

    final missing = _selected!.requirements
        .where((r) => !_files.containsKey(r.key))
        .toList();
    if (missing.isNotEmpty) {
      _toast('Please upload: ${missing.map((r) => r.label).join(', ')}');
      return;
    }

    // Payment comes after the form and uploads are complete
    final payment = await _resolvePayment();
    if (payment == null || !mounted) return;

    setState(() => _loading = true);

    try {
      final req = await RequestService.instance.submit(
        type: _selected!.name,
        purpose: _purposeCtrl.text.trim(),
        pickupDate: _pickupDate!,
        payment: payment,
        files: [
          for (final r in _selected!.requirements)
            UploadFile(r.key, r.label, _files[r.key]!),
        ],
      );

      if (!mounted) return;
      setState(() => _loading = false);

      _toast('Request ${req.requestNo} submitted!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request Document'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<DocumentType>(
                      initialValue: _selected,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Document Type',
                        prefixIcon: const Icon(Icons.description_outlined,
                            color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: DocumentType.all
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d.name),
                              ))
                          .toList(),
                      onChanged: _onTypeChanged,
                      validator: (v) =>
                          v == null ? 'Select a document type' : null,
                    ),
                    if (_selected != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.welcomeCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fee: ${_selected!.fee}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                                'Requirements: ${_selected!.requirementsText}',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Purpose (e.g. Employment)',
                      icon: Icons.edit_note,
                      controller: _purposeCtrl,
                      validator: (v) => Validators.required(v, 'Purpose'),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Preferred Pickup Date',
                      icon: Icons.event_outlined,
                      controller: _pickupCtrl,
                      readOnly: true,
                      onTap: _pickDate,
                      validator: (v) => Validators.required(v, 'Pickup date'),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Required Uploads',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selected == null)
                      const Text(
                        'Choose a document type to see what you need to upload.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      for (final r in _selected!.requirements) ...[
                        RequirementUploadTile(
                          requirement: r,
                          bytes: _files[r.key],
                          showError: _showErrors,
                          onTap: () => _imageOptions(r),
                        ),
                        const SizedBox(height: 10),
                      ],
                    PaymentMethodSelector(
                      type: _selected,
                      method: _method,
                      showError: _showErrors,
                      onChanged: (m) => setState(() {
                        _method = m;
                        _paid = null;
                      }),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      text: 'Submit Request',
                      isLoading: _loading,
                      onPressed: _submit,
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