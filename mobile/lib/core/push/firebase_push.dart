import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'push.dart';

/// Push notifications through Firebase Cloud Messaging (Android).
/// - app closed or in the background: Android shows the notification itself
/// - app open: Firebase stays quiet, so we show it with flutter_local_notifications
class FirebasePush implements PushPlatform {
  final _local = FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  // Android lists these under Settings → Apps → Nirmal Mart → Notifications, so people can mute one
  static const _orders = AndroidNotificationChannel(
    'orders',
    'Order updates',
    description: 'Payment, shipping, delivery, refunds and returns',
    importance: Importance.high,
  );
  static const _offers = AndroidNotificationChannel(
    'offers',
    'Offers & deals',
    description: 'Sales and new arrivals from Nirmal Mart',
    importance: Importance.defaultImportance,
  );

  bool _started = false;

  @override
  Future<void> start({required void Function(String route) onOpen}) async {
    if (_started) return;
    await Firebase.initializeApp(options: firebaseOptions);
    _started = true; // Firebase is ready: token() and tokenRefresh can use it from here
    await _local.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_notification')),
      onDidReceiveNotificationResponse: (r) => onOpen(r.payload ?? '/'),
    );
    await _android?.createNotificationChannel(_orders);
    await _android?.createNotificationChannel(_offers);

    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n == null) return;
      final channel = n.android?.channelId == _offers.id ? _offers : _orders;
      _local.show(
        id: (n.android?.tag ?? m.messageId ?? '${DateTime.now().microsecondsSinceEpoch}').hashCode & 0x7fffffff,
        title: n.title,
        body: n.body,
        payload: m.data['route'] as String? ?? '/',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: channel.importance,
            priority: channel == _orders ? Priority.high : Priority.defaultPriority,
            icon: '@drawable/ic_notification',
            color: const Color(0xFF317239),
          ),
        ),
      );
    });
    // tapped while the app was in the background
    FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen(m.data['route'] as String? ?? '/'));
    // tapped while the app was closed: it starts on that page
    final first = await FirebaseMessaging.instance.getInitialMessage();
    if (first != null) {
      onOpen(first.data['route'] as String? ?? '/');
    } else {
      final launch = await _local.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) && payload != null) onOpen(payload);
    }
  }

  @override
  Future<String?> token() async {
    if (!_started) return null;
    try {
      // The classic FCM registration token: what the server's HTTP v1 send API takes.
      // (The newer register()/onRegistered installation IDs need a different server API.)
      // ignore: deprecated_member_use
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null; // offline, or Google Play services missing
    }
  }

  @override
  // ignore: deprecated_member_use
  Stream<String> get tokenRefresh => _started ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  @override
  Future<bool> allowed() async => await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<bool> ask() async => await _android?.requestNotificationsPermission() ?? false;
}
