import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system.dart';

class FloatingPillNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final int cartCount;

  const FloatingPillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
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

  @override
  void initState() {
    super.initState();
    _position = widget.currentIndex.toDouble();
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
      _animateTo(widget.currentIndex.toDouble());
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
    if (totalWidth <= 0) return;
    final tabWidth = totalWidth / 5;
    final delta = details.primaryDelta! / tabWidth;
    final newPos = (_position + delta).clamp(0.0, 4.0);
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
      targetIndex = (_position.floor() + 1).clamp(0, 4);
    } else if (velocity < -350) {
      targetIndex = (_position.ceil() - 1).clamp(0, 4);
    } else {
      targetIndex = _position.round().clamp(0, 4);
    }

    _animateTo(targetIndex.toDouble());
    if (targetIndex != widget.currentIndex) {
      widget.onTabSelected(targetIndex);
    }
  }

  void _onHorizontalDragCancel() {
    _scaleController.reverse();
    _animateTo(widget.currentIndex.toDouble());
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
    return AnimatedBuilder(
      animation: Listenable.merge([_animController, _scaleController]),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth - (AppSpacing.md * 2);
            final tabWidth = totalWidth > 0 ? totalWidth / 5 : 60.0;
            final activeIndex = _position.round().clamp(0, 4);

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
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: _onHorizontalDragStart,
                    onHorizontalDragUpdate: (details) =>
                        _onHorizontalDragUpdate(details, totalWidth),
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    onHorizontalDragCancel: _onHorizontalDragCancel,
                    child: Stack(
                      children: [
                        // Symmetrical draggable/sliding selection pill with dynamic zoom
                        Positioned(
                          left: _position * tabWidth + 3,
                          top: 3,
                          bottom: 3,
                          width: tabWidth - 6,
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
                              _buildTab(0, "Home", Icons.home_rounded, Icons.home_outlined, activeIndex),
                              _buildTab(1, "Orders", Icons.receipt_long_rounded, Icons.receipt_long_outlined, activeIndex),
                              _buildTab(2, "Saved", Icons.favorite_rounded, Icons.favorite_border_rounded, activeIndex),
                              _buildTab(3, "Account", Icons.person_rounded, Icons.person_outline_rounded, activeIndex),
                              _buildTab(4, "Cart", Icons.shopping_cart_rounded, Icons.shopping_cart_outlined, activeIndex, badgeCount: widget.cartCount),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTab(
    int index,
    String label,
    IconData selectedIcon,
    IconData unselectedIcon,
    int activeIndex, {
    int badgeCount = 0,
  }) {
    final isSelected = activeIndex == index;

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
                    isSelected ? selectedIcon : unselectedIcon,
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
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
