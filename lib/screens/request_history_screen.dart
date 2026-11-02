import 'package:flutter/material.dart';
import 'request_list_screen.dart';

class RequestHistoryScreen extends StatelessWidget {
  const RequestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestListScreen(
      title: 'Request History',
    );
  }
}