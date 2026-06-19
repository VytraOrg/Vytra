import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system.dart';

class AddressItem {
  final String id;
  final String label;
  final String addressLine;
  final String city;
  final String zip;
  final bool isDefault;

  AddressItem({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.city,
    required this.zip,
    this.isDefault = false,
  });

  AddressItem copyWith({bool? isDefault}) {
    return AddressItem(
      id: id,
      label: label,
      addressLine: addressLine,
      city: city,
      zip: zip,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  final List<AddressItem> _addresses = [
    AddressItem(
      id: '1',
      label: 'Home',
      addressLine: 'Flat 402, Block B, Green Heights, Lakeview Road',
      city: 'Kolkata',
      zip: '700156',
      isDefault: true,
    ),
    AddressItem(
      id: '2',
      label: 'Office',
      addressLine: '12th Floor, Tower C, Salt Lake Sector V',
      city: 'Kolkata',
      zip: '700091',
      isDefault: false,
    ),
  ];

  void _setDefaultAddress(String id) {
    setState(() {
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: _addresses[i].id == id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated!'),
        backgroundColor: AppColors.freshGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteAddress(String id) {
    final deleted = _addresses.firstWhere((a) => a.id == id);
    setState(() {
      _addresses.removeWhere((a) => a.id == id);
      // If we deleted the default address, make the first remaining one default
      if (deleted.isDefault && _addresses.isNotEmpty) {
        _addresses[0] = _addresses[0].copyWith(isDefault: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address deleted'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddAddressSheet() {
    final labelController = TextEditingController();
    final addressLineController = TextEditingController();
    final cityController = TextEditingController();
    final zipController = TextEditingController();
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
                  const Text('Add New Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: labelController,
                    decoration: InputDecoration(
                      labelText: 'Label (e.g. Home, Office, Work)',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a label' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: addressLineController,
                    decoration: InputDecoration(
                      labelText: 'Street Address',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your street address' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cityController,
                          decoration: InputDecoration(
                            labelText: 'City',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: zipController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Pincode',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter pincode' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          _addresses.add(AddressItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            label: labelController.text.trim(),
                            addressLine: addressLineController.text.trim(),
                            city: cityController.text.trim(),
                            zip: zipController.text.trim(),
                            isDefault: _addresses.isEmpty,
                          ));
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Address added successfully!'),
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
                    child: const Text('Add Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('home')) return Icons.home_rounded;
    if (l.contains('office') || l.contains('work')) return Icons.business_rounded;
    return Icons.location_on_rounded;
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
        title: const Text('Saved Addresses', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_rounded, size: 80, color: AppColors.textMuted.withOpacity(0.4)),
                  const SizedBox(height: AppSpacing.md),
                  const Text('No Addresses Saved Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Add your home or office address to start shopping.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms)
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.soft,
                    border: Border.all(color: address.isDefault ? AppColors.primary.withOpacity(0.2) : Colors.transparent, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getIconForLabel(address.label), color: address.isDefault ? AppColors.primary : AppColors.textMuted, size: 20),
                            const SizedBox(width: 8),
                            Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                            const Spacer(),
                            if (address.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.sm)),
                                child: const Text('Default', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(address.addressLine, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('${address.city} - ${address.zip}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!address.isDefault)
                              TextButton(
                                onPressed: () => _setDefaultAddress(address.id),
                                child: const Text('Set as Default', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                            IconButton(
                              onPressed: () => _deleteAddress(address.id),
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ElevatedButton.icon(
            onPressed: _showAddAddressSheet,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            label: const Text('Add New Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
          ),
        ),
      ),
    );
  }
}
