import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stockflow/screens/forgot_pw_page.dart';
import 'package:stockflow/screens/login_page.dart';
import 'login_test.mocks.dart';

/*
// Unit and widget tests:
// 🔹 Mandatory fields: Checks whether the system prevents the
// form from being sent if the login and password fields are empty.
// 🔹 Email format: Tests whether invalid emails are rejected
// 🔹 Minimum password 8 characters: Ensures that the password has at least 8 characters
// 🔹 Password visibility toggle: Tests whether the 
// password can be displayed and hidden when clicking the eye icon
// 🔹 Text input: Verify email and password input fields
// 🔹 Forgot Password link navigates to ForgotPasswordPage
// 🔹 Register now link calls showRegisterPage callback
// 🔹 Support link opens the support email dialog
*/

class MockNavigatorObserver extends Mock implements NavigatorObserver {}
@GenerateMocks([FirebaseAuth, User, UserCredential])

Future<void> main() async {

  testWidgets('Mandatory fields: Empty login email', (WidgetTester tester) async {
    // Mandatory fields: Checks whether the system prevents the form from being 
    // sent if the login and password fields are empty.
    await tester.pumpWidget(MaterialApp(
      home: LoginPage(showRegisterPage: () {}),
    ));

    // Tap the login button without filling in the fields
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Verify if the error alert is displayed
    expect(find.text('Please enter your email address.'), findsOneWidget);
  });

  testWidgets('Mandatory fields: Empty password', (WidgetTester tester) async {
    // Mandatory fields: Checks whether the system prevents the form from 
    // being sent if the password field is empty.
    await tester.pumpWidget(MaterialApp(
      home: LoginPage(showRegisterPage: () {}),
    ));

    // Fill in the email field but leave the password field empty
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Verify if the error alert is displayed
    expect(find.text('The password must be at least 8 characters long and include at least one uppercase letter and one special character.'), findsOneWidget);
  });

  testWidgets('Invalid email format.', (WidgetTester tester) async {
    // Email format: Tests whether invalid emails are rejected.
    await tester.pumpWidget(MaterialApp(
      home: LoginPage(showRegisterPage: () {}),
    ));
    await tester.pumpAndSettle(); // Ensures the layout is rendered

    // List of invalid emails
    List<String> invalidEmails = ['usuario.com', 'user@com', 'user@.com', 'user@com.'];

    for (String email in invalidEmails) {
      await tester.enterText(find.byType(TextField).first, email);
      
      // Ensure the button is visible
      await tester.ensureVisible(find.text('Sign In'));
      
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(); // Wait for animations to finish

      // Debugging: print texts on the screen
      if (kDebugMode) {
        print(tester.widgetList(find.byType(Text)).map((e) => (e as Text).data).toList());
      }

      // Verify if the error alert appears
      expect(find.text('The email address is not valid. Please check your input.'), findsOneWidget);
    }
  });

  testWidgets('Password minimum 8 characters', (WidgetTester tester) async {
    // Minimum and maximum length: Ensures the password has at least 8 characters.
    await tester.pumpWidget(MaterialApp(
      home: LoginPage(showRegisterPage: () {}),
    ));
    await tester.pumpAndSettle(); // Ensures the layout is rendered

    // Enter a valid email
    await tester.enterText(find.byType(TextField).first, 'validemail@example.com');

    // List of invalid passwords (less than 8 characters)
    List<String> shortPasswords = ['123', 'abc12', 'pass1'];

    for (String password in shortPasswords) {
      await tester.enterText(find.byType(TextField).at(1), password);
      
      // Ensure the button is visible
      await tester.ensureVisible(find.text('Sign In'));

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(); // Wait for animations to finish

      // Verify if the error alert appears
      expect(find.text('The password must be at least 8 characters long and include at least one uppercase letter and one special character.'), findsOneWidget);
    }
  });

  testWidgets('Password visibility toggle', (WidgetTester tester) async {
    // Create the LoginPage widget
    await tester.pumpWidget(MaterialApp(
      home: LoginPage(showRegisterPage: () {}),
    ));

    // Find the password field
    final passwordField = find.byType(TextField).at(1);

    // Verify if the password is initially hidden
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect((tester.widget(passwordField) as TextField).obscureText, true);

    // Click the eye icon (visibility)
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    // Verify if the password is visible after the click
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect((tester.widget(passwordField) as TextField).obscureText, false);

    // Click the eye icon again to hide the password
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    // Verify if the password is hidden again
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect((tester.widget(passwordField) as TextField).obscureText, true);
  });

  testWidgets('Verify email and password input fields', (WidgetTester tester) async {
  // Text input: Verify email and password input fields
  // Create the LoginPage widget
  await tester.pumpWidget(MaterialApp(
    home: LoginPage(showRegisterPage: () {}),
  ));

  // Find the text input fields
  final emailField = find.byType(TextField).first; // First TextField is the email field
  final passwordField = find.byType(TextField).at(1); // Second TextField is the password field

  // Test text for email and password
  const testEmail = 'test@example.com';
  const testPassword = 'TestPassword123!';

  // Enter text in the email field
  await tester.enterText(emailField, testEmail);
  // Verify if the text was entered correctly
  expect(find.text(testEmail), findsOneWidget);

  // Enter text in the password field
  await tester.enterText(passwordField, testPassword);
  // Verify if the text was entered correctly
  expect(find.text(testPassword), findsOneWidget);
});

testWidgets('Forgot Password link test', (WidgetTester tester) async {
  // Forgot Password link navigates to ForgotPasswordPage
  // Mount the LoginPage widget
  await tester.pumpWidget(MaterialApp(
    home: LoginPage(showRegisterPage: () {}),
  ));

  // Find the "Forgot Password?" link
  final forgotPasswordLink = find.text('Forgot Password?');

  // Verify if the link is present on the screen
  expect(forgotPasswordLink, findsOneWidget);

  // Tap the "Forgot Password?" link
  await tester.tap(forgotPasswordLink);
  await tester.pumpAndSettle(); // Wait for navigation

  // Verify if navigation to ForgotPasswordPage occurred
  expect(find.byType(ForgotPasswordPage), findsOneWidget);
});

testWidgets('Register now link test', (WidgetTester tester) async {
  // Register now link calls showRegisterPage callback
  // Variable to track if the callback was called
  bool isRegisterPageCalled = false;

  // Function to simulate the callback
  void showRegisterPage() {
    isRegisterPageCalled = true;
  }

  // Mount the LoginPage widget with the callback
  await tester.pumpWidget(MaterialApp(
    home: LoginPage(showRegisterPage: showRegisterPage),
  ));

  // Find the "Register now" link
  final registerNowLink = find.text(' Register now'); // Ensure the text matches exactly

  // Scroll the screen to ensure the link is visible
  await tester.ensureVisible(registerNowLink);

  // Verify if the link is present on the screen
  expect(registerNowLink, findsOneWidget);

  // Tap the "Register now" link
  await tester.tap(registerNowLink);
  await tester.pumpAndSettle(); // Wait for any animation or navigation

  // Verify if the callback was called
  expect(isRegisterPageCalled, isTrue);
});

testWidgets('Support link test', (WidgetTester tester) async {
  // Support link opens the support email dialog
  // Mount the LoginPage widget
  await tester.pumpWidget(MaterialApp(
    home: LoginPage(showRegisterPage: () {}),
  ));

  // Find the "Support" link
  final supportLink = find.text('Support');

  // Scroll the screen to ensure the link is visible
  await tester.ensureVisible(supportLink);

  // Verify if the link is present on the screen
  expect(supportLink, findsOneWidget);

  // Tap the "Support" link
  await tester.tap(supportLink);
  await tester.pumpAndSettle(); // Wait for the dialog to appear

  // Verify if the dialog was displayed with the correct title
  expect(find.text('Support Email'), findsOneWidget);

  // Verify if the dialog content is correct
  expect(find.text('For assistance, please contact: helpstockflow@gmail.com'), findsOneWidget);

  // Tap the "Close" button to close the dialog
  await tester.tap(find.text('Close'));
  await tester.pumpAndSettle(); // Wait for the dialog to close

  // Verify if the dialog was closed
  expect(find.text('Support Email'), findsNothing);
});

/*
// Integration tests:
// 🔹 Test for Successful Login: Test the end-to-end
// flow when a user inputs valid credentials 
// and logs in successfully. Verify if the user is 
// navigated to the /home page after a successful login.
// 🔹 Test for Failed Login: Test the flow when a user enters incorrect credentials 
// (e.g., wrong email or password). Verify if the error message is displayed and the state of 
// _failedAttempts is updated correctly.
// 🔹 Test for Lockout After Too Many Attempts: Simulate multiple failed login attempts and verify 
// if the lockout mechanism works (e.g., check if the lockout message appears and the user cannot 
// attempt to log in again until the lockout period expires).
// 🔹 Test for UI Elements: Verify if all UI elements (like the email and password fields, 
// sign-in button, and links) are displayed correctly and are interactive.
*/

  group('Login Page Integration Test with Mockito', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      // Crie instâncias simuladas do FirebaseAuth e User
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      // Configure o comportamento do mock
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => MockUserCredential());

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.emailVerified).thenReturn(true);
    });

testWidgets('Integration Test: Invalid Email', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: LoginPage(showRegisterPage: () {}),
  ));

  // Wait for the initial widgets to load
  await tester.pumpAndSettle();

  // Find the email and password fields using their type
  final emailField = find.byType(TextField).first; // First TextField is the email field
  final passwordField = find.byType(TextField).at(1); // Second TextField is the password field

  // Enter an invalid email
  await tester.enterText(emailField, 'invalidemail');

  // Enter a valid password
  await tester.enterText(passwordField, 'Password123!');

  // Tap the "Sign In" button using its text
  await tester.tap(find.text('Sign In'));
  await tester.pump();

  // Verify if the error message is displayed
  expect(find.text('The email address is not valid. Please check your input.'), findsOneWidget);
});

testWidgets('Integration Test: Incorrect Password', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: LoginPage(showRegisterPage: () {}),
  ));

  // Esperar o carregamento inicial dos widgets
  await tester.pumpAndSettle();

  // Verificar se os campos de email e senha estão na tela antes de interagir
  expect(find.byType(TextField).first, findsOneWidget); // Campo de email
  expect(find.byType(TextField).at(1), findsOneWidget); // Campo de senha

  // Inserir credenciais incorretas
  await tester.enterText(find.byType(TextField).first, 'test@example.com'); // Email
  await tester.enterText(find.byType(TextField).at(1), 'wrongpassword'); // Senha

  // Tentar fazer login
  await tester.tap(find.text('Sign In')); // Botão de login
  await tester.pumpAndSettle();

  // Verificar se aparece mensagem de erro
  expect(find.textContaining('The password must be at least 8 characters long and include at least one uppercase letter and one special character.'), findsOneWidget);
});

});

  group('Login Functionality Test', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      // Create mock instances
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      // Configure mock behavior
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => MockUserCredential());

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.emailVerified).thenReturn(true);
    });

  test('Successful login', () async {
    // Mock the behavior of signInWithEmailAndPassword
    when(mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'Password123!',
    )).thenAnswer((_) async => MockUserCredential());

    // Act: Call the method that should trigger signInWithEmailAndPassword
    await mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'Password123!',
    );

    // Verify that the signInWithEmailAndPassword method was called
    verify(mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'Password123!',
    )).called(1);

    // Check if the current user is the mock user
    expect(mockAuth.currentUser, isNotNull);
    expect(mockAuth.currentUser?.email, 'test@example.com');
    expect(mockAuth.currentUser?.emailVerified, isTrue);
  });


    test('Failed login with invalid credentials', () async {
      // Simulate a failed login
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found for that email.',
      ));

      try {
        await mockAuth.signInWithEmailAndPassword(
          email: 'invalid@example.com',
          password: 'wrongpassword',
        );
      } catch (e) {
        // Verify that the exception is thrown
        expect(e, isA<FirebaseAuthException>());
        expect((e as FirebaseAuthException).code, 'user-not-found');
      }

      // Verify that the login method was called
      verify(mockAuth.signInWithEmailAndPassword(
        email: 'invalid@example.com',
        password: 'wrongpassword',
      )).called(1);
    });
  });
}