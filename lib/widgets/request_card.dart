import 'package:flutter/material.dart';
import '../core/format.dart';
import '../models/document_request.dart';
import 'status_badge.dart';

class RequestCard extends StatelessWidget {
  final DocumentRequest request;
  final VoidCallback onTap;

  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD9E2EC),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              color: Color(0xFF123B6D),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.documentType,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.requestNo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pickup: ${formatDate(request.pickupDate)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 7),
                  StatusBadge(status: request.status),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}