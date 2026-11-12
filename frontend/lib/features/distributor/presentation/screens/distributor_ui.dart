import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';
import 'distributor_controller.dart';
import 'distributor_models.dart';

// ----------------------------------------------------------------- colours
class DColors {
  static const Color green = Color(0xFF2E7D5B);
  static const Color amber = Color(0xFFE08E2B);
  static const Color blue = Color(0xFF3B78A6);
  static const Color red = Color(0xFFC0473B);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color chipBg = Color(0xFFF6EDE4); // beige, as in nav pill
}

Color agencyStatusColor(AgencyStatus s) {
  switch (s) {
    case AgencyStatus.open:
      return DColors.green;
    case AgencyStatus.paused:
      return DColors.amber;
    case AgencyStatus.updating:
      return DColors.blue;
    case AgencyStatus.closed:
      return DColors.red;
  }
}

String agencyStatusLabel(AgencyStatus s) {
  switch (s) {
    case AgencyStatus.open:
      return 'OPEN';
    case AgencyStatus.paused:
      return 'PAUSED';
    case AgencyStatus.updating:
      return 'UPDATING';
    case AgencyStatus.closed:
      return 'OFF';
  }
}

Color deliveryColor(DeliveryStatus s) {
  switch (s) {
    case DeliveryStatus.pending:
      return DColors.amber;
    case DeliveryStatus.accepted:
      return DColors.blue;
    case DeliveryStatus.dispatched:
      return const Color(0xFF7A5BB5);
    case DeliveryStatus.delivered:
      return DColors.green;
    case DeliveryStatus.cancelled:
      return DColors.red;
  }
}

IconData deliveryIcon(DeliveryStatus s) {
  switch (s) {
    case DeliveryStatus.pending:
      return Icons.hourglass_top_rounded;
    case DeliveryStatus.accepted:
      return Icons.check_circle_outline_rounded;
    case DeliveryStatus.dispatched:
      return Icons.local_shipping_outlined;
    case DeliveryStatus.delivered:
      return Icons.inventory_rounded;
    case DeliveryStatus.cancelled:
      return Icons.cancel_outlined;
  }
}

// --------------------------------------------------------------- formatting
/// Indian number format: 123456.5 -> ₹1,23,457
String formatInr(double value, {bool symbol = true, int decimals = 0}) {
  final negative = value < 0;
  final parts = value.abs().toStringAsFixed(decimals).split('.');
  final intPart = parts[0];
  String result;
  if (intPart.length <= 3) {
    result = intPart;
  } else {
    final last3 = intPart.substring(intPart.length - 3);
    var rest = intPart.substring(0, intPart.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    result = '${groups.join(',')},$last3';
  }
  if (parts.length > 1) result = '$result.${parts[1]}';
  return '${negative ? '-' : ''}${symbol ? '₹' : ''}$result';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatDateTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = d.hour < 12 ? 'AM' : 'PM';
  return '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}, $h:$m $ap';
}

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}

// ------------------------------------------------------------------ widgets
class DCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const DCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: Colors.black.withOpacity(0.06))),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class TagChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const TagChip(this.text, {super.key, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
    );
  }
}

class DeliveryChip extends StatelessWidget {
  final DeliveryStatus status;
  const DeliveryChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) =>
      TagChip(status.label, color: deliveryColor(status), icon: deliveryIcon(status));
}

/// Green/amber/blue/red pill shown in headers. Tap opens the agency controls.
class AgencyStatusPill extends StatelessWidget {
  const AgencyStatusPill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DistributorController.instance;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final color = agencyStatusColor(c.status);
        return GestureDetector(
          onTap: () => showAgencyControlsSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(agencyStatusLabel(c.status),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8, fontSize: 12)),
            ]),
          ),
        );
      },
    );
  }
}

/// Brown rounded header used on every distributor page.
class DistributorHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;
  final Widget? bottom;

  const DistributorHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (showBack) ...[
              InkWell(
                onTap: () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
            ),
            if (trailing != null) trailing!,
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
          if (bottom != null) ...[const SizedBox(height: 16), bottom!],
        ],
      ),
    );
  }
}

