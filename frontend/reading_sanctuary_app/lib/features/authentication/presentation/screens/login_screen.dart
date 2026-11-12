import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_palette.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import '../widgets/forgot_password_dialog.dart';
import '../widgets/social_login_row.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authNotifierProvider.notifier).login(
      email: _emailController.text.trim(), password: _passwordController.text);
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      _showAuthError(ref.read(authNotifierProvider).error ?? 'Login failed');
    }
  }

  Future<void> _handleSocial(String provider) async {
    final success = await ref.read(authNotifierProvider.notifier).loginWithSocial(provider);
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      final error = ref.read(authNotifierProvider).error;
      if (error != null && error.isNotEmpty) _showAuthError(error);
    }
  }

  void _showAuthError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message), backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return AuthScaffold(
      headerAsset: 'assets/images/auth/login_header.png',
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClayTextField(controller: _emailController, hintText: 'Email or Username',
            icon: Icons.person_rounded, keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: (val) => val == null || val.trim().isEmpty
                ? 'Please enter your email or username' : null),
          const SizedBox(height: 14),
          ClayTextField(controller: _passwordController, hintText: 'Password',
            icon: Icons.lock_rounded, isPassword: true,
            textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _handleLogin(),
            validator: (val) => val == null || val.isEmpty
                ? 'Please enter your password' : null),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () => ForgotPasswordDialog.show(context,
              initialEmail: _emailController.text.trim()),
            child: const Text('Forgot Password?', style: TextStyle(
              color: AuthPalette.textLink, fontSize: 13.5, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 16),
          ClayButton(label: 'Login', isLoading: authState.isLoading, onPressed: _handleLogin),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Container(height: 1, color: AuthPalette.dividerLine)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with', style: TextStyle(
                color: AuthPalette.textMuted, fontSize: 13, fontWeight: FontWeight.w500))),
            Expanded(child: Container(height: 1, color: AuthPalette.dividerLine)),
          ]),
          const SizedBox(height: 18),
          SocialLoginRow(onSocialSelect: _handleSocial),
          const SizedBox(height: 22),
          Center(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center, children: [
            const Text("Don't have an account? ", style: TextStyle(
              color: AuthPalette.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
            GestureDetector(onTap: () => context.go('/signup'),
              child: const Text('Sign Up', style: TextStyle(
                color: AuthPalette.textLink, fontSize: 14, fontWeight: FontWeight.w700))),
          ])),
        ]),
      ),
    );
  }
}
