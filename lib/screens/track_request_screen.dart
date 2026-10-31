import 'package:flutter/material.dart';

class TrackRequestScreen extends StatelessWidget {
  const TrackRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Request'),
      ),
      body: const Center(
        child: Text('Track Request Screen'),
      ),
    );
  }
}