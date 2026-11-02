import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/format.dart';
import '../core/validators.dart';
import '../models/document_type.dart';
import '../services/request_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'request_details_screen.dart';

class RequestDocumentScreen extends StatefulWidget {
  const RequestDocumentScreen({super.key});

  @override
  State<RequestDocumentScreen> createState() =>
      _RequestDocumentScreenState();
}

class _RequestDocumentScreenState extends State<RequestDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();

  DocumentType? _selected;
  DateTime? _pickupDate;
  bool _loading = false;

  @override
  void dispose() {
    _purposeCtrl.dispose();
    _pickupCtrl.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final req = await RequestService.instance.submit(
      type: _selected!.name,
      purpose: _purposeCtrl.text.trim(),
      pickupDate: _pickupDate!,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request ${req.requestNo} submitted!'),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetailsScreen(request: req),
      ),
    );
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
                        prefixIcon: const Icon(
                          Icons.description_outlined,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: DocumentType.all
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selected = v);
                      },
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
                            Text(
                              'Fee: ${_selected!.fee}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Requirements: ${_selected!.requirements}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    CustomTextField(
                      label: 'Purpose (e.g. Employment)',
                      icon: Icons.edit_note,
                      controller: _purposeCtrl,
                      validator: (v) =>
                          Validators.required(v, 'Purpose'),
                    ),

                    const SizedBox(height: 14),

                    CustomTextField(
                      label: 'Preferred Pickup Date',
                      icon: Icons.event_outlined,
                      controller: _pickupCtrl,
                      readOnly: true,
                      onTap: _pickDate,
                      validator: (v) =>
                          Validators.required(v, 'Pickup date'),
                    ),

                    const SizedBox(height: 14),

                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Upload coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Valid ID'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

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