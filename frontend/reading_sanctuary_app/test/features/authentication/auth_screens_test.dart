import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:reading_sanctuary_app/features/authentication/presentation/screens/signup_screen.dart';
import 'package:reading_sanctuary_app/features/authentication/presentation/widgets/forgot_password_dialog.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Tests', () {
    testWidgets('renders all login elements correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // Verify fields
      expect(find.text('Email or Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('or continue with'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);

      // Verify 3 social buttons (tooltips)
      expect(find.byTooltip('Continue with Google'), findsOneWidget);
      expect(find.byTooltip('Continue with Apple'), findsOneWidget);
      expect(find.byTooltip('Continue with Facebook'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // Tap Login button without entering anything
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email or username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('tapping Forgot Password opens dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });
  });

  group('SignUpScreen Tests', () {
    testWidgets('renders all signup elements correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(const SignUpScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('validates password mismatch on signup', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(const SignUpScreen()));
      await tester.pumpAndSettle();

      // Enter mismatched passwords
      await tester.enterText(find.widgetWithText(TextField, 'Username'), 'testuser');
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'test@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), 'mismatch456');

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('ForgotPasswordDialog Tests', () {
    testWidgets('validates email input and submits', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const Scaffold(
            body: ForgotPasswordDialog(initialEmail: 'test@example.com'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Check Your Inbox'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });
  });
}
