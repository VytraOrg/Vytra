import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';
import 'bill_service.dart';
import 'distributor_controller.dart';
import 'distributor_models.dart';
import 'distributor_ui.dart';
import 'order_details_page.dart';

/// List of all shopkeeper orders. Each card shows shop name, owner,
/// address, phone, order value and a "Print Bill" button beside the value.
class DistributorOrdersPage extends StatefulWidget {
  final bool showBack;
  const DistributorOrdersPage({super.key, this.showBack = false});

  @override
  State<DistributorOrdersPage> createState() => _DistributorOrdersPageState();
}

class _DistributorOrdersPageState extends State<DistributorOrdersPage> {
  DeliveryStatus? _filter; // null = all
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = DistributorController.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final q = _query.toLowerCase();
          final list = c.orders.where((o) {
            final matchesFilter = _filter == null || o.status == _filter;
            final matchesQuery = q.isEmpty ||
                o.shopName.toLowerCase().contains(q) ||
                o.ownerName.toLowerCase().contains(q) ||
                o.id.toLowerCase().contains(q) ||
                o.phone.contains(q);
            return matchesFilter && matchesQuery;
          }).toList()
            ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

          return Column(children: [
            DistributorHeader(
              title: 'Incoming Orders',
              subtitle: '${c.totalOrders} orders  •  ${formatInr(c.totalOrderValue)} total',
              showBack: widget.showBack,
              trailing: const AgencyStatusPill(),
              bottom: _SearchField(onChanged: (v) => setState(() => _query = v)),
            ),
            SizedBox(
              height: 58,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                children: [
                  _filterChip(null, 'All', c.orders.length),
                  for (final s in DeliveryStatus.values) _filterChip(s, s.label, c.countByStatus(s)),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(icon: Icons.receipt_long_outlined, text: 'No orders here yet')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => OrderCard(order: list[i]),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _filterChip(DeliveryStatus? s, String label, int count) {
    final selected = _filter == s;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) => setState(() => _filter = s),
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.primary : Colors.black12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search shop, owner, phone or order no...',
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}

/// Reused on the dashboard ("Recent Orders") and the orders list.
class OrderCard extends StatelessWidget {
  final DistributorOrder order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final agency = DistributorController.instance.profile;
    return DCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailsPage(orderId: order.id)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Shop + status
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: DColors.chipBg, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(order.ownerName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ),
              ]),
            ]),
          ),
          DeliveryChip(order.status),
        ]),
        const SizedBox(height: 12),
        _infoLine(Icons.location_on_outlined, order.address),
        const SizedBox(height: 6),
        _infoLine(Icons.call_outlined, '+91 ${order.phone}'),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
        // Value + print bill
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Order Value', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(formatInr(order.grandTotal),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('${order.id}  •  ${order.items.length} items  •  ${timeAgo(order.placedAt)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
          OutlinedButton.icon(
            onPressed: () => BillService.printBill(order, agency),
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Print Bill'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _infoLine(IconData icon, String text) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ),
      ]);
}
