import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system.dart';

/// Configurable item model for the unified [FloatingPillNavBar].
class NavBarItem {
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final int badgeCount;

  const NavBarItem({
    required this.label,
    required this.selectedIcon,
    IconData? unselectedIcon,
    this.badgeCount = 0,
  }) : unselectedIcon = unselectedIcon ?? selectedIcon;
}

/// A modern, physics-based floating pill navigation bar used across all user roles
/// (Customer, Shopkeeper, Distributor).
///
/// Features:
/// - Smooth interactive swipe / horizontal dragging with haptic feedback
/// - Animated sliding active-tab pill with scale dynamics
/// - Universal role-based customization via `items` list
class FloatingPillNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<NavBarItem> items;
  final int cartCount;

  const FloatingPillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.items = const [],
    this.cartCount = 0,
  });

  @override
  State<FloatingPillNavBar> createState() => _FloatingPillNavBarState();
}

class _FloatingPillNavBarState extends State<FloatingPillNavBar>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _scaleController;
  late Animation<double> _navScaleAnim;
  late Animation<double> _pillScaleAnim;

  Animation<double>? _anim;
  double _position = 0.0;
  int _lastHapticIndex = 0;

  List<NavBarItem> get _effectiveItems {
    if (widget.items.isNotEmpty) return widget.items;
    return [
      const NavBarItem(
        label: "Home",
        selectedIcon: Icons.home_rounded,
        unselectedIcon: Icons.home_outlined,
      ),
      const NavBarItem(
        label: "Orders",
        selectedIcon: Icons.receipt_long_rounded,
        unselectedIcon: Icons.receipt_long_outlined,
      ),
      const NavBarItem(
        label: "Saved",
        selectedIcon: Icons.favorite_rounded,
        unselectedIcon: Icons.favorite_border_rounded,
      ),
      const NavBarItem(
        label: "Account",
        selectedIcon: Icons.person_rounded,
        unselectedIcon: Icons.person_outline_rounded,
      ),
      NavBarItem(
        label: "Cart",
        selectedIcon: Icons.shopping_cart_rounded,
        unselectedIcon: Icons.shopping_cart_outlined,
        badgeCount: widget.cartCount,
      ),
    ];
  }

  int get _itemCount => _effectiveItems.length;
  int get _maxIndex => _itemCount > 0 ? _itemCount - 1 : 0;

  @override
  void initState() {
    super.initState();
    _position = widget.currentIndex.toDouble().clamp(0.0, _maxIndex.toDouble());
    _lastHapticIndex = widget.currentIndex;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _navScaleAnim = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    _pillScaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant FloatingPillNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex &&
        !_animController.isAnimating) {
      _animateTo(widget.currentIndex.toDouble().clamp(0.0, _maxIndex.toDouble()));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _animController.stop();
    final start = _position;
    _anim = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _position = _anim!.value;
        });
      });
    _animController.forward(from: 0.0);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _animController.stop();
    _scaleController.forward();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double totalWidth) {
    if (totalWidth <= 0 || _itemCount == 0) return;
    final tabWidth = totalWidth / _itemCount;
    final delta = details.primaryDelta! / tabWidth;
    final newPos = (_position + delta).clamp(0.0, _maxIndex.toDouble());
    final roundedIndex = newPos.round();
    if (roundedIndex != _lastHapticIndex) {
      _lastHapticIndex = roundedIndex;
      HapticFeedback.selectionClick();
    }
    setState(() {
      _position = newPos;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _scaleController.reverse();
    final velocity = details.primaryVelocity ?? 0.0;
    int targetIndex;
    if (velocity > 350) {
      targetIndex = (_position.floor() + 1).clamp(0, _maxIndex);
    } else if (velocity < -350) {
      targetIndex = (_position.ceil() - 1).clamp(0, _maxIndex);
    } else {
      targetIndex = _position.round().clamp(0, _maxIndex);
    }

    _animateTo(targetIndex.toDouble());
    if (targetIndex != widget.currentIndex) {
      widget.onTabSelected(targetIndex);
    }
  }

  void _onHorizontalDragCancel() {
    _scaleController.reverse();
    _animateTo(widget.currentIndex.toDouble().clamp(0.0, _maxIndex.toDouble()));
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    _animateTo(index.toDouble());
    if (index != widget.currentIndex) {
      widget.onTabSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _effectiveItems;
    final count = items.length;

    return AnimatedBuilder(
      animation: Listenable.merge([_animController, _scaleController]),
      builder: (context, child) {
        final activeIndex = _position.round().clamp(0, _maxIndex);

        return Transform.scale(
          scale: _navScaleAnim.value,
          child: Container(
            margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppColors.primaryLight,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: 0.12 + 0.06 * _scaleController.value,
                  ),
                  blurRadius: 24 + 6 * _scaleController.value,
                  spreadRadius: 0,
                  offset: Offset(0, 8 + 2 * _scaleController.value),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final tabWidth = totalWidth > 0 && count > 0 ? totalWidth / count : 60.0;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: _onHorizontalDragStart,
                    onHorizontalDragUpdate: (details) =>
                        _onHorizontalDragUpdate(details, totalWidth),
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    onHorizontalDragCancel: _onHorizontalDragCancel,
                    child: Stack(
                      children: [
                        // Symmetrical sliding selection pill with dynamic zoom
                        Positioned(
                          left: _position * tabWidth + 3,
                          top: 3,
                          bottom: 3,
                          width: tabWidth - 6 > 0 ? tabWidth - 6 : 0,
                          child: Transform.scale(
                            scale: _pillScaleAnim.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: _scaleController.value > 0.01
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.14 * _scaleController.value,
                                          ),
                                          blurRadius: 8 * _scaleController.value,
                                          offset: Offset(0, 2 * _scaleController.value),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        // Tab Items
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              for (int i = 0; i < count; i++)
                                _buildTab(i, items[i], activeIndex),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(
    int index,
    NavBarItem item,
    int activeIndex,
  ) {
    final isSelected = activeIndex == index;
    final badgeCount = item.badgeCount;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabTapped(index),
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? item.selectedIcon : item.unselectedIcon,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 22,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
