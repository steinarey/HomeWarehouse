import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> checkAndShowNotifications() async {
    try {
      // We need to create a fresh ApiClient here because this might run in a background isolate
      // where Riverpod providers are not available in the same way.
      // However, for simplicity in this "Hybrid" approach, we'll assume we can access SharedPreferences.

      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url');
      final token = prefs.getString('auth_token');

      if (baseUrl == null || token == null) {
        print('NotificationService: Missing base_url or auth_token');
        return;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      // Call the new endpoint directly using Dio since ApiClient wraps it but we need manual Dio setup here
      final response = await dio.get('/notifications/pending');

      if (response.statusCode == 200) {
        final List<dynamic> pending = response.data;

        for (var item in pending) {
          final categoryName = item['category_name'];
          final daysElapsed = item['days_elapsed'];
          final consumptionRate = item['consumption_rate'];

          await _showNotification(
            id: item['category_id'],
            title: 'Restock Needed: $categoryName',
            body:
                'It has been $daysElapsed days since last restock. Usual rate is $consumptionRate days.',
          );
        }
      }
    } catch (e) {
      print('NotificationService: Error checking notifications: $e');
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'restock_channel',
          'Restock Notifications',
          channelDescription: 'Notifications for items needing restock',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
