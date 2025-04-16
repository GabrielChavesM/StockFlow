import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stockflow/auth/main_page.dart';

void main() async { // Continuos access from project to Firebase
  // Gives access to the native code
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}