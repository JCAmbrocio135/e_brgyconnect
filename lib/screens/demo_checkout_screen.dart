import 'dart:math';

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/document_type.dart';
import '../models/payment_info.dart';
import '../widgets/primary_button.dart';

class DemoCheckoutScreen extends StatefulWidget {
  final DocumentType type;
  final PayMethod method;

  const DemoCheckoutScreen({
    super.key,
    required this.type,
    required this.method,
  });

  @override
  State<DemoCheckoutScreen> createState() => _DemoCheckoutScreenState();
}

class _DemoCheckoutScreenState extends State<DemoCheckoutScreen> {
  bool _processing = false;
  PaymentInfo? _done;

  Future<void> _pay() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 2200)); // fake processing
    if (!mounted) return;

    final ref = 'DEMO-${100000 + Random().nextInt(900000)}';
    setState(() {
      _processing = false;
      _done = PaymentInfo.demoPaid(
        method: widget.method,
        amount: widget.type.amount!,
        reference: ref,
      );
    });
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _checkout() {
    final amount = widget.type.amount!;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'DEMO ONLY. This is a simulated payment for a class project. '
            'No real money is charged. Never enter real account details here. '
            'Not affiliated with GCash or Maya.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A6500)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _row('Pay to', 'E-BrgyConnect (Demo)'),
              _row('Document', widget.type.name),
              _row('Method', widget.method.label),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '₱$amount',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          text: 'Pay ₱$amount (Demo)',
          isLoading: _processing,
          onPressed: _pay,
        ),
        const SizedBox(height: 8),
        if (_processing)
          const Text(
            'Processing payment...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _success() {
    final d = _done!;

    return Column(
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.check_circle, size: 72, color: AppColors.green),
        const SizedBox(height: 12),
        const Text(
          'Payment successful (demo)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _row('Reference', d.reference ?? ''),
              _row('Method', d.method),
              _row('Amount', '₱${d.amount}'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your request will be submitted next. No real money was charged.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          text: 'Continue',
          onPressed: () => Navigator.pop(context, _done),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canLeave = !_processing && _done == null;

    return PopScope(
      canPop: canLeave,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Demo Checkout'),
          backgroundColor: Colors.white,
          automaticallyImplyLeading: canLeave,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _done == null ? _checkout() : _success(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}