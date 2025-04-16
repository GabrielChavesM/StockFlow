// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stockflow/components/privacy_policy.dart';

class ValidationUtils {
  /// Verifica se a senha é válida.
  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'\d').hasMatch(password)) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    return true;
  }

  /// Verifica se as senhas coincidem.
  static bool passwordConfirmed(String password, String confirmPassword) {
    return password.trim() == confirmPassword.trim();
  }
}

class ColorUtils {
  /// Converte um código hexadecimal em um objeto Color.
  static Color hexStringToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

// Define the RegisterPage widget
class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage; // Alternate to login page
  final VoidCallback signUpCallback; // Callback to handle sign up

  const RegisterPage({
    super.key, // Unique widget identifier from the three
    required this.showLoginPage,
    required this.signUpCallback,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState(); // Create the state and update the register page
}

class _RegisterPageState extends State<RegisterPage> {
  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Variables to toggle password visibility
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Track if the user has accepted the policy
  bool _hasAcceptedPolicy = false;

  @override
  void initState() {
    super.initState();
    // Show the privacy policy dialog when the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPrivacyPolicyDialog();
    });
  }

  // Liberate the data from memory, avoiding data leaks
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog by tapping outside
      builder: (context) {
        return AlertDialog(
          title: Text('Privacy Policy'),
          content: SingleChildScrollView(
            child: Text(PrivacyPolicy.privacyPolicyText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Closes the pop up window
                widget.showLoginPage(); // Redirects to the login page
              },
              child: Text('I do not agree.'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _hasAcceptedPolicy = true;
                });
                Navigator.of(context).pop(); // Closes the pop up window
              },
              child: Text('I read it and agree.'),
            ),
          ],
        );
      },
    );
  }

  bool isPasswordValid(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'\d').hasMatch(password)) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    return true;
  }
  
  // Register a new user on the database
  Future<void> signUp() async {
    if (!_hasAcceptedPolicy) {
      // Display message if user has not yet accepted the privacy policy
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please accept the Privacy Policy to continue.')),
      );
      return;
    }

    if (passwordConfirmed()) {
      if (!isPasswordValid(_passwordController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password must be at least 8 characters long, include at least one uppercase letter, one number, and one special character.')),
        );
        return;
      }

      try {
        // Put the new user in the database
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Verify if the user already verified the email, if verified it can login
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification email sent! Please check your email before logging in.')),
          );
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        // Catches and show specific errors to the user
        String errorMessage = 'An error occurred. Please check your connection and try again.';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'This email is already in use. Please use another email.';
              break;
            case 'invalid-email':
              errorMessage = 'The email address is not valid. Please enter a valid email.';
              break;
            case 'weak-password':
              errorMessage = 'The password is too weak. Please use a stronger password.';
              break;
            case 'operation-not-allowed':
              errorMessage = 'Signing up with email and password is disabled. Please contact support.';
              break;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The passwords do not match.')),
      );
    }
  }

  bool passwordConfirmed() {
    return _passwordController.text.trim() == _confirmPasswordController.text.trim();
  }

  hexStringToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Build the app visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("CB2B93"),
              hexStringToColor("9546C4"),
              hexStringToColor("5E61F4"),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('lib/images/icon.png', width: 100, height: 100, fit: BoxFit.cover),
                  SizedBox(height: 75),
                  Text('New on the app?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 36)),
                  SizedBox(height: 10),
                  Text('Register below!', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextField(controller: _emailController, decoration: InputDecoration(border: InputBorder.none, hintText: 'Email')),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextField(
                          key: Key('passwordField'), // Adiciona a chave ao campo de senha
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              key: Key('togglePasswordVisibility'), // Adiciona a chave ao botão de visibilidade
                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextField(
                          key: Key('confirmPasswordField'),
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Confirm Password',
                            suffixIcon: IconButton(
                              key: Key('toggleConfirmPasswordVisibility'),
                              icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Text(
                      'Password must contain at least: 8 characters, 1 uppercase letter, 1 number, and 1 special character (!@#\$%^&*).',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: GestureDetector(
                      onTap: signUp,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text(
                            'Sign Up',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('I am a member!', style: TextStyle(fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: widget.showLoginPage,
                        child: Text(
                          ' Sign In now!',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}