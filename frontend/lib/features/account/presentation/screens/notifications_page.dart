import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system.dart';

class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconColor;
  bool isRead;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _orderUpdates = true;
  bool _offers = true;
  bool _deliveryAlerts = false;

  final List<NotificationMessage> _notifications = [
    NotificationMessage(
      id: '1',
      title: 'Order Delivered!',
      body: 'Your order #OD9238472934 from Fresh Mart has been successfully delivered.',
      time: '2 hours ago',
      icon: Icons.local_shipping_rounded,
      iconColor: AppColors.freshGreen,
      isRead: false,
    ),
    NotificationMessage(
      id: '2',
      title: '20% OFF Weekly Coupon',
      body: 'Use code LOCAL20 at checkout to get a flat 20% discount on all groceries.',
      time: '1 day ago',
      icon: Icons.local_offer_rounded,
      iconColor: AppColors.primary,
      isRead: true,
    ),
    NotificationMessage(
      id: '3',
      title: 'Welcome to Local Commerce!',
      body: 'Your account is active. Start exploring top local shops near you.',
      time: '3 days ago',
      icon: Icons.celebration_rounded,
      iconColor: AppColors.citrusOrange,
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Read All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PREFERENCES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _orderUpdates,
                    onChanged: (v) => setState(() => _orderUpdates = v),
                    title: const Text('Order Updates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: const Text('Get alerts about your order status changes', style: TextStyle(fontSize: 11)),
                    activeColor: AppColors.primary,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _offers,
                    onChanged: (v) => setState(() => _offers = v),
                    title: const Text('Promotional Offers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: const Text('Receive coupons, discounts, and deals', style: TextStyle(fontSize: 11)),
                    activeColor: AppColors.primary,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _deliveryAlerts,
                    onChanged: (v) => setState(() => _deliveryAlerts = v),
                    title: const Text('Delivery Agent Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: const Text('Get notifications when the agent is nearby', style: TextStyle(fontSize: 11)),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
            const SizedBox(height: AppSpacing.xl),
            const Text('RECENT NOTIFICATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.sm),
            _notifications.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_rounded, size: 60, color: AppColors.textMuted.withOpacity(0.3)),
                        const SizedBox(height: AppSpacing.md),
                        const Text('No Notifications Yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: n.isRead ? Colors.white : AppColors.primary.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppShadows.soft,
                          border: Border.all(color: n.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.1), width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: n.iconColor.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(n.icon, color: n.iconColor, size: 20),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(n.body, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3)),
                              const SizedBox(height: 6),
                              Text(n.time, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              n.isRead = true;
                            });
                          },
                        ),
                      ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.05);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
