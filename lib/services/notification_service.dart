import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // Initialize notification service
  static Future<void> initialize() async {
    try {
      // Skip notification setup for web platform
      if (kIsWeb) {
        print('Skipping notification setup for web platform');
        return;
      }

      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('Notification permission granted');

        // Get FCM token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('FCM Token: $token');
          await _saveFCMToken(token);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _saveFCMToken(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleForegroundMessage(message);
        });

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

        // Handle notification tap when app is opened from background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationTap(message);
        });
      } else {
        print('Notification permission denied');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Save FCM token to user's document
  static Future<void> _saveFCMToken(String token) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId != null) {
        await FirebaseFirestore.instance.collection('Users').doc(userId).update(
          {'fcmToken': token, 'lastTokenUpdate': FieldValue.serverTimestamp()},
        );
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');

    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'Thông báo mới',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Received background message: ${message.notification?.title}');

    // Handle background notification
    // This will be called when the app is in the background
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');

    // Navigate to appropriate screen based on notification type
    String? type = message.data['type'];
    String? orderId = message.data['orderId'];

    if (type == 'order_status_update' && orderId != null) {
      // Navigate to order status page
      // You'll need to implement navigation logic here
      print('Navigate to order status for order: $orderId');
    }
  }

  // Show local notification
  static void _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    // For now, we'll just print the notification
    // In a real app, you'd use flutter_local_notifications package
    print('Local Notification: $title - $body');

    // You can implement local notifications using flutter_local_notifications
    // Example implementation:
    /*
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'order_status_channel',
      'Order Status Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
    */
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? fcmToken = userData['fcmToken'];

        if (fcmToken != null) {
          // Send notification via Cloud Functions or your backend
          await _sendFCMNotification(
            token: fcmToken,
            title: title,
            body: body,
            data: data,
          );
        }
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send FCM notification
  static Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // This would typically be done through Cloud Functions
      // For now, we'll just print the notification details
      print('Sending FCM notification:');
      print('Token: $token');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');

      // In a real implementation, you would:
      // 1. Call your Cloud Function or backend API
      // 2. Send the notification to FCM
      // 3. Handle the response

      // Example Cloud Function call:
      /*
      await FirebaseFunctions.instance
          .httpsCallable('sendNotification')
          .call({
        'token': token,
        'title': title,
        'body': body,
        'data': data,
      });
      */
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }

  // Send order status update notification
  static Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String status,
    required String orderNumber,
  }) async {
    String title = 'Cập nhật đơn hàng';
    String body = '';

    switch (status.toLowerCase()) {
      case 'confirmed':
        body = 'Đơn hàng #$orderNumber đã được xác nhận!';
        break;
      case 'preparing':
        body = 'Đơn hàng #$orderNumber đang được chuẩn bị!';
        break;
      case 'delivering':
        body = 'Đơn hàng #$orderNumber đang được giao!';
        break;
      case 'completed':
        body = 'Đơn hàng #$orderNumber đã hoàn thành!';
        break;
      case 'cancelled':
        body = 'Đơn hàng #$orderNumber đã bị hủy!';
        break;
      default:
        body = 'Đơn hàng #$orderNumber có cập nhật mới!';
    }

    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: {
        'type': 'order_status_update',
        'orderId': orderId,
        'status': status,
        'orderNumber': orderNumber,
      },
    );
  }

  // Subscribe to order status updates
  static Future<void> subscribeToOrderUpdates(String orderId) async {
    try {
      // Subscribe to a topic for this specific order
      await _firebaseMessaging.subscribeToTopic('order_$orderId');
      print('Subscribed to order updates: order_$orderId');
    } catch (e) {
      print('Error subscribing to order updates: $e');
    }
  }

  // Unsubscribe from order status updates
  static Future<void> unsubscribeFromOrderUpdates(String orderId) async {
    try {
      // Unsubscribe from the topic
      await _firebaseMessaging.unsubscribeFromTopic('order_$orderId');
      print('Unsubscribed from order updates: order_$orderId');
    } catch (e) {
      print('Error unsubscribing from order updates: $e');
    }
  }

  static Future<void> sendPushNotification(
    String s,
    String t,
    String u,
    Map<String, String> map,
  ) async {}

  static Future<void> sendPromotionNotificationToAllUsers({
    required String promoTitle,
    required String promoDescription,
  }) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('Users').get();
      for (var doc in usersSnapshot.docs) {
        final userId = doc.id;
        await sendNotificationToUser(
          userId: userId,
          title: 'Khuyến mãi mới!',
          body: '$promoTitle: $promoDescription',
          data: {'type': 'promotion'},
        );
      }
    } catch (e) {
      print('Error sending promotion notification to all users: $e');
    }
  }
}
