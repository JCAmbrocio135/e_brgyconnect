import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/document_request.dart';
import '../services/request_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/progress_tracker.dart';

class RequestDetailsScreen extends StatelessWidget {
  final DocumentRequest request;

  const RequestDetailsScreen({
    super.key,
    required this.request,
  });

  static const _steps = [
    'Pending',
    'Processing',
    'Ready for Pickup',
    'Released',
  ];

  String _headline() {
    switch (request.status) {
      case 'Processing':
        return 'Staff is processing your request';
      case 'Ready for Pickup':
        return 'Ready for pickup on ${formatDate(request.pickupDate)}';
      case 'Released':
        return 'Document released';
      default:
        return 'Request received';
    }
  }

  // Tracker colors: Pending gray, Processing yellow, Ready/Released green
  Color _fill() {
    switch (request.status) {
      case 'Processing':
        return const Color(0xFFF2B01E);
      case 'Ready for Pickup':
      case 'Released':
        return AppColors.green;
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _text() {
    switch (request.status) {
      case 'Processing':
        return const Color(0xFF8A6500);
      case 'Ready for Pickup':
      case 'Released':
        return AppColors.green;
      default:
        return const Color(0xFF4B5563);
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel Request',
              style: TextStyle(color: Color(0xFFB42318)),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await RequestService.instance.cancel(request.requestNo);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request ${request.requestNo} cancelled.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(request.status);
    final isRejected = request.status == 'Rejected';
    final isCancelled = request.status == 'Cancelled';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Request #${request.requestNo}'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                request.documentType,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            StatusBadge(status: request.status),
                          ],
                        ),
                        const Divider(height: 24),
                        _row('Purpose', request.purpose),
                        _row('Filed on', formatDate(request.createdAt)),
                        _row('Pickup date', formatDate(request.pickupDate)),
                        if (request.paymentMethod != 'None') ...[
                          const Divider(height: 24),
                          _row('Payment', request.paymentMethod),
                          if (request.amount > 0)
                            _row('Amount', '₱${request.amount}'),
                          _row('Payment status', request.paymentStatus),
                          if (request.paymentRef != null)
                            _row('Reference', request.paymentRef!),
                          if (request.paymentMethod.contains('Demo'))
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Demo payment: no real money was charged.',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Rejected: red remarks box
                  if (isRejected)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Staff remarks: ${request.remarks ?? 'No remarks.'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB42318),
                        ),
                      ),
                    )
                  // Cancelled: grey notice
                  else if (isCancelled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'You cancelled this request.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    )
                  // Otherwise: progress tracker
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _headline(),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _text(),
                            ),
                          ),
                          const SizedBox(height: 22),
                          ProgressTracker(
                            steps: _steps,
                            current: current,
                            color: _fill(),
                            textColor: _text(),
                          ),
                        ],
                      ),
                    ),

                  // Cancel button: only for Pending requests
                  if (request.status == 'Pending') ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _cancel(context),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB42318),
                        side: const BorderSide(color: Color(0xFFB42318)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}