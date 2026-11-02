import 'package:flutter/material.dart';
import 'request_list_screen.dart';

class TrackRequestScreen extends StatelessWidget {
  const TrackRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestListScreen(
      title: 'Track Request',
      activeOnly: true,
    );
  }
}