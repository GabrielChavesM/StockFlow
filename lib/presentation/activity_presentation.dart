// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/activity_domain.dart';
import '../data/activity_data.dart';

// Presentation Layer
class LoginLogoutHistoryPage extends StatefulWidget {
  const LoginLogoutHistoryPage({super.key});

  @override
  _LoginLogoutHistoryPageState createState() => _LoginLogoutHistoryPageState();
}

class _LoginLogoutHistoryPageState extends State<LoginLogoutHistoryPage> {
  final ActivityService _activityService = ActivityService(ActivityRepository());
  User? user;
  List<Map<String, dynamic>> _activityHistory = [];
  bool isLoading = true;
  bool hasMarkedEntryToday = false;
  bool hasMarkedExitToday = false;

  @override
  void initState() {
    super.initState();
    _checkUserAndFetchActivityHistory();
  }

  Future<void> _checkUserAndFetchActivityHistory() async {
    user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return; // Exit if no user is logged in
    }

    await _fetchActivityHistory();
  }

  Future<void> _fetchActivityHistory() async {
    if (user == null) return;
    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(Duration(days: 7));

    try {
      DocumentSnapshot userDoc = await _activityService.getUserDocument(user!.uid);
      String userName = userDoc['name'] ?? 'No Name';

      QuerySnapshot querySnapshot = await _activityService.getUserActivity(user!.uid, sevenDaysAgo);

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, List<Map<String, dynamic>>> groupedActivities = {};

        for (var doc in querySnapshot.docs) {
          Timestamp timestamp = doc['timestamp'];
          String action = doc['action'];
          DateTime activityDate = timestamp.toDate();
          String dateKey = DateFormat('yyyy-MM-dd').format(activityDate);

          if (!groupedActivities.containsKey(dateKey)) {
            groupedActivities[dateKey] = [];
          }

          groupedActivities[dateKey]!.add({
            'action': action,
            'date': activityDate,
            'userName': userName,
          });
        }

        setState(() {
          _activityHistory = groupedActivities.entries.map((entry) {
            return {
              'date': entry.key,
              'activities': entry.value,
            };
          }).toList();

          DateTime today = DateTime.now();
          String todayKey = DateFormat('yyyy-MM-dd').format(today);

          hasMarkedEntryToday = _activityHistory.any((dayEntry) =>
              dayEntry['date'] == todayKey &&
              dayEntry['activities'].any((activity) => activity['action'] == 'Entry Marked'));

          hasMarkedExitToday = _activityHistory.any((dayEntry) =>
              dayEntry['date'] == todayKey &&
              dayEntry['activities'].any((activity) => activity['action'] == 'Exit Marked'));
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching activity history: $e");
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(content: Text(message)),
    );
  }

  Future<void> _markEntry() async {
    if (hasMarkedEntryToday) {
      _showAlert('You have already marked entry for today.');
      return;
    }

    await _activityService.logUserActivity(user!.uid, 'Entry Marked');
    await _fetchActivityHistory();
  }

  Future<void> _markExit() async {
    if (hasMarkedExitToday) {
      _showAlert('You have already marked exit for today.');
      return;
    }

    if (!hasMarkedEntryToday) {
      _showAlert('You must mark entry before marking exit.');
      return;
    }

    await _activityService.logUserActivity(user!.uid, 'Exit Marked');
    await _fetchActivityHistory();
  }

  Color hexStringToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Permite que o AppBar fique sobre o fundo do Scaffold
      backgroundColor: Colors.transparent, // Fundo transparente
      appBar: AppBar(
        title: Text('Entry and Exit Logger', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey), // Muda a cor do botão de voltar para branco
      ),
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
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: _activityHistory.isEmpty
                        ? Center(child: Text('No activity history found.'))
                        : ListView.builder(
                            itemCount: _activityHistory.length,
                            itemBuilder: (context, index) {
                              String activityDate = _activityHistory[index]['date'];
                              List<Map<String, dynamic>> activities = _activityHistory[index]['activities'];

                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${DateFormat('EEEE, dd/MM/yyyy').format(DateTime.parse(activityDate))} - ${activities.isNotEmpty ? activities[0]['userName'] : ''}',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      ...activities.map((activity) {
                                        return ListTile(
                                          title: Text(activity['action']),
                                          subtitle: Text(DateFormat('HH:mm').format(activity['date'])),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6),
                    child: GestureDetector(
                      onTap: hasMarkedEntryToday ? null : _markEntry,
                      child: Opacity(
                        opacity: hasMarkedEntryToday ? 0.5 : 1.0,
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Mark Entry',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6),
                    child: GestureDetector(
                      onTap: hasMarkedExitToday ? null : _markExit,
                      child: Opacity(
                        opacity: hasMarkedExitToday || !hasMarkedEntryToday ? 0.5 : 1.0,
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Mark Exit',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20)
                ],
              ),
      ),
    );
  }
}