import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tacir_app/providers/auth_provider.dart';
import 'package:tacir_app/providers/events_provider.dart';
import '../model/app_notification.dart';
import '../providers/notification_provider.dart';
import 'api_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  Future<void> initialize(String userId, BuildContext context) async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _fcm.getToken();
      print('🔥 FCM Token: $token');

      if (token != null && userId.isNotEmpty) {
        await _apiService.saveFcmToken(userId, token);
      }

      // Notification reçue quand l'app est ouverte → sauvegarder in-app
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notif = AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: message.notification?.title ?? 'Notification',
          body: message.notification?.body ?? '',
          date: DateTime.now(),
          eventId: message.data['eventId'],
          eventType: message.data['eventType'],
        );

        if (context.mounted) {
          await context.read<NotificationProvider>().addNotification(notif);

          // ← Rafraîchir le calendrier automatiquement
          final auth = context.read<AuthProvider>();
          await context.read<EventsProvider>().fetchEvents(
            auth.userRole ?? '',
            auth.regionId,
          );
        }
      });

      _fcm.onTokenRefresh.listen((newToken) async {
        await _apiService.saveFcmToken(userId, newToken);
      });
    }
  }
}
