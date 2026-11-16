import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/document_type.dart';
import '../models/payment_info.dart';

class PaymentMethodSelector extends StatelessWidget {
  final DocumentType? type;
  final PayMethod? method;
  final bool showError;
  final ValueChanged<PayMethod> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.type,
    required this.method,
    required this.showError,
    required this.onChanged,
  });

  Widget _info(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.welcomeCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );

  Widget _tile(PayMethod m) {
    final selected = method == m;
    final (icon, subtitle, color) = switch (m) {
      PayMethod.gcash => (
          Icons.account_balance_wallet_outlined,
          'E-wallet (demo)',
          const Color(0xFF0B6FE0),
        ),
      PayMethod.maya => (
          Icons.account_balance_wallet_outlined,
          'E-wallet (demo)',
          const Color(0xFF12B76A),
        ),
      PayMethod.hall => (
          Icons.storefront_outlined,
          'Pay in cash when you pick it up',
          AppColors.primary,
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(m),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = type;
    if (t == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Payment',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (t.isFree)
          _info('No payment needed. This document is free.')
        else if (!t.canPayOnline)
          _info('Fee: ${t.fee}. Please pay at the barangay hall when you pick it up.')
        else ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.welcomeCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount to pay', style: TextStyle(fontSize: 12)),
                Text(
                  '₱${t.amount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          for (final m in PayMethod.values) _tile(m),
          if (showError && method == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Please choose a payment option.',
                style: TextStyle(fontSize: 11, color: Color(0xFFB42318)),
              ),
            ),
          const Text(
            'Online options are a demo for this project. No real money is charged.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}