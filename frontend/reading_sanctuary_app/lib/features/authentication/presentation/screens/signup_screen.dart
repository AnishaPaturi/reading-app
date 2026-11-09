import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_palette.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import '../widgets/social_login_row.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
        );

    if (mounted) {
      if (success) {
        context.go('/home');
      } else {
        final error = ref.read(authNotifierProvider).error ?? 'Sign up failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleSocial(String provider) async {
    final success = await ref.read(authNotifierProvider.notifier).loginWithSocial(provider);
    if (mounted && success) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return AuthScaffold(
      headerAsset: 'assets/images/auth/signup_header.png',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Username / Name
            ClayTextField(
              controller: _usernameController,
              hintText: 'Username',
              icon: Icons.person_rounded,
              textInputAction: TextInputAction.next,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Email Address
            ClayTextField(
              controller: _emailController,
              hintText: 'Email Address',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password
            ClayTextField(
              controller: _passwordController,
              hintText: 'Password',
              icon: Icons.lock_rounded,
              isPassword: true,
              textInputAction: TextInputAction.next,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter a password';
                }
                if (val.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Confirm Password
            ClayTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm Password',
              icon: Icons.verified_user_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSignUp(),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please confirm your password';
                }
                if (val != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),

            // Sign Up Button
            ClayButton(
              label: 'Sign Up',
              isLoading: authState.isLoading,
              onPressed: _handleSignUp,
            ),
            const SizedBox(height: 20),

            // Divider: or continue with
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AuthPalette.dividerLine,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or continue with',
                    style: TextStyle(
                      color: AuthPalette.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AuthPalette.dividerLine,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Social Login Buttons
            SocialLoginRow(onSocialSelect: _handleSocial),
            const SizedBox(height: 22),

            // Bottom Switch to Login
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: AuthPalette.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: AuthPalette.textLink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
