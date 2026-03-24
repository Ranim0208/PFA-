import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  Future<void> initialize(String userId) async {
    // Demander la permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Récupérer le token FCM
      final token = await _fcm.getToken();
      if (token != null && userId.isNotEmpty) {
        await _apiService.saveFcmToken(userId, token);
      }

      // Notification reçue quand l'app est ouverte
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showInAppNotification(message);
      });

      // Token refreshed
      _fcm.onTokenRefresh.listen((newToken) async {
        await _apiService.saveFcmToken(userId, newToken);
      });
    }
  }

  void _showInAppNotification(RemoteMessage message) {
    // Cette fonction sera appelée depuis le contexte
    debugPrint('📬 Notification reçue: ${message.notification?.title}');
  }
}
