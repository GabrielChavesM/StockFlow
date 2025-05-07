// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    showCupertinoDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog by tapping outside
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Privacy Policy'),
          content: Container(
            height: 300, // Set a fixed height for the scrollable content
            child: CupertinoScrollbar(
              child: SingleChildScrollView(
                child: Text(PrivacyPolicy.privacyPolicyText),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // Closes the pop-up window
                widget.showLoginPage(); // Redirects to the login page
              },
              child: Text('I do not agree.'),
              isDestructiveAction: true, // Highlight as a destructive action
            ),
            CupertinoDialogAction(
              onPressed: () {
                setState(() {
                  _hasAcceptedPolicy = true;
                });
                Navigator.of(context).pop(); // Closes the pop-up window
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
      // Show a Cupertino-style error pop-up if the user has not accepted the privacy policy
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text('Privacy Policy'),
            content: Text('Please accept the Privacy Policy to continue.'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    if (passwordConfirmed()) {
      if (!isPasswordValid(_passwordController.text.trim())) {
        // Show a Cupertino-style error pop-up for invalid password
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text('Invalid Password'),
              content: Text(
                'Password must be at least 8 characters long, include at least one uppercase letter, one number, and one special character.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      try {
        // Register the new user in Firebase
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Verify if the user has verified their email
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          showCupertinoDialog(
            context: context,
            builder: (context) {
              return CupertinoAlertDialog(
                title: Text('Verification Email Sent'),
                content: Text(
                  'A verification email has been sent! Please check your email before logging in.',
                ),
                actions: [
                  CupertinoDialogAction(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        // Handle Firebase-specific errors
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

        // Show a Cupertino-style error pop-up for Firebase errors
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text('Error'),
              content: Text(errorMessage),
              actions: [
                CupertinoDialogAction(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      // Show a Cupertino-style error pop-up for mismatched passwords
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text('Password Mismatch'),
            content: Text('The passwords do not match.'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
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