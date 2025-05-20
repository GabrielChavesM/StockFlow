// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:stockflow/components/privacy_policy.dart';
import 'package:stockflow/data/account_settings_data.dart';
import 'package:stockflow/domain/account_settings_domain.dart';
import 'package:stockflow/presentation/activity_presentation.dart';
import 'package:stockflow/screens/login_page.dart';

// Presentation Layer
class AccountSettingsPage extends StatefulWidget {
  final Function(String) onNameChanged;

  const AccountSettingsPage({super.key, required this.onNameChanged});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final UserService _userService = UserService(UserRepository());
  String _name = "";
  String _storeNumber = "";
  final String _email = FirebaseAuth.instance.currentUser?.email ?? "";
  final _nameController = TextEditingController();
  final _storeNumberController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _storeNumberController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_userService.currentUser != null) {
      DocumentSnapshot userDoc = await _userService.getUserData();
      if (userDoc.exists) {
        setState(() {
          _name = userDoc['name'] ?? "";
          _storeNumber = userDoc['storeNumber'] ?? "";
          _nameController.text = _name;
          _storeNumberController.text = _storeNumber;
        });
      }
    }
  }

  Future<void> _saveUserData(String name, String storeNumber) async {
    if (_userService.currentUser != null) {
      await _userService.saveUserData(name, storeNumber);
      widget.onNameChanged(name);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      await _userService.sendPasswordResetEmail();
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text('Success'),
            content: Text('Password reset link sent to $_email! Check your email.'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text('Error'),
            content: Text(e.message.toString()),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Account Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              hexStringToColor("CB2B93"),
              hexStringToColor("9546C4"),
              hexStringToColor("5E61F4"),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SizedBox(height: kToolbarHeight * 2),
            _buildOptionButton(
              icon: Icons.person,
              title: 'User Profile',
              subtitle:
                  'Name: ${_name.isNotEmpty ? _name : "Not set"}\nEmail: $_email\nStore Number: ${_storeNumber.isNotEmpty ? _storeNumber : "Not set"}',
              onTap: () {
                _setUserDataDialog(context);
              },
            ),
            _buildOptionButton(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                _confirmPasswordReset(context);
              },
            ),
            _buildOptionButton(
              icon: Icons.history,
              title: 'Activity History',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => LoginLogoutHistoryPage()),
                );
              },
            ),
            _buildOptionButton(
              icon: Icons.feedback,
              title: 'Feedback and Support',
              onTap: () {
                _showFeedbackDialog(context);
              },
            ),
            _buildOptionButton(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                _showPrivacyPolicyDialog(context);
              },
            ),
            _buildOptionButton(
              icon: Icons.delete,
              title: 'Remove Account',
              onTap: () {
                _confirmAccountDeletion(context);
              },
            ),
            _buildOptionButton(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: () {
                _confirmLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setUserDataDialog(BuildContext context) {
    _nameController.text = _name;
    _storeNumberController.text = _storeNumber;

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Update Name or Store Number'),
          content: Column(
            children: [
              SizedBox(height: 16),
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Enter your name',
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                controller: _storeNumberController,
                placeholder: 'Enter your store number',
                keyboardType: TextInputType.number,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            CupertinoDialogAction(
              child: Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                if ((_nameController.text.isNotEmpty &&
                        _nameController.text != _name) ||
                    (_storeNumberController.text.isNotEmpty &&
                        _storeNumberController.text != _storeNumber)) {
                  _saveUserData(
                    _nameController.text.isNotEmpty
                        ? _nameController.text
                        : _name,
                    _storeNumberController.text.isNotEmpty
                        ? _storeNumberController.text
                        : _storeNumber,
                  );
                  setState(() {
                    _name = _nameController.text.isNotEmpty
                        ? _nameController.text
                        : _name;
                    _storeNumber = _storeNumberController.text.isNotEmpty
                        ? _storeNumberController.text
                        : _storeNumber;
                  });
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  _showAlert(
                      'Please fill in at least one field with a new value.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmPasswordReset(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Confirm Password Reset'),
          content: Text(
            'Are you sure you want to send a password reset link to $_email?',
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'Send Reset Email',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _sendPasswordResetEmail();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
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
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Support Email'),
          content: Text('For assistance, please contact: helpstockflow@gmail.com'),
          actions: [
            CupertinoDialogAction(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmAccountDeletion(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) {
        bool isGoogleSignIn = _userService.currentUser!.providerData
            .any((provider) => provider.providerId == "google.com");

        return CupertinoAlertDialog(
          title: Text('Account Deletion Confirmation'),
          content: Column(
            children: [
              if (isGoogleSignIn)
                Text(
                  'Since you are logged in with Google, simply confirm your account to delete it.',
                )
              else ...[
                Text(
                  'Are you sure you want to remove your account? This action cannot be undone.',
                ),
                SizedBox(height: 16),
                CupertinoTextField(
                  controller: emailController,
                  placeholder: 'Re-enter your email',
                ),
                SizedBox(height: 16),
                CupertinoTextField(
                  controller: passwordController,
                  placeholder: 'Enter your password',
                  obscureText: true,
                ),
              ],
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'Remove Account',
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
              onPressed: () async {
                if (isGoogleSignIn) {
                  try {
                    await _userService.reauthenticateWithGoogle();
                    await _userService.deleteUser();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              LoginPage(showRegisterPage: () {})),
                    );
                    _showAlert('Account successfully deleted.');
                  } catch (e) {
                    _showAlert(
                        'An error occurred while reauthenticating with Google. Please try again.');
                  }
                } else {
                  if (emailController.text != _email) {
                    _showAlert('Email does not match. Please try again.');
                  } else if (passwordController.text.isEmpty) {
                    _showAlert('Password field cannot be empty.');
                  } else {
                    try {
                      await _userService.reauthenticateWithEmail(
                          emailController.text, passwordController.text);
                      await _userService.deleteUser();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                LoginPage(showRegisterPage: () {})),
                      );
                      _showAlert('Account successfully deleted.');
                    } on FirebaseAuthException catch (e) {
                      _showAlert(e.message ?? 'Password is incorrect.');
                    }
                  }
                }
              },
            ),
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Logout Confirmation'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            CupertinoDialogAction(
              child: Text(
                'Sign Out',
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
              onPressed: () {
                _userService.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginPage(showRegisterPage: () {}),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

hexStringToColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}
