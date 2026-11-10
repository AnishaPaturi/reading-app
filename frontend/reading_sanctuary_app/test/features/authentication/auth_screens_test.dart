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

      // Verify only Google social button is present, Apple & Facebook are removed
      expect(find.byTooltip('Continue with Google'), findsOneWidget);
      expect(find.byTooltip('Continue with Apple'), findsNothing);
      expect(find.byTooltip('Continue with Facebook'), findsNothing);

      // Verify input bars have white fill
      final emailField = tester.widget<TextField>(find.widgetWithText(TextField, 'Email or Username'));
      final passwordField = tester.widget<TextField>(find.widgetWithText(TextField, 'Password'));
      expect(emailField.decoration?.fillColor, const Color(0xFFFFFFFF));
      expect(passwordField.decoration?.fillColor, const Color(0xFFFFFFFF));
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

    testWidgets('renders input bars white instead of dark theme fillColor', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Colors.black,
              ),
            ),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextField>(find.widgetWithText(TextField, 'Email or Username'));
      final passwordField = tester.widget<TextField>(find.widgetWithText(TextField, 'Password'));
      expect(emailField.decoration?.fillColor, const Color(0xFFFFFFFF));
      expect(passwordField.decoration?.fillColor, const Color(0xFFFFFFFF));
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
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.byType(Radio<String>), findsNWidgets(2));
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('renders and toggles gender radio buttons on signup', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(const SignUpScreen()));
      await tester.pumpAndSettle();

      // Check initial state (neither selected)
      final maleRadio = tester.widget<Radio<String>>(find.byWidgetPredicate(
        (w) => w is Radio<String> && w.value == 'male',
      ));
      final femaleRadio = tester.widget<Radio<String>>(find.byWidgetPredicate(
        (w) => w is Radio<String> && w.value == 'female',
      ));
      expect(maleRadio.groupValue, isNull);
      expect(femaleRadio.groupValue, isNull);

      // Select Male
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      final maleSelected = tester.widget<Radio<String>>(find.byWidgetPredicate(
        (w) => w is Radio<String> && w.value == 'male',
      ));
      expect(maleSelected.groupValue, 'male');

      // Select Female
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();

      final femaleSelected = tester.widget<Radio<String>>(find.byWidgetPredicate(
        (w) => w is Radio<String> && w.value == 'female',
      ));
      expect(femaleSelected.groupValue, 'female');
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
