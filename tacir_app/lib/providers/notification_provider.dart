import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('notifications') ?? [];
    _notifications =
        data.map((e) => AppNotification.fromJson(jsonDecode(e))).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications = [];
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList('notifications', data);
  }
}
