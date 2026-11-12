import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';
import 'distributor_controller.dart';
import 'distributor_models.dart';
import 'distributor_profile_page.dart';
import 'distributor_ui.dart';
import 'inventory_page.dart';
import 'orders_page.dart';
import 'sales_report_page.dart';

/// Entry point for the distributor role (same class name as before, so your
/// existing navigation to `DistributorDash()` keeps working).
/// Bottom nav: Dashboard · Orders · Inventory · Reports · Profile
class DistributorDash extends StatefulWidget {
  const DistributorDash({super.key});

  @override
  State<DistributorDash> createState() => _DistributorDashState();
}

class _DistributorDashState extends State<DistributorDash> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          DistributorHomeTab(onNavigate: _go),
          const DistributorOrdersPage(),
          const DistributorInventoryPage(),
          const DistributorSalesReport(),
          DistributorProfilePage(
            onLogout: () {
              // TODO: sign out, then go to your login screen.
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
      bottomNavigationBar: _DistributorNavBar(index: _index, onTap: _go),
    );
  }
}

// ======================================================================= HOME
class DistributorHomeTab extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const DistributorHomeTab({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final c = DistributorController.instance;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final recent = c.recentOrders(3);
        final toDeliver = c.countByStatus(DeliveryStatus.pending) +
            c.countByStatus(DeliveryStatus.accepted) +
            c.countByStatus(DeliveryStatus.dispatched);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context, c)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.status != AgencyStatus.open) ...[
                      AgencyStatusBanner(onFinishUpdate: () => onNavigate(2)),
                      const SizedBox(height: 20),
                    ],

                    // ---- Overview
                    const SectionTitle('Business Overview'),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.receipt_long_rounded,
                          color: AppColors.skyBlue,
                          tag: 'All-time',
                          value: '${c.totalOrders}',
                          label: 'Total Orders',
                          onTap: () => onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.currency_rupee_rounded,
                          color: AppColors.freshGreen,
                          tag: 'Incl. GST',
                          value: formatInr(c.totalOrderValue),
                          label: 'Total Order Value',
                          onTap: () => onNavigate(3),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.pending_actions_rounded,
                          color: DColors.amber,
                          tag: 'Action needed',
                          value: '${c.countByStatus(DeliveryStatus.pending)}',
                          label: 'New Orders',
                          onTap: () => onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_shipping_outlined,
                          color: AppColors.accent,
                          tag: 'In progress',
                          value: '$toDeliver',
                          label: 'To Deliver',
                          onTap: () => onNavigate(1),
                        ),
                      ),
                    ]),

                    // ---- Delivery status
                    const SizedBox(height: 28),
                    SectionTitle('Delivery Status', action: 'Manage', onAction: () => onNavigate(1)),
                    const SizedBox(height: 12),
                    _DeliveryStatusCard(onTap: () => onNavigate(1)),

                    // ---- Controls
                    const SizedBox(height: 28),
                    const SectionTitle('Agency Controls'),
                    const SizedBox(height: 12),
                    const AgencyControlsCard(),

                    // ---- Quick actions
                    const SizedBox(height: 28),
                    const SectionTitle('Quick Actions'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _QuickAction(icon: Icons.assignment_outlined, label: 'Orders', onTap: () => onNavigate(1)),
                        _QuickAction(icon: Icons.price_change_outlined, label: 'Update Rates', onTap: () => onNavigate(2)),
                        _QuickAction(icon: Icons.local_shipping_outlined, label: 'Delivery', onTap: () => onNavigate(1)),
                        _QuickAction(icon: Icons.bar_chart_rounded, label: 'Reports', onTap: () => onNavigate(3)),
                      ],
                    ),

                    // ---- Recent orders
                    const SizedBox(height: 28),
                    SectionTitle('Recent Orders', action: 'View all', onAction: () => onNavigate(1)),
                    const SizedBox(height: 12),
                    if (recent.isEmpty)
                      const EmptyState(icon: Icons.receipt_long_outlined, text: 'No orders yet')
                    else
                      ...recent.map((o) => OrderCard(order: o)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context, DistributorController c) {
    final top = MediaQuery.of(context).padding.top;
    final p = c.profile;
    final pending = c.countByStatus(DeliveryStatus.pending);
    return Container(
      padding: EdgeInsets.fromLTRB(22, top + 14, 22, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xxl),
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // faded truck in the corner, like the store awning on the shop dashboard
          Positioned(
            right: -10,
            top: 30,
            child: Icon(Icons.local_shipping_rounded, size: 130, color: Colors.white.withOpacity(0.06)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(p.agencyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
                ),
                _NotificationBell(count: pending, onTap: () => onNavigate(1)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => onNavigate(4),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFE7B48A),
                    child: Text(
                      p.ownerName.isEmpty ? 'D' : p.ownerName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Welcome back 👋', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(p.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const AgencyStatusPill(),
                ],
              ),
              const SizedBox(height: 14),
              Row(children: [
                _HeaderBadge(icon: Icons.receipt_long_outlined, text: 'GSTIN ${p.gstNo.isEmpty ? '—' : p.gstNo}'),
                const SizedBox(width: 8),
                Flexible(
                  child: _HeaderBadge(
                    icon: Icons.verified_user_outlined,
                    text: 'FSSAI ${p.fssaiNo.isEmpty ? '—' : p.fssaiNo}',
                  ),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================== widgets
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tag;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.tag,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 8),
          Expanded(child: Align(alignment: Alignment.topRight, child: TagChip(tag, color: color))),
        ]),
        const SizedBox(height: 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _DeliveryStatusCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DeliveryStatusCard({required this.onTap});

  static const _shown = [
    DeliveryStatus.pending,
    DeliveryStatus.accepted,
    DeliveryStatus.dispatched,
    DeliveryStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final c = DistributorController.instance;
    final counts = {for (final s in _shown) s: c.countByStatus(s)};
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    return DCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('$total orders',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          if (c.countByStatus(DeliveryStatus.cancelled) > 0)
            TagChip('${c.countByStatus(DeliveryStatus.cancelled)} cancelled', color: DColors.red),
        ]),
        const SizedBox(height: 12),
        // segmented progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: total == 0
                ? Container(color: Colors.black12)
                : Row(children: [
                    for (final s in _shown)
                      if (counts[s]! > 0)
                        Expanded(flex: counts[s]!, child: Container(color: deliveryColor(s))),
                  ]),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          for (final s in _shown)
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: deliveryColor(s), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(s.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('${counts[s]}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ]),
            ),
        ]),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            decoration: const BoxDecoration(color: Color(0xFFE59A5B), shape: BoxShape.circle),
            child: Text('$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeaderBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 0.3)),
        ),
      ]),
    );
  }
}

// ============================================================== bottom nav
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _DistributorNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _DistributorNavBar({required this.index, required this.onTap});

  static const _items = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.receipt_long_rounded, 'Orders'),
    _NavItem(Icons.inventory_2_rounded, 'Inventory'),
    _NavItem(Icons.bar_chart_rounded, 'Reports'),
    _NavItem(Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _items.length; i++)
                GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(horizontal: i == index ? 16 : 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: i == index ? DColors.chipBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_items[i].icon,
                          size: 22, color: i == index ? AppColors.primary : AppColors.textMuted),
                      if (i == index) ...[
                        const SizedBox(width: 8),
                        Text(_items[i].label,
                            style: const TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
