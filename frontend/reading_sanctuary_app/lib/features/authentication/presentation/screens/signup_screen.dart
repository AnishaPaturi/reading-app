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
  String? _selectedGender;

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
    if (_selectedGender != null) {
      final genderKey = _selectedGender == 'male' ? 'boy' : 'girl';
      ref.read(userGenderProvider.notifier).state = genderKey;
    }
    final success = await ref.read(authNotifierProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _usernameController.text.trim(),
      gender: _selectedGender,
    );
    if (!mounted) return;
    if (success) {
      if (_selectedGender != null) {
        final genderKey = _selectedGender == 'male' ? 'boy' : 'girl';
        ref.read(authNotifierProvider.notifier).setGender(genderKey);
        ref.read(userGenderProvider.notifier).state = genderKey;
      }
      context.go('/home');
    } else {
      _showAuthError(ref.read(authNotifierProvider).error ?? 'Sign up failed');
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
      headerAsset: 'assets/images/auth/signup_header.png',
      child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClayTextField(controller: _usernameController, hintText: 'Username',
          icon: Icons.person_rounded, textInputAction: TextInputAction.next,
          validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your username' : null),
        const SizedBox(height: 14),
        ClayTextField(controller: _emailController, hintText: 'Email Address',
          icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) => v == null || !v.contains('@') || !v.contains('.')
              ? 'Please enter a valid email address' : null),
        const SizedBox(height: 14),
        ClayTextField(controller: _passwordController, hintText: 'Password',
          icon: Icons.lock_rounded, isPassword: true, textInputAction: TextInputAction.next,
          validator: (v) => v == null || v.length < 8
              ? 'Password must be at least 8 characters' : null),
        const SizedBox(height: 14),
        ClayTextField(controller: _confirmPasswordController, hintText: 'Confirm Password',
          icon: Icons.verified_user_rounded, isPassword: true, textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleSignUp(),
          validator: (v) => v == null || v.isEmpty ? 'Please confirm your password'
              : v.trim() != _passwordController.text.trim() ? 'Passwords do not match' : null),
        const SizedBox(height: 14),
        _buildGenderSelector(),
        const SizedBox(height: 22),
        ClayButton(label: 'Sign Up', isLoading: authState.isLoading, onPressed: _handleSignUp),
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
          const Text('Already have an account? ', style: TextStyle(
            color: AuthPalette.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
          GestureDetector(onTap: () => context.go('/login'),
            child: const Text('Login', style: TextStyle(
              color: AuthPalette.textLink, fontSize: 14, fontWeight: FontWeight.w700))),
        ])),
      ])),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AuthPalette.inputBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AuthPalette.inputBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'Gender',
              style: TextStyle(
                color: AuthPalette.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selectedGender = 'male'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: 'male',
                          groupValue: _selectedGender,
                          activeColor: AuthPalette.primaryPurpleDark,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (val) => setState(() => _selectedGender = val),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Male',
                          style: TextStyle(
                            color: AuthPalette.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selectedGender = 'female'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: 'female',
                          groupValue: _selectedGender,
                          activeColor: AuthPalette.primaryPurpleDark,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (val) => setState(() => _selectedGender = val),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Female',
                          style: TextStyle(
                            color: AuthPalette.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
