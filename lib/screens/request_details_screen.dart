import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/document_request.dart';
import '../widgets/status_badge.dart';

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
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(request.status);

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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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
                            StatusBadge(
                              status: request.status,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _row('Purpose', request.purpose),
                        _row(
                          'Filed on',
                          formatDate(request.createdAt),
                        ),
                        _row(
                          'Pickup date',
                          formatDate(request.pickupDate),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (request.status == 'Rejected')
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
                  else ...[
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    for (var i = 0; i < _steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              i <= current
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: i <= current
                                  ? AppColors.green
                                  : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _steps[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: i == current
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
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