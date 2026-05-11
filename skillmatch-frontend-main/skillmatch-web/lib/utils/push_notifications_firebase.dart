import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillmatch_platform/main.dart';
import 'package:skillmatch_platform/services/job_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/jobs_screen_tabs/job_details_screen.dart';

class PushNotificationsFirebase {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final _logger = Logger();
  //late JobService=>JobService(token: token);
  static late JobService jobService;
  static Future<void> initializeJobService(String token) async {
    jobService = JobService(token: token);
  }

  static Future init() async {
    // req permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: null,
          macOS: null,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final Map<String, dynamic> data = jsonDecode(response.payload!);
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token') ?? 'defaultToken';

          await initializeJobService(token);

          if (data['type'] == 'chat') {
            final Map<String, String> arguments = data.map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            );
            arguments['token'] = token;
            navigatorKey.currentState?.pushNamed('/chat', arguments: arguments);
          }

          if (data['type'] == 'job') {
            try {
              if (data['jobId'] == null) {
                _logger.e('Job ID is missing in notification data');
                return;
              }

              final job = await jobService.fetchJobById(
                data['jobId'].toString(),
              );

              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder:
                      (context) => JobDetailsScreen(job: job, token: token),
                ),
              );
            } catch (e) {
              _logger.e('Error handling job notification', error: e);
              // Show user-friendly error instead of crashing
              if (navigatorKey.currentContext != null) {
                ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to load job details. Please check your connection and try again.',
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          }

          if (data['type'] == 'meeting') {
            // Navigate to a MeetingDetailsScreen or show alert dialog
            showDialog(
              context: navigatorKey.currentContext!,
              builder:
                  (context) => AlertDialog(
                    title: Text("Meeting Scheduled"),
                    content: Text(
                      "You have a meeting with ${data['title']} at ${data['scheduledDateTime']}",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("OK"),
                      ),
                    ],
                  ),
            );
          }
          if (data['type'] == 'application') {
            try {
              if (data['jobId'] == null) {
                _logger.e('Job ID is missing in application notification data');
                return;
              }

              // Fetch the job details
              final job = await jobService.fetchJobById(
                data['jobId'].toString(),
              );

              // Show a dialog with application details and options
              showDialog(
                context: navigatorKey.currentContext!,
                builder:
                    (context) => AlertDialog(
                      title: Text("New Job Application"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${data['applicantName']} has applied for:"),
                          SizedBox(height: 8),
                          Text(
                            data['jobTitle'] ?? 'Unknown job',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Would you like to view the application details?",
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("Later"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Navigate to application details screen
                            // navigatorKey.currentState?.push(
                            // MaterialPageRoute(
                            //   builder: (context) => ApplicationDetailsScreen(
                            //     job: job,
                            //     applicantUsername: data['applicantUsername'] ?? '',
                            //     applicantName: data['applicantName'] ?? '',
                            //     token: token,
                            //   ),
                            // ),
                            // );
                          },
                          child: Text("View Details"),
                        ),
                      ],
                    ),
              );
            } catch (e) {
              _logger.e('Error handling application notification', error: e);
              // Show user-friendly error instead of crashing
              if (navigatorKey.currentContext != null) {
                ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to load application details. Please check your connection and try again.',
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          }
        }
      },
    );
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      _logger.i('Notification opened: ${message.data}');

      if (message.data['type'] == 'chat') {
        navigatorKey.currentState?.pushNamed(
          '/chat',
          arguments: {
            'currentUserId': message.data['currentUserId'],
            'peerUserId': message.data['senderId'],
            'peerUsername': message.data['peerUsername'],
            'currentuserAvatarUrl': message.data['currentuserAvatarUrl'],
            'token': message.data['token'],
          },
        );
      }

      if (message.data['type'] == 'job') {
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token') ?? 'defaultToken';
          await initializeJobService(token);

          if (message.data['jobId'] == null) {
            _logger.e('Job ID is missing in notification data');
            return;
          }

          final job = await jobService.fetchJobById(
            message.data['jobId'].toString(),
          );

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => JobDetailsScreen(job: job, token: token),
            ),
          );
        } catch (e) {
          _logger.e(
            'Error handling job notification from opened app',
            error: e,
          );
          // Show user-friendly error instead of crashing
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text(
                  'Unable to load job details. Please check your connection and try again.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    });

    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleTerminatedMessage(initialMessage);
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.i('Got a message whilst in the foreground!');
    _logger.i('Message data:', error: message.data);

    if (message.notification != null) {
      _logger.i(
        'Message also contained a notification:',
        error: message.notification,
      );

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'chat_messages', //
            'Chat Messages',
            channelDescription: 'Incoming chat messages',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title,
        message.notification?.body,
        platformChannelSpecifics,
        payload: jsonEncode(message.data),
      );
    }
  }

  static void handleBackgroundMessage(RemoteMessage message) {
    _logger.i('Got a message whilst in the background!');
    _logger.i('Message data:', error: message.data);

    if (message.data['type'] == 'chat') {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'chat_messages',
            'Chat Messages',
            channelDescription: 'Incoming chat messages',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      _flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title,
        message.notification?.body,
        platformChannelSpecifics,
        payload: jsonEncode(message.data),
      );
    }

    if (message.data['type'] == 'job') {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'chat_messages',
            'Chat Messages',
            channelDescription: 'Incoming chat messages',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      _flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title,
        message.notification?.body,
        platformChannelSpecifics,
        payload: jsonEncode(message.data),
      );
    }
  }

  static void _handleTerminatedMessage(RemoteMessage message) {
    _logger.i('Got a message whilst app was terminated!');
    _logger.i('Message data:', error: message.data);

    handleBackgroundMessage(message);
  }

  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    PushNotificationsFirebase.handleBackgroundMessage(message);
  }
}
