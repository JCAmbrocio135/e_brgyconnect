import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/request_service.dart';
import '../widgets/request_card.dart';
import 'request_details_screen.dart';

class RequestListScreen extends StatelessWidget {
  final String title;
  final bool activeOnly;

  const RequestListScreen({
    super.key,
    required this.title,
    this.activeOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: RequestService.instance,
        builder: (context, _) {
          final items = RequestService.instance.requests
              .where(
                (r) =>
                    !activeOnly ||
                    (r.status != 'Released' &&
                        r.status != 'Rejected'),
              )
              .toList();

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No requests yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (_, i) => RequestCard(
              request: items[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestDetailsScreen(
                    request: items[i],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}