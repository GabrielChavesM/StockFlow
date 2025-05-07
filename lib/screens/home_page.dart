// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:stockflow/presentation/account_settings_presentation.dart';
import 'package:stockflow/presentation/locations_presentation.dart';
import 'package:stockflow/presentation/notifications_presentation.dart';
import 'package:stockflow/presentation/return_presentation.dart';
import 'package:stockflow/presentation/stock_presentation.dart';
import 'package:stockflow/presentation/warehouse_presentation.dart';
import 'package:stockflow/screens/help_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? userName;

  List<Map<String, dynamic>> options = [];

  final List<String> dailyPhrases = [
    "Have a good day!",
    "Let's work together!",
    "Always smile!",
    "Keep pushing forward!",
    "Believe in yourself!",
    "Today is a new opportunity!",
    "Stay positive and productive!",
    "Make today count!",
    "You are capable of great things!",
    "Embrace the challenge!",
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _initializeOptions(); // Inicializa as opções após o método initState
  }

  // Inicialize as opções com a referência ao método _updateUserName
  void _initializeOptions() {
    options = [
      {'name': 'Products & Stock', 'icon': Icons.inventory, 'page': FilterPage()},
      {'name': 'Stock Locations', 'icon': Icons.business, 'page': LocationsPage()},
      {'name': 'Warehouse Stock', 'icon': Icons.local_shipping, 'page': WarehouseFilteredPage()},
      {'name': 'Stock Brakes', 'icon': Icons.remove_shopping_cart, 'page': ReturnPage()},
      {'name': 'Notifications & Alerts', 'icon': Icons.notifications, 'page': NotificationsPage()},
      {'name': 'Account Settings', 'icon': Icons.settings, 'page': AccountSettingsPage(onNameChanged: _updateUserName)},
      {'name': 'Help', 'icon': Icons.help, 'page': HelpPage()},
      {'name': 'Sign Out', 'icon': Icons.logout, 'page': null},
    ];
  }

  int getDayOfYear(DateTime date) {
    int dayOfYear = 0;
    for (int i = 1; i < date.month; i++) {
      dayOfYear += DateTime(date.year, i + 1, 0).day;
    }
    dayOfYear += date.day;
    return dayOfYear;
  }

  String getDailyPhrase() {
    DateTime now = DateTime.now();
    int dayOfYear = getDayOfYear(now);
    String seed = '${user?.uid}-$dayOfYear';
    var bytes = utf8.encode(seed); // Converte o seed para bytes
    var hash = md5.convert(bytes); // Gera o hash
    int hashValue = hash.bytes.fold(0, (prev, element) => prev + element);
    int randomIndex = hashValue % dailyPhrases.length;
    return dailyPhrases[randomIndex];
  }

  Future<void> _fetchUserName() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? "User";
        });
      }
    }
  }

  void _updateUserName(String newName) {
    setState(() {
      userName = newName;
    });
  }

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 135),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Hello ',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  TextSpan(
                    text: userName ?? "Loading...",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ',',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              getDailyPhrase(),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        if (options[index]['name'] == 'Sign Out') {
                          showCupertinoDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return CupertinoAlertDialog(
                                title: Text('Sign Out'),
                                content: Text('Are you sure you want to sign out?'),
                                actions: <Widget>[
                                  CupertinoDialogAction(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Close the dialog
                                    },
                                  ),
                                  CupertinoDialogAction(
                                    child: Text('Sign Out'),
                                    isDestructiveAction: true, // Highlight as a destructive action
                                    onPressed: () {
                                      FirebaseAuth.instance.signOut();
                                      Navigator.of(context).pop(); // Close the dialog
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => options[index]['page'],
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 1,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 2.0),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    options[index]['icon'],
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    options[index]['name'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

Color hexStringToColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}