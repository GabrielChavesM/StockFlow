import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:stockflow/screens/forgot_pw_page.dart';
import 'login_test.mocks.dart';

// Mock do FirebaseAuth
@GenerateMocks([FirebaseAuth])
void main() {
  group('Unit Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
    });

    test('Deve chamar sendPasswordResetEmail com email correto', () async {
      when(mockFirebaseAuth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenAnswer((_) async => Future.value());

      final email = 'test@example.com';

      await mockFirebaseAuth.sendPasswordResetEmail(email: email);

      verify(mockFirebaseAuth.sendPasswordResetEmail(email: email)).called(1);
    });

    test('Deve capturar erro ao chamar sendPasswordResetEmail', () async {
      when(mockFirebaseAuth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenThrow(FirebaseAuthException(code: 'user-not-found', message: 'Usuário não encontrado'));

      try {
        await mockFirebaseAuth.sendPasswordResetEmail(email: 'test@example.com');
      } catch (e) {
        expect(e, isA<FirebaseAuthException>());
        expect((e as FirebaseAuthException).code, 'user-not-found');
      }
    });
  });


  group('Widget Tests', (){

  testWidgets('Verifica se os widgets principais estão na tela', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));

    expect(find.text('Recover your Password!'), findsOneWidget);
    expect(find.text('Enter your email to receive a password reset link'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
  });
});
}
