import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';
import 'bill_service.dart';
import 'distributor_controller.dart';
import 'distributor_models.dart';
import 'distributor_ui.dart';

/// Full order: shop details, delivery status flow, every product with
/// qty × rate, GST split and grand total, plus Print Bill.
class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final c = DistributorController.instance;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final order = c.orderById(orderId);
        if (order == null) {
          return const Scaffold(body: Center(child: Text('Order not found')));
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              DistributorHeader(
                title: order.id,
                subtitle: 'Placed ${formatDateTime(order.placedAt)}',
                showBack: true,
                trailing: DeliveryChipOnDark(order.status),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _shopCard(order),
                  const SizedBox(height: 26),
                  const SectionTitle('Delivery Status'),
                  const SizedBox(height: 12),
                  _DeliveryFlow(order: order),
                  const SizedBox(height: 26),
                  SectionTitle('Products (${order.items.length})'),
                  const SizedBox(height: 12),
                  _productsCard(order),
                  const SizedBox(height: 16),
                  _summaryCard(order),
                ]),
              ),
            ],
          ),
          bottomNavigationBar: _bottomBar(context, order, c.profile),
        );
      },
    );
  }

  Widget _shopCard(DistributorOrder o) {
    Widget row(IconData i, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, size: 20, color: AppColors.primary),
            const SizedBox(width: 14),
            SizedBox(
              width: 70,
              child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
          ]),
        );
    return DCard(
      child: Column(children: [
        row(Icons.storefront_rounded, 'Shop', o.shopName),
        row(Icons.person_outline_rounded, 'Owner', o.ownerName),
        row(Icons.call_outlined, 'Phone', '+91 ${o.phone}'),
        row(Icons.location_on_outlined, 'Address', o.address),
      ]),
    );
  }

  Widget _productsCard(DistributorOrder o) {
    return DCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(children: [
        for (var i = 0; i < o.items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: DColors.chipBg, borderRadius: BorderRadius.circular(9)),
                child: Text('${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.items[i].name,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${o.items[i].qty} × ${formatInr(o.items[i].rate, decimals: 2)}  •  ${o.items[i].unit}  •  GST ${o.items[i].gstPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ]),
              ),
              Text(formatInr(o.items[i].amount, decimals: 2),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]),
          ),
          if (i != o.items.length - 1) const Divider(height: 1),
        ],
      ]),
    );
  }

  Widget _summaryCard(DistributorOrder o) {
    Widget line(String k, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Text(k,
                style: TextStyle(
                    fontSize: bold ? 16 : 13.5,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    color: bold ? AppColors.textPrimary : AppColors.textSecondary)),
            const Spacer(),
            Text(v,
                style: TextStyle(
                    fontSize: bold ? 18 : 13.5,
                    fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                    color: AppColors.textPrimary)),
          ]),
        );
    return DCard(
      child: Column(children: [
        line('Total items', '${o.items.length}'),
        line('Total quantity', '${o.totalQty}'),
        line('Taxable value', formatInr(o.subtotal, decimals: 2)),
        line('CGST', formatInr(o.gstTotal / 2, decimals: 2)),
        line('SGST', formatInr(o.gstTotal / 2, decimals: 2)),
        const Divider(height: 20),
        line('Grand Total', formatInr(o.grandTotal, decimals: 2), bold: true),
      ]),
    );
  }

  Widget _bottomBar(BuildContext context, DistributorOrder o, DistributorProfile agency) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16)],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Order Value', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(formatInr(o.grandTotal),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]),
          ),
          FilledButton.icon(
            onPressed: () => BillService.printBill(o, agency),
            icon: const Icon(Icons.print_rounded),
            label: const Text('Print Bill'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// White status chip for use on the brown header.
class DeliveryChipOnDark extends StatelessWidget {
  final DeliveryStatus status;
  const DeliveryChipOnDark(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(deliveryIcon(status), size: 14, color: deliveryColor(status)),
        const SizedBox(width: 6),
        Text(status.label,
            style: TextStyle(color: deliveryColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }
}

/// Pending → Accepted → Dispatched → Delivered, with the next-step button.
class _DeliveryFlow extends StatelessWidget {
  final DistributorOrder order;
  const _DeliveryFlow({required this.order});

  static const _steps = [
    DeliveryStatus.pending,
    DeliveryStatus.accepted,
    DeliveryStatus.dispatched,
    DeliveryStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final c = DistributorController.instance;
    final cancelled = order.status == DeliveryStatus.cancelled;
    final current = cancelled ? -1 : _steps.indexOf(order.status);
    final next = order.status.next;

    String? actionLabel;
    IconData? actionIcon;
    if (next == DeliveryStatus.accepted) {
      actionLabel = 'Accept Order';
      actionIcon = Icons.check_rounded;
    } else if (next == DeliveryStatus.dispatched) {
      actionLabel = 'Mark Dispatched & Notify Shop';
      actionIcon = Icons.local_shipping_rounded;
    } else if (next == DeliveryStatus.delivered) {
      actionLabel = 'Mark Delivered';
      actionIcon = Icons.done_all_rounded;
    }

    return DCard(
      child: Column(children: [
        if (cancelled)
          const Row(children: [
            Icon(Icons.cancel_rounded, color: DColors.red),
            SizedBox(width: 10),
            Text('This order was cancelled', style: TextStyle(color: DColors.red, fontWeight: FontWeight.w600)),
          ])
        else
          Row(children: [
            for (var i = 0; i < _steps.length; i++) ...[
              _StepDot(step: _steps[i], done: i <= current, active: i == current),
              if (i != _steps.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 22),
                    color: i < current ? DColors.green : Colors.black12,
                  ),
                ),
            ],
          ]),
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  c.updateOrderStatus(order.id, next!);
                  if (next == DeliveryStatus.dispatched) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${order.shopName} has been notified that the order is on the way')),
                    );
                  }
                },
                icon: Icon(actionIcon),
                label: Text(actionLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (order.status == DeliveryStatus.pending || order.status == DeliveryStatus.accepted) ...[
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _confirmCancel(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DColors.red,
                  side: const BorderSide(color: DColors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ]),
        ],
      ]),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel this order?'),
        content: Text('${order.shopName} will be informed that order ${order.id} was cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (ok == true) {
      DistributorController.instance.updateOrderStatus(order.id, DeliveryStatus.cancelled);
    }
  }
}

class _StepDot extends StatelessWidget {
  final DeliveryStatus step;
  final bool done;
  final bool active;
  const _StepDot({required this.step, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = done ? DColors.green : Colors.black26;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: active ? 36 : 30,
        height: active ? 36 : 30,
        decoration: BoxDecoration(
          color: done ? color : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(deliveryIcon(step), size: 16, color: done ? Colors.white : Colors.black38),
      ),
      const SizedBox(height: 6),
      Text(step.label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: done ? AppColors.textPrimary : AppColors.textMuted,
          )),
    ]);
  }
}
