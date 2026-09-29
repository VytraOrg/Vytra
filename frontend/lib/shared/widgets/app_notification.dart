import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system.dart';
import '../../features/cart/presentation/screens/cart_page.dart';

/// Centralized modern notification system for Vytra.
/// Smoothly slides UP from below the bottom of the screen,
/// then slides back DOWN to the bottom when dismissed.
class AppNotification {
  static OverlayEntry? _currentEntry;
  static _SlideToastState? _currentState;

  /// Dismisses any currently showing notification by sliding it down to the bottom.
  static void dismiss([BuildContext? context]) {
    _currentState?.dismiss();
  }

  /// Shows a premium floating pill notification when an item is added to the cart.
  /// Slides in from the bottom, and slides out to the bottom.
  static void showAddedToCart(
    BuildContext context, {
    required String productName,
    String? priceInfo,
    VoidCallback? onViewCart,
    bool isTab = false,
  }) {
    HapticFeedback.mediumImpact();

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomMargin = (isTab ? 96.0 : 16.0) + bottomInset;

    _showSlideToast(
      context: context,
      bottomMargin: bottomMargin,
      builder: (dismiss) => _buildAddedToCartWidget(
        context: context,
        productName: productName,
        priceInfo: priceInfo,
        onViewCart: onViewCart,
        dismiss: dismiss,
      ),
    );
  }

  /// Shows a success notification sliding from and to the bottom.
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool isTab = false,
  }) {
    HapticFeedback.lightImpact();

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomMargin = (isTab ? 96.0 : 16.0) + bottomInset;

    _showSlideToast(
      context: context,
      bottomMargin: bottomMargin,
      builder: (dismiss) => _buildSuccessWidget(
        context: context,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        dismiss: dismiss,
      ),
    );
  }

  /// Shows an error notification sliding from and to the bottom.
  static void showError(
    BuildContext context,
    String message, {
    bool isTab = false,
  }) {
    HapticFeedback.heavyImpact();

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomMargin = (isTab ? 96.0 : 16.0) + bottomInset;

    _showSlideToast(
      context: context,
      bottomMargin: bottomMargin,
      builder: (dismiss) => _buildErrorWidget(
        context: context,
        message: message,
        dismiss: dismiss,
      ),
    );
  }

  static void _showSlideToast({
    required BuildContext context,
    required double bottomMargin,
    required Widget Function(VoidCallback dismiss) builder,
  }) {
    // If one is already showing, remove it cleanly first
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
      _currentState = null;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _SlideToastWidget(
        bottomMargin: bottomMargin,
        onStateCreated: (state) {
          _currentState = state;
        },
        onDismissed: () {
          if (_currentEntry == entry) {
            try {
              entry.remove();
            } catch (_) {}
            _currentEntry = null;
            _currentState = null;
          }
        },
        childBuilder: (dismiss) => builder(dismiss),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static Widget _buildAddedToCartWidget({
    required BuildContext context,
    required String productName,
    String? priceInfo,
    VoidCallback? onViewCart,
    required VoidCallback dismiss,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing cart badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.freshGreen.withValues(alpha: 0.35),
                  AppColors.freshGreen.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.freshGreen.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Color(0xFF68D391),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: productName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const TextSpan(
                        text: " added to cart",
                        style: TextStyle(
                          color: Color(0xFFE2D8CC),
                          fontWeight: FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (priceInfo != null && priceInfo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    priceInfo,
                    style: TextStyle(
                      color: AppColors.accent.withValues(alpha: 0.9),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // "View Cart" Pill Button
          GestureDetector(
            onTap: () {
              dismiss();
              if (onViewCart != null) {
                onViewCart();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartPage()),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "View Cart",
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primaryDark,
                    size: 13,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSuccessWidget({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    required VoidCallback dismiss,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.freshGreen.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.freshGreen.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF68D391),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                dismiss();
                onAction();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildErrorWidget({
    required BuildContext context,
    required String message,
    required VoidCallback dismiss,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1517),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFC8181),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal animated stateful widget managing slide-in from bottom and slide-out to bottom.
class _SlideToastWidget extends StatefulWidget {
  final double bottomMargin;
  final ValueChanged<_SlideToastState> onStateCreated;
  final VoidCallback onDismissed;
  final Widget Function(VoidCallback dismiss) childBuilder;

  const _SlideToastWidget({
    required this.bottomMargin,
    required this.onStateCreated,
    required this.onDismissed,
    required this.childBuilder,
  });

  @override
  State<_SlideToastWidget> createState() => _SlideToastState();
}

class _SlideToastState extends State<_SlideToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  Timer? _autoDismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 280),
    );

    // Starts below screen (Offset(0, 1.8)), slides to 0.0, and reverses back down to Offset(0, 1.8)
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 1.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _animController.forward();

    _autoDismissTimer = Timer(const Duration(milliseconds: 2800), () {
      dismiss();
    });
  }

  void dismiss() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _autoDismissTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: widget.bottomMargin,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            type: MaterialType.transparency,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragEnd: (details) {
                    // Swipe down to dismiss early to the bottom
                    if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                      dismiss();
                    }
                  },
                  child: widget.childBuilder(dismiss),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