/// Agency ON/OFF + Accepting orders switches (dashboard & profile).
class AgencyControlsCard extends StatelessWidget {
  const AgencyControlsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DistributorController.instance;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => DCard(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: [
          _SwitchRow(
            icon: Icons.power_settings_new_rounded,
            color: c.isOpen ? DColors.green : DColors.red,
            title: c.isOpen ? 'Agency is ON' : 'Agency is OFF',
            subtitle: c.isOpen ? 'Shopkeepers can see your agency' : 'Hidden from shopkeepers',
            value: c.isOpen,
            onChanged: (v) => _confirmToggle(context,
                value: v,
                offTitle: 'Turn agency OFF?',
                offBody: 'Shopkeepers will not be able to see your products or place orders until you turn it back ON.',
                onConfirm: () => c.setOpen(v)),
          ),
          const Divider(height: 1, indent: 64),
          _SwitchRow(
            icon: Icons.shopping_cart_checkout_rounded,
            color: c.isAcceptingOrders ? DColors.green : DColors.amber,
            title: 'Accepting new orders',
            subtitle: c.isAcceptingOrders ? 'New orders are coming in' : 'Paused — no new orders',
            value: c.isAcceptingOrders,
            enabled: c.isOpen,
            onChanged: (v) => _confirmToggle(context,
                value: v,
                offTitle: 'Stop taking orders?',
                offBody: 'Existing orders stay as they are. Shopkeepers just cannot place new orders until you resume.',
                onConfirm: () => c.setAcceptingOrders(v)),
          ),
          if (c.isUpdatingRates) ...[
            const Divider(height: 1, indent: 64),
            const ListTile(
              leading: Icon(Icons.sync_rounded, color: DColors.blue),
              title: Text('Rate update in progress',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
              subtitle: Text('Ordering is locked until you save the rates',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
        ]),
      ),
    );
  }

  Future<void> _confirmToggle(BuildContext context,
      {required bool value, required String offTitle, required String offBody, required VoidCallback onConfirm}) async {
    if (value) {
      onConfirm();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(offTitle),
        content: Text(offBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok == true) onConfirm();
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14.5)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Switch(
          value: value,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

void showAgencyControlsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 18),
          const Text('Agency Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Control whether shopkeepers can order from you.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const AgencyControlsCard(),
        ]),
      ),
    ),
  );
}

/// Warning strip shown when the agency is not open for orders.
class AgencyStatusBanner extends StatelessWidget {
  final VoidCallback? onFinishUpdate;
  const AgencyStatusBanner({super.key, this.onFinishUpdate});

  @override
  Widget build(BuildContext context) {
    final c = DistributorController.instance;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final s = c.status;
        if (s == AgencyStatus.open) return const SizedBox.shrink();
        late final String title, body, action;
        late final IconData icon;
        late final VoidCallback onAction;
        switch (s) {
          case AgencyStatus.updating:
            icon = Icons.sync_rounded;
            title = 'Rates are being updated';
            body = 'No shopkeeper can order until you save the new rates.';
            action = 'Finish';
            onAction = onFinishUpdate ?? () {};
            break;
          case AgencyStatus.paused:
            icon = Icons.pause_circle_outline_rounded;
            title = 'Not accepting orders';
            body = 'Shopkeepers can browse but cannot place orders.';
            action = 'Resume';
            onAction = () => c.setAcceptingOrders(true);
            break;
          case AgencyStatus.closed:
            icon = Icons.power_off_rounded;
            title = 'Agency is OFF';
            body = 'You are hidden from shopkeepers.';
            action = 'Turn ON';
            onAction = () => c.setOpen(true);
            break;
          case AgencyStatus.open:
            return const SizedBox.shrink();
        }
        final color = agencyStatusColor(s);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onAction,
              child: Text(action),
            ),
          ]),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
