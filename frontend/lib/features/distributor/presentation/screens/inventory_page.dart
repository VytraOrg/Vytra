import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system.dart';
import 'distributor_controller.dart';
import 'distributor_models.dart';
import 'distributor_ui.dart';

/// Inventory & rates.
/// Tapping "Update Rates" puts the agency in UPDATING mode: no shopkeeper can
/// order until the distributor taps "Save & Reopen" (or cancels).
class DistributorInventoryPage extends StatefulWidget {
  final bool showBack;
  const DistributorInventoryPage({super.key, this.showBack = false});

  @override
  State<DistributorInventoryPage> createState() => _DistributorInventoryPageState();
}

class _DistributorInventoryPageState extends State<DistributorInventoryPage> {
  final Map<String, TextEditingController> _rateCtrls = {};
  String _query = '';

  DistributorController get c => DistributorController.instance;

  void _ensureControllers() {
    if (_rateCtrls.isNotEmpty) return;
    for (final p in c.inventory) {
      _rateCtrls[p.id] = TextEditingController(text: _plain(p.rate));
    }
  }

  void _disposeControllers() {
    for (final t in _rateCtrls.values) {
      t.dispose();
    }
    _rateCtrls.clear();
  }

  String _plain(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _startUpdate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.sync_lock_rounded, color: DColors.blue, size: 36),
        title: const Text('Start rate update?'),
        content: const Text(
          'Your agency will show "Updating" to all shopkeepers and nobody can place an order '
          'until you save the new rates.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start Updating'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _disposeControllers();
    _ensureControllers();
    c.startRateUpdate();
  }

  void _save() {
    final newRates = <String, double>{};
    for (final p in c.inventory) {
      final v = double.tryParse(_rateCtrls[p.id]?.text.trim() ?? '');
      if (v == null || v <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enter a valid rate for ${p.name}')),
        );
        return;
      }
      newRates[p.id] = v;
    }
    c.finishRateUpdate(newRates);
    _disposeControllers();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rates saved. Shopkeepers can order again.')),
    );
  }

  void _cancel() {
    c.cancelRateUpdate();
    _disposeControllers();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final updating = c.isUpdatingRates;
        if (updating) _ensureControllers();

        final q = _query.toLowerCase();
        final items = c.inventory
            .where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q))
            .toList();
        final available = c.inventory.where((p) => p.isAvailable).length;

        final double bottomMargin = widget.showBack ? 20.0 : 88.0;
        final double listBottomPadding = updating ? 220.0 : (widget.showBack ? 90.0 : 165.0);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Column(children: [
                DistributorHeader(
                  title: 'Inventory & Rates',
                  subtitle: '${c.inventory.length} products  •  $available available',
                  showBack: widget.showBack,
                  trailing: const AgencyStatusPill(),
                  bottom: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                if (updating)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _buildUpdatingModeHeader(),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => c.loadData(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20, 16, 20, listBottomPadding),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _productTile(items[i], updating),
                    ),
                  ),
                ),
              ]),
              if (!updating)
                Positioned(
                  right: 20,
                  bottom: bottomMargin,
                  child: FloatingActionButton.extended(
                    onPressed: _startUpdate,
                    backgroundColor: AppColors.primary,
                    elevation: 4,
                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'Update Rates',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                )
              else
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: bottomMargin,
                  child: _editingActionPanel(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _productTile(InventoryItem p, bool updating) {
    final lowStock = p.stock > 0 && p.stock < 20;
    return DCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: DColors.chipBg, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Opacity(
            opacity: p.isAvailable ? 1 : 0.5,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14.5)),
              const SizedBox(height: 3),
              Text('${p.category}  •  ${p.unit}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 5),
              Row(children: [
                TagChip(
                  p.stock == 0 ? 'Out of stock' : '${p.stock} in stock',
                  color: p.stock == 0 ? DColors.red : (lowStock ? DColors.amber : DColors.green),
                ),
                if (!p.isAvailable) ...[
                  const SizedBox(width: 6),
                  const TagChip('Hidden', color: DColors.grey),
                ],
              ]),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        if (updating)
          Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RATE / ${p.unit.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      '₹',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _rateCtrls[p.id],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatInr(p.rate, decimals: p.rate == p.rate.roundToDouble() ? 0 : 2),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: p.isAvailable,
                activeColor: Colors.white,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => c.setProductAvailable(p.id, v),
              ),
            ),
          ]),
      ]),
    );
  }

  Widget _buildUpdatingModeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DColors.green.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DColors.green.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sync_lock_rounded, color: DColors.green, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rates Updating in Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: DColors.green,
                    fontSize: 13.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Orders are paused. Enter new rates below and tap Save & Reopen.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editingActionPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: _cancel,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: const Text(
                'Save & Reopen',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: DColors.green,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
