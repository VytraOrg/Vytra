import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../auth/presentation/auth_controller.dart';

class CreditCardItem {
  final String id;
  final String cardHolder;
  final String cardNumber;
  final String expiry;
  final String brand;
  final Color gradientStart;
  final Color gradientEnd;

  CreditCardItem({
    required this.id,
    required this.cardHolder,
    required this.cardNumber,
    required this.expiry,
    this.brand = 'Visa',
    required this.gradientStart,
    required this.gradientEnd,
  });
}

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final List<CreditCardItem> _cards = [
    CreditCardItem(
      id: '1',
      cardHolder: 'Sayan Pandit',
      cardNumber: '4532 9876 1234 8492',
      expiry: '09/29',
      brand: 'Visa',
      gradientStart: const Color(0xFF6B11FF),
      gradientEnd: const Color(0xFF1199FF),
    ),
    CreditCardItem(
      id: '2',
      cardHolder: 'Sayan Pandit',
      cardNumber: '5412 7564 9812 3004',
      expiry: '12/28',
      brand: 'Mastercard',
      gradientStart: const Color(0xFFFF416C),
      gradientEnd: const Color(0xFFFF4B2B),
    ),
  ];

  final List<String> _upis = [
    'sayan@okaxis',
    'sayanpandit@okhdfcbank',
  ];

  void _showAddCardSheet() {
    final numberController = TextEditingController();
    final holderController = TextEditingController(text: context.read<AuthController>().currentUser?.name ?? 'Sayan Pandit');
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xl),
              topRight: Radius.circular(AppRadius.xl),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Add New Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Card Number',
                      hintText: '4111 2222 3333 4444',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v == null || v.trim().length < 16 ? 'Please enter a valid card number' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: holderController,
                    decoration: InputDecoration(
                      labelText: 'Card Holder Name',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: expiryController,
                          decoration: InputDecoration(
                            labelText: 'Expiry Date',
                            hintText: 'MM/YY',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Expiry' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'CVV',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v == null || v.trim().length < 3 ? 'CVV' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          _cards.add(CreditCardItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            cardHolder: holderController.text.trim(),
                            cardNumber: numberController.text.trim(),
                            expiry: expiryController.text.trim(),
                            brand: 'Visa',
                            gradientStart: const Color(0xFF0F2027),
                            gradientEnd: const Color(0xFF203A43),
                          ));
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Card added successfully!'),
                            backgroundColor: AppColors.freshGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                    ),
                    child: const Text('Add Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddUpiSheet() {
    final upiController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xl),
              topRight: Radius.circular(AppRadius.xl),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Link UPI ID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: upiController,
                  decoration: InputDecoration(
                    labelText: 'UPI ID (e.g. username@upi)',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Please enter a valid UPI ID' : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        _upis.add(upiController.text.trim());
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('UPI ID linked successfully!'),
                          backgroundColor: AppColors.freshGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                  child: const Text('Link UPI ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
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
        title: const Text('Payment Methods', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [card.gradientStart, card.gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: AppShadows.soft,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.credit_card_rounded, color: Colors.white, size: 30),
                            Text(
                              card.brand.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          card.cardNumber,
                          style: const TextStyle(color: Colors.white, letterSpacing: 2.0, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CARD HOLDER', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
                                const SizedBox(height: 2),
                                Text(card.cardHolder, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EXPIRES', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
                                const SizedBox(height: 2),
                                Text(card.expiry, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 150).ms).slideX(begin: 0.1);
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('UPI Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    TextButton.icon(
                      onPressed: _showAddUpiSheet,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Link UPI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._upis.map((upi) => Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 18),
                        ),
                        title: Text(upi, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                          onPressed: () {
                            setState(() {
                              _upis.remove(upi);
                            });
                          },
                        ),
                      ),
                    )),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: _showAddCardSheet,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('Add New Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
