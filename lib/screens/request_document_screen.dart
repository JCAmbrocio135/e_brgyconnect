import 'package:flutter/material.dart';

class RequestDocumentScreen extends StatelessWidget {
  const RequestDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Document'),
      ),
      body: const Center(
        child: Text('Request Document Screen'),
      ),
    );
  }
}