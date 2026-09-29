import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/orders/domain/order_model.dart';
import '../cache/cache_manager.dart';

/// Service managing active order live tracking both in-app (Dynamic Island)
/// and system-level (Android ongoing progress notification for HyperOS Super Island).
class LiveOrderTrackingService extends ChangeNotifier {
  static final LiveOrderTrackingService instance = LiveOrderTrackingService._internal();
  factory LiveOrderTrackingService() => instance;

  LiveOrderTrackingService._internal() {
    _initNotifications();
  }

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isNotificationInitialized = false;

  OrderModel? _activeOrder;
  OrderModel? get activeOrder => _activeOrder;
  bool get hasActiveOrder => _activeOrder != null;

  int _remainingMinutes = 20;
  int get remainingMinutes => _remainingMinutes;

  String _currentStatus = 'Placed';
  String get currentStatus => _currentStatus;

  bool _isDynamicIslandEnabled = CacheManager.isDynamicIslandEnabled();
  bool get isDynamicIslandEnabled => _isDynamicIslandEnabled;

  void setDynamicIslandEnabled(bool value) {
    _isDynamicIslandEnabled = value;
    CacheManager.setDynamicIslandEnabled(value);
    notifyListeners();
  }

  Timer? _countdownTimer;
  Timer? _stageTimer;
  static const int _notificationId = 9901;

  double get progressPercentage {
    switch (_currentStatus.toLowerCase()) {
      case 'placed':
        return 0.25;
      case 'processing':
      case 'preparing':
        return 0.55;
      case 'dispatched':
      case 'shipped':
      case 'out for delivery':
        return 0.85;
      case 'delivered':
        return 1.0;
      default:
        return 0.25;
    }
  }

  Future<void> _initNotifications() async {
    if (kIsWeb) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notificationsPlugin.initialize(settings: initSettings);

      // Request notification permission on Android 13+
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlatform?.requestNotificationsPermission();
      _isNotificationInitialized = true;
    } catch (e) {
      debugPrint('⚠️ Local notification init notice: $e');
    }
  }

  /// Starts live tracking for an order.
  void startTracking(OrderModel order) {
    if (order.status.toLowerCase() == 'delivered' || order.status.toLowerCase() == 'cancelled') {
      return;
    }

    _activeOrder = order;
    _currentStatus = order.status;
    _remainingMinutes = 22;
    notifyListeners();

    _countdownTimer?.cancel();
    // Decrement countdown every minute
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_remainingMinutes > 1) {
        _remainingMinutes--;
        notifyListeners();
        _updateSystemOngoingNotification();
      }
    });

    // Auto-advance stages simulation if not updated by backend
    _startStageProgression();
    _updateSystemOngoingNotification();
  }

  void _startStageProgression() {
    _stageTimer?.cancel();
    // Advance Placed -> Processing after 45 seconds
    _stageTimer = Timer(const Duration(seconds: 45), () {
      if (_activeOrder != null && _currentStatus == 'Placed') {
        updateStatus('Processing', etaMinutes: 18);
        // Advance Processing -> Dispatched after another 60 seconds
        _stageTimer = Timer(const Duration(seconds: 60), () {
          if (_activeOrder != null && _currentStatus == 'Processing') {
            updateStatus('Dispatched', etaMinutes: 12);
          }
        });
      }
    });
  }

  /// Updates the order status and syncs both In-App Dynamic Island and HyperOS Notification.
  void updateStatus(String status, {int? etaMinutes}) {
    if (_activeOrder == null) return;
    _currentStatus = status;
    if (etaMinutes != null) {
      _remainingMinutes = etaMinutes;
    }
    notifyListeners();

    if (status.toLowerCase() == 'delivered') {
      stopTracking(isDelivered: true);
    } else {
      _updateSystemOngoingNotification();
    }
  }

  /// Broadcasts the ongoing Android notification.
  /// HyperOS picks this up and promotes it to the camera punch-hole Super Island!
  Future<void> _updateSystemOngoingNotification() async {
    if (kIsWeb || !_isNotificationInitialized || _activeOrder == null) return;

    try {
      final progress = (progressPercentage * 100).toInt();
      final orderShortId = _activeOrder!.id.length > 5
          ? _activeOrder!.id.substring(_activeOrder!.id.length - 5)
          : _activeOrder!.id;

      final androidDetails = AndroidNotificationDetails(
        'vytra_order_tracking',
        'Active Deliveries',
        channelDescription: 'Real-time order progress and delivery countdown',
        importance: Importance.max,
        priority: Priority.max,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        category: AndroidNotificationCategory.progress,
        color: const Color(0xFF38240D),
        subText: '$_remainingMinutes mins left',
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id: _notificationId,
        title: 'Order #$orderShortId • ${_getStatusHeader(_currentStatus)}',
        body: 'Arriving in ~$_remainingMinutes mins ($_currentStatus)',
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('⚠️ Error posting HyperOS tracking notification: $e');
    }
  }

  String _getStatusHeader(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'Order Confirmed';
      case 'processing':
        return 'Store Preparing';
      case 'dispatched':
      case 'shipped':
        return 'Out for Delivery 🛵';
      case 'delivered':
        return 'Order Delivered! 🎉';
      default:
        return 'In Progress';
    }
  }

  /// Stops tracking and dismisses the ongoing notifications.
  Future<void> stopTracking({bool isDelivered = false}) async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _stageTimer?.cancel();
    _stageTimer = null;

    if (isDelivered) {
      _currentStatus = 'Delivered';
      _remainingMinutes = 0;
      notifyListeners();

      if (!kIsWeb && _isNotificationInitialized) {
        try {
          await _notificationsPlugin.cancel(id: _notificationId);

          const deliveredDetails = AndroidNotificationDetails(
            'vytra_order_tracking',
            'Active Deliveries',
            importance: Importance.high,
            priority: Priority.high,
            ongoing: false,
            autoCancel: true,
          );
          await _notificationsPlugin.show(
            id: _notificationId + 1,
            title: 'Order Delivered! 🎉',
            body: 'Your Vytra delivery has safely arrived. Enjoy!',
            notificationDetails: const NotificationDetails(android: deliveredDetails),
          );
        } catch (_) {}
      }

      // Allow 4 seconds for celebratory in-app display before collapsing
      await Future.delayed(const Duration(seconds: 4));
    } else {
      if (!kIsWeb && _isNotificationInitialized) {
        try {
          await _notificationsPlugin.cancel(id: _notificationId);
        } catch (_) {}
      }
    }

    _activeOrder = null;
    notifyListeners();
  }
}
