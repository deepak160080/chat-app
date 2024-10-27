import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final String serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // Get this from Firebase Console
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initialize() {
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      ),
    );

    _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> saveUserFCMToken(String userId) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'fcmToken': fcmToken});
  }

  Future<void> sendNotification({
    required String recipientToken,
    required String senderName,
    required String message,
  }) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'notification': {
            'title': senderName,
            'body': message,
            'sound': 'default',
          },
          'priority': 'high',
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'type': 'message',
          },
          'to': recipientToken,
        }),
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'virtualhelp_chat_channel',
      'Chat Notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        sound: 'notification_sound.aiff',
      ),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }
}
