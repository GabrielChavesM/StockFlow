// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/notifications_domain.dart';
import '../data/notifications_data.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService(NotificationRepository());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey),
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
        child: FutureBuilder<String?>(
          future: notificationService.getUserStoreNumber(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text(
                  'Failed to fetch user storeNumber.',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              );
            }

            final storeNumber = snapshot.data!;
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: notificationService.fetchNotificationsStream(storeNumber),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error fetching notifications.',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notifications available.',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final notificationType = notification['notificationType'] ?? 'Default';

                    // Determine icon and color
                    IconData iconData;
                    Color iconColor;
                    switch (notificationType) {
                      case 'Order':
                        iconData = Icons.add_box;
                        iconColor = const Color.fromARGB(255, 25, 105, 170);
                        break;
                      case 'Update':
                        iconData = Icons.inventory_2;
                        iconColor = const Color.fromARGB(255, 23, 143, 27);
                        break;
                      case 'Transfer':
                        iconData = Icons.swap_horiz;
                        iconColor = const Color.fromARGB(255, 131, 6, 153);
                        break;
                      case 'UpdatePrice':
                        iconData = Icons.attach_money;
                        iconColor = const Color.fromARGB(255, 255, 115, 0);
                        break;
                      case 'Create':
                        iconData = Icons.fiber_new;
                        iconColor = Colors.black;
                        break;
                      case 'Edit':
                        iconData = Icons.edit;
                        iconColor = const Color.fromARGB(255, 221, 199, 0);
                        break;
                      case 'Meeting':
                        iconData = Icons.timelapse_sharp;
                        iconColor = const Color.fromARGB(255, 3, 12, 138);
                        break;
                      case 'Warning':
                        iconData = Icons.warning;
                        iconColor = const Color.fromARGB(255, 141, 128, 9);
                        break;
                      case 'Schedule':
                        iconData = Icons.schedule;
                        iconColor = const Color.fromARGB(255, 0, 0, 0);
                        break;
                      default:
                        iconData = Icons.notification_important;
                        iconColor = Colors.red;
                        break;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.5),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification['message'] ?? 'No message',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    notification['timestamp'] != null
                                        ? notificationService.getTimeAgo((notification['timestamp'] as Timestamp).toDate())
                                        : 'No timestamp',
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      Icon(iconData, color: iconColor, size: 20.0),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        notificationType,
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white,
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
                  },
                );
              },
            );
          },
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