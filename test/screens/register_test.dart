/*
// Testes Unitários
- Validação de senha:
Testar se senhas fortes são aceitas e fracas são rejeitadas.
Exemplo: "Senha123!" deve ser válida, enquanto "abc123" deve ser inválida.

- Confirmação de senha
Testar se passwordConfirmed() retorna true quando as senhas coincidem e false quando são diferentes.

- Conversão de cor
Testar se hexStringToColor() converte corretamente um código hexadecimal para Color.

// Testes de Widget
- Exibição do formulário de registro
Verificar se os campos de email, senha e confirmação de senha são renderizados corretamente.

- Visibilidade da senha
Testar se o botão de visibilidade alterna corretamente a exibição da senha.

- Exibição do diálogo da política de privacidade
Testar se o AlertDialog aparece automaticamente ao carregar a tela.

- Redireciona para a tela de login ao não aceitar a política de privacidade
Testar se o botão exibe uma SnackBar impedindo o registro sem aceitar a política.
*/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:stockflow/screens/register_page.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}

@GenerateMocks([FirebaseAuth, UserCredential, User])
void main() {
  group('Unit Tests', () {
    test('Accept Strong Password', () {
      // Senhas fortes
      expect(ValidationUtils.isPasswordStrong('Password123!'), isTrue);
      expect(ValidationUtils.isPasswordStrong('StrongPass1@'), isTrue);
      expect(ValidationUtils.isPasswordStrong('Valid#Password9'), isTrue);
    });

    test('Weak password get rejected', () {
      // Senhas fracas
      expect(ValidationUtils.isPasswordStrong('abc123'), isFalse); // No upper case or special character
      expect(ValidationUtils.isPasswordStrong('12345678'), isFalse); // Only numbers
      expect(ValidationUtils.isPasswordStrong('password'), isFalse); // No numbers or special character
      expect(ValidationUtils.isPasswordStrong('Short1!'), isFalse); // Less than 8 characters
    });
    
    test('Password match', () {
      expect(ValidationUtils.passwordConfirmed('Password123!', 'Password123!'), isTrue);
    });

    test('Password do not match', () {
      expect(ValidationUtils.passwordConfirmed('Password123!', 'Wordpass123!'), isFalse);
    });

    test('Converts Hex to Color correctely', () {
      // Teste com diferentes códigos hexadecimais
      expect(ColorUtils.hexStringToColor("#FFFFFF"), equals(const Color(0xFFFFFFFF))); // White
      expect(ColorUtils.hexStringToColor("#000000"), equals(const Color(0xFF000000))); // Black
      expect(ColorUtils.hexStringToColor("#FF5733"), equals(const Color(0xFFFF5733))); // Orange
      expect(ColorUtils.hexStringToColor("#123456"), equals(const Color(0xFF123456))); // Dark blue
    });

    test('Converts Hex without "#" to Color correctely', () {
      // Teste com códigos hexadecimais sem o símbolo "#"
      expect(ColorUtils.hexStringToColor("FFFFFF"), equals(const Color(0xFFFFFFFF))); // White
      expect(ColorUtils.hexStringToColor("000000"), equals(const Color(0xFF000000))); // Black
      expect(ColorUtils.hexStringToColor("FF5733"), equals(const Color(0xFFFF5733))); // Orange
      expect(ColorUtils.hexStringToColor("123456"), equals(const Color(0xFF123456))); // Dark blue
    });
  });

  group('Widget Tests', () {
    testWidgets('Verify if email and password fields are rendered', (WidgetTester tester) async {
      // Mounts the RegisterPage widget
      await tester.pumpWidget(
        MaterialApp(
          home: RegisterPage(showLoginPage: () {}, signUpCallback: () {  },),
        ),
      );

      // Wait for the initial widgets to load
      await tester.pumpAndSettle();

      // Verify if the email field is present
      expect(find.byType(TextField).at(0), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);

      // Verify if the password field is present
      expect(find.byType(TextField).at(1), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

      // Verify if the confirm password field is present
      expect(find.byType(TextField).at(2), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Confirm Password'), findsOneWidget);
    });
  
    testWidgets('Password visibility test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RegisterPage(showLoginPage: () {}, signUpCallback: () {}),
      ),
    ));

    // Verify if the password field is obscured
    TextField passwordField = tester.widget(find.byKey(Key('passwordField')));
    expect(passwordField.obscureText, isTrue);

    // Press the visibility toggle button
    await tester.tap(find.byKey(Key('togglePasswordVisibility')));
    await tester.pump();

    // Verify if password is visible
    passwordField = tester.widget(find.byKey(Key('passwordField')));
    expect(passwordField.obscureText, isFalse);
  });

  testWidgets('Privacy Policy dialog test', (WidgetTester tester) async {
    // Monta o widget RegisterPage
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(showLoginPage: () {}, signUpCallback: () {}),
      ),
    );

    // Wait for the initial widgets to load
    await tester.pumpAndSettle();

    // Verify if the AlertDialog is displayed automatically
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget); // Verify the dialog title
    expect(find.textContaining('This Privacy Policy describes'), findsWidgets); // Verify the dialog content
  });

  testWidgets('Redirects to login screen when not accepting privacy policy', (WidgetTester tester) async {
    // Variable to check if the login page is shown
    bool loginPageShown = false;

    // Function to set the loginPageShown variable to true
    void showLoginPage() {
      loginPageShown = true;
    }

    // Mounts the RegisterPage widget
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(showLoginPage: showLoginPage, signUpCallback: () {}),
      ),
    );

    // Wait for the initial widgets to load
    await tester.pumpAndSettle();

    // Verify if the AlertDialog is displayed automatically
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget); // Verify the dialog title

    // Press the "I do not agree" button
    await tester.tap(find.text('I do not agree.'));
    await tester.pumpAndSettle();

    // Verify if the login page is shown
    expect(loginPageShown, isTrue);
  });
});
}
