import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stockflow/screens/home_page.dart';
import 'package:stockflow/screens/login_page.dart';
import 'package:stockflow/screens/register_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomePage();
          } else {
            return LoginPage(showRegisterPage: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterPage(showLoginPage: () {
                  Navigator.pop(context);
                }, signUpCallback: () {  },)),
              );
            });
          }
        },
      ),
    );
  }
}
