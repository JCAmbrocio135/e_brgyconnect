import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  bool _loading = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    // Reuse the email already typed on the login screen
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final error = await AuthService.instance.sendPasswordReset(_emailCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() => _sent = true);
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
          const SizedBox(height: 14),
          const Text(
            'Enter the email you registered with and we will send you a link to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 22),
          CustomTextField(
            label: 'Email',
            icon: Icons.email_outlined,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            text: 'Send Reset Link',
            isLoading: _loading,
            onPressed: _send,
          ),
        ],
      ),
    );
  }

  Widget _confirmation() {
    return Column(
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 64, color: AppColors.green),
        const SizedBox(height: 14),
        const Text(
          'Check your email',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'If an account exists for that email, we sent a link to reset your password. Check your spam folder too.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          text: 'Back to Login',
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          onPressed: () => setState(() => _sent = false),
          child: const Text('Use a different email'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _sent ? _confirmation() : _form(),
            ),
          ),
        ),
      ),
    );
  }
}