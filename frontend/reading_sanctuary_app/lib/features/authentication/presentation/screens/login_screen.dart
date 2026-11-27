import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_palette.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import '../widgets/forgot_password_dialog.dart';
import '../widgets/social_login_row.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectTo;
  final bool sessionExpired;

  const LoginScreen({
    super.key,
    this.redirectTo,
    this.sessionExpired = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showAuthError('Your session has expired. Please sign in again.');
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _postAuthDestination {
    final r = widget.redirectTo;
    if (r != null && r.startsWith('/') && !r.startsWith('/login') && !r.startsWith('/signup')) {
      return r;
    }
    return '/home';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authNotifierProvider.notifier).login(
      email: _emailController.text.trim(), password: _passwordController.text.trim());
    if (!mounted) return;
    if (success) {
      context.go(_postAuthDestination);
    } else {
      _showAuthError(ref.read(authNotifierProvider).error ?? 'Login failed');
    }
  }

  Future<void> _handleSocial(String provider) async {
    final success = await ref.read(authNotifierProvider.notifier).loginWithSocial(provider);
    if (!mounted) return;
    if (success) {
      context.go(_postAuthDestination);
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
            child: Text('Forgot Password?', style: GoogleFonts.inter(
              color: AuthPalette.textLink, fontSize: 13.5, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 16),
          ClayButton(label: 'Login', isLoading: authState.isLoading, onPressed: _handleLogin),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Container(height: 1, color: AuthPalette.dividerLine)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with', style: GoogleFonts.inter(
                color: AuthPalette.textMuted, fontSize: 13, fontWeight: FontWeight.w500))),
            Expanded(child: Container(height: 1, color: AuthPalette.dividerLine)),
          ]),
          const SizedBox(height: 18),
          SocialLoginRow(onSocialSelect: _handleSocial),
          const SizedBox(height: 22),
          Center(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center, children: [
            Text("Don't have an account? ", style: GoogleFonts.inter(
              color: AuthPalette.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
            GestureDetector(onTap: () {
              final redirect = widget.redirectTo;
              context.go(redirect != null
                  ? '/signup?redirect=${Uri.encodeComponent(redirect)}'
                  : '/signup');
            },
              child: Text('Sign Up', style: GoogleFonts.inter(
                color: AuthPalette.textLink, fontSize: 14, fontWeight: FontWeight.w700))),
          ])),
        ]),
      ),
    );
  }
}
