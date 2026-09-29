import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/design_system.dart';
import '../../core/services/live_order_tracking_service.dart';
import '../../features/orders/presentation/screens/orders_page.dart';

/// Interactive Dynamic Island widget for Vytra.
/// Sits at the top of the screen around the camera punch-hole cutout.
/// Shows live order status and delivery countdown until the order is delivered or app is closed.
class DynamicIslandWidget extends StatefulWidget {
  const DynamicIslandWidget({super.key});

  @override
  State<DynamicIslandWidget> createState() => _DynamicIslandWidgetState();
}

class _DynamicIslandWidgetState extends State<DynamicIslandWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final trackingService = context.watch<LiveOrderTrackingService>();
    final activeOrder = trackingService.activeOrder;

    if (!trackingService.hasActiveOrder ||
        activeOrder == null ||
        !trackingService.isDynamicIslandEnabled) {
      return const SizedBox.shrink();
    }

    final topInset = MediaQuery.of(context).padding.top;
    final status = trackingService.currentStatus;
    final remainingMins = trackingService.remainingMinutes;
    final isDelivered = status.toLowerCase() == 'delivered';

    return Positioned(
      top: topInset > 0 ? (topInset + 4) : 10,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          width: _isExpanded ? 340 : 220,
          constraints: BoxConstraints(
            minHeight: _isExpanded ? 180 : 38,
            maxHeight: _isExpanded ? 210 : 38,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0C0E),
            borderRadius: BorderRadius.circular(_isExpanded ? 26 : 22),
            border: Border.all(
              color: isDelivered
                  ? AppColors.freshGreen.withValues(alpha: 0.6)
                  : AppColors.accent.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 22,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
              if (!isDelivered)
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_isExpanded ? 26 : 22),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isExpanded = !_isExpanded);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_isExpanded ? 26 : 22),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _isExpanded
                      ? _buildExpandedContent(context, trackingService, activeOrder)
                      : _buildCompactPill(context, trackingService),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Compact Pill View hugging the top notch / punch-hole
  Widget _buildCompactPill(BuildContext context, LiveOrderTrackingService tracker) {
    final status = tracker.currentStatus;
    final mins = tracker.remainingMinutes;
    final isDelivered = status.toLowerCase() == 'delivered';

    return Container(
      key: const ValueKey('compact'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing Animated Icon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDelivered
                  ? AppColors.freshGreen.withValues(alpha: 0.3)
                  : const Color(0xFF221A14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivered
                  ? Icons.check_circle_rounded
                  : (status.toLowerCase().contains('dispatch') || status.toLowerCase().contains('ship')
                      ? Icons.two_wheeler_rounded
                      : Icons.restaurant_rounded),
              color: isDelivered ? const Color(0xFF68D391) : AppColors.accent,
              size: 16,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(begin: 0.95, end: 1.08, duration: 900.ms),

          const SizedBox(width: 8),

          // Status snippet
          Flexible(
            child: Text(
              isDelivered ? "Delivered! 🎉" : _getShortStatus(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Countdown pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isDelivered
                  ? AppColors.freshGreen.withValues(alpha: 0.35)
                  : AppColors.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isDelivered ? "Done" : "~${mins}m",
              style: TextStyle(
                color: isDelivered ? const Color(0xFF68D391) : AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Expanded Detailed View with progress bar & order action
  Widget _buildExpandedContent(
    BuildContext context,
    LiveOrderTrackingService tracker,
    dynamic order,
  ) {
    final status = tracker.currentStatus;
    final mins = tracker.remainingMinutes;
    final orderShortId = order.id.toString().length > 6
        ? order.id.toString().substring(order.id.toString().length - 6)
        : order.id.toString();

    return Container(
      key: const ValueKey('expanded'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with collapse button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF68D391),
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.3, 1.3), duration: 800.ms),
                  const SizedBox(width: 6),
                  const Text(
                    "LIVE ORDER TRACKING",
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isExpanded = false);
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Big ETA and Order ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.toLowerCase() == 'delivered'
                        ? "Delivered!"
                        : "Arriving in ~$mins mins",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Order #$orderShortId • ${order.items?.length ?? 1} item(s)",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.moped_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar with 4 steps
          _buildMilestoneBar(tracker.progressPercentage),

          const SizedBox(height: 12),

          // Footer row with "View Full Order"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Stage: $status",
                style: const TextStyle(
                  color: Color(0xFFE2D8CC),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _isExpanded = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersPage()),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      "Details",
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.accent,
                      size: 11,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneBar(double progress) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? const Color(0xFF68D391) : AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Placed", style: TextStyle(color: Colors.white54, fontSize: 9.5)),
            Text("Kitchen", style: TextStyle(color: Colors.white54, fontSize: 9.5)),
            Text("On Way", style: TextStyle(color: Colors.white54, fontSize: 9.5)),
            Text("Arrived", style: TextStyle(color: Colors.white54, fontSize: 9.5)),
          ],
        ),
      ],
    );
  }

  String _getShortStatus(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'Confirmed';
      case 'processing':
        return 'Preparing...';
      case 'dispatched':
      case 'shipped':
        return 'On the way 🛵';
      default:
        return status;
    }
  }
}
