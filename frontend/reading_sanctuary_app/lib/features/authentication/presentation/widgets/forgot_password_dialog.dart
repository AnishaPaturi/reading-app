import 'package:flutter/material.dart';
import '../theme/auth_palette.dart';
import 'clay_button.dart';
import 'clay_text_field.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordDialog({super.key, this.initialEmail});

  static Future<void> show(BuildContext context, {String? initialEmail}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => ForgotPasswordDialog(initialEmail: initialEmail),
    );
  }

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
        decoration: BoxDecoration(
          color: AuthPalette.cardSurface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AuthPalette.cardShadow,
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _submitted ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(
                  color: AuthPalette.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AuthPalette.textMuted),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your registered email address and we will send you instructions to reset your password.',
            style: TextStyle(
              color: AuthPalette.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ClayTextField(
            controller: _emailController,
            hintText: 'Enter your email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!val.contains('@') || !val.contains('.')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ClayButton(
            label: 'Send Reset Link',
            isLoading: _isLoading,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AuthPalette.iconBadge.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AuthPalette.primaryPurpleDark,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Check Your Inbox',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AuthPalette.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent a reset link to ${_emailController.text.trim()}.\nPlease follow the instructions in the email.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AuthPalette.textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        ClayButton(
          label: 'Back to Login',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
