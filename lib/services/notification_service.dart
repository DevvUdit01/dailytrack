// ignore_for_file: depend_on_referenced_packages

import 'package:dailytrack/pages/notified_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/model/task.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:awesome_notifications/awesome_notifications.dart';

class NotifyHelper {

  // Initialize AwesomeNotifications and Timezone data
  Future<void> initializeNotification() async {
    tz.initializeTimeZones();  // Initialize timezone data

    AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher',  // Replace with your app icon.
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic notifications',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
        ),
      ],
    );

    // Request notification permission
    await _requestNotificationPermission();
  }

  // Handle background notifications
  @pragma('vm:entry-point')
  static void notificationTapBackground(ReceivedNotification details) {
    debugPrint("Background notification tapped: ${details.payload}");
  }

  // Select notification to navigate or perform an action
  Future<void> selectNotification(String? payload) async {
    if (payload != null) {
      print('Notification payload: $payload');
    } else {
      print("Notification Done");
    }
    if (payload == "Theme Changed") {
      print("Nothing to navigate to");
    } else {
      Get.to(() => NotifiedPage(label: payload!));
    }
  }

  // Display simple notification
  Future<void> displayNotification({required String title, required String body}) async {
    print("Displaying notification...");

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        payload: {"title": title, "body": body},
      ),
    );
  }

// Updated scheduled notification method for IST
Future<void> scheduledNotification(int hour, int minute, Task task, {bool weekly = false, bool monthly = false, bool oneTime = false}) async {
  // Convert the provided hour and minute to a TZDateTime in the local timezone
  tz.TZDateTime scheduledTime = _convertTime(hour, minute);
  int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

  bool repeats = false;

  if (oneTime) {
    // One-time notification (no repeats)
    repeats = false;
  } else if (weekly) {
    // Weekly notification (repeat every 7 days)
    repeats = true;
  } else if (monthly) {
    // Monthly notification (repeat every month)
    repeats = true;
  } else {
    // Daily notification (repeat every day)
    repeats = true;
  }

  // Schedule the notification
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: notificationId,
      channelKey: 'basic_channel',
      title: task.title,
      body: task.note,
      notificationLayout: NotificationLayout.Default,
      payload: {
        "title": task.title,
        "body": task.note,
      },
    ),
    schedule: NotificationCalendar(
      year: scheduledTime.year,
      month: scheduledTime.month,
      day: scheduledTime.day,
      hour: scheduledTime.hour,
      minute: scheduledTime.minute,
      second: scheduledTime.second,
      repeats: repeats,
      allowWhileIdle: true,
    ),
  );

  print("Scheduled notification set for: $scheduledTime with repeat: ${task.repeat}");
}

  // Helper function to convert time (if needed)
// Helper function to convert time (if needed)
tz.TZDateTime _convertTime(int hour, int minutes) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local); // Use local timezone
  tz.TZDateTime scheduleDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minutes);

  // If the scheduled time is before the current time, schedule it for the next day
  if (scheduleDate.isBefore(now)) {
    scheduleDate = scheduleDate.add(const Duration(days: 1));
  }

  // Debugging output
  print("Scheduled time (local): ${scheduleDate.toLocal()}");

  return scheduleDate;
}

  // Request notification permission
  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isGranted) {
      print("Notification permission granted.");
    } else {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        print("Notification permission granted after request.");
      } else {
        print("Notification permission denied.");
      }
    }
  }

  // Check pending notifications
  Future<void> checkPendingNotifications() async {
    var pendingNotifications = await AwesomeNotifications().listScheduledNotifications();

    print("🔔 Pending Notifications: ${pendingNotifications.length}");

    for (var notification in pendingNotifications) {
      print("📌 Notification: ID: ${notification.content?.id}, Title: ${notification.content?.title}, Body: ${notification.content?.body}, Payload: ${notification.content?.payload}");
    }

    // If needed, cancel pending notifications
    // await AwesomeNotifications().cancelAll();
    // print("✅ All scheduled notifications cleared!");
  }

}









 // Scheduled notification
  // Future<void> scheduledNotification() async {
  //   DateTime localTime = DateTime.now().add(Duration(seconds: 5));
  //   AwesomeNotifications().createNotification(
  //     content: NotificationContent(
  //       id: 0,
  //       channelKey: 'basic_channel',
  //       title: 'Scheduled title',
  //       body: 'Theme changes 5 seconds ago',
  //       notificationLayout: NotificationLayout.Default,
  //       payload: {"title": "Scheduled title", "body": "Theme changes 5 seconds ago"},
  //     ),
  //     schedule: NotificationCalendar(
  //       year: localTime.year,
  //       month: localTime.month,
  //       day: localTime.day,
  //       hour: localTime.hour,
  //       minute: localTime.minute,
  //       second: localTime.second,
  //       repeats: false,  
  //       allowWhileIdle: true,  // One-time notification
  //     ),
  //   );
  //   print("Scheduled notification set for: $localTime");
  // }
