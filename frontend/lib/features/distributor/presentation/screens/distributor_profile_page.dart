import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system.dart';
import 'distributor_controller.dart';

import 'distributor_ui.dart';

/// Agency profile: business details, GSTIN / Trade Licence / FSSAI,
/// agency ON/OFF controls and logout.
class DistributorProfilePage extends StatelessWidget {
  final VoidCallback? onLogout;
  const DistributorProfilePage({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final c = DistributorController.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final p = c.profile;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DistributorHeader(title: 'Agency Profile', trailing: const AgencyStatusPill()),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Identity card
                  DCard(
                    child: Row(children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          p.agencyName.isEmpty ? 'D' : p.agencyName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.agencyName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(p.email, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          const TagChip('Distributor', color: AppColors.primary),
                        ]),
                      ),
                    ]),
                  ),
                  if (!p.isComplianceComplete) ...[
                    const SizedBox(height: 14),
                    _missingDocsBanner(context),
                  ],
                  const SizedBox(height: 26),
                  SectionTitle('Business Details', action: 'Edit', onAction: () => _openEdit(context)),
                  const SizedBox(height: 10),
                  DCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(children: [
                      _row(Icons.store_mall_directory_outlined, 'Agency Name', p.agencyName),
                      _row(Icons.person_outline_rounded, 'Owner', p.ownerName),
                      _row(Icons.call_outlined, 'Contact', p.phone.isEmpty ? '' : '+91 ${p.phone}'),
                      _row(Icons.location_on_outlined, 'Address', p.address, last: true),
                    ]),
                  ),
                  const SizedBox(height: 26),
                  SectionTitle('Licences & Compliance', action: 'Edit', onAction: () => _openEdit(context)),
                  const SizedBox(height: 10),
                  DCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(children: [
                      _docRow(Icons.receipt_long_outlined, 'GST No. (GSTIN)', p.gstNo),
                      _docRow(Icons.badge_outlined, 'Trade Licence No.', p.tradeLicenseNo),
                      _docRow(Icons.verified_user_outlined, 'FSSAI Licence No.', p.fssaiNo, last: true),
                    ]),
                  ),
                  const SizedBox(height: 26),
                  const SectionTitle('Agency Controls'),
                  const SizedBox(height: 10),
                  const AgencyControlsCard(),
                  const SizedBox(height: 26),
                  const SectionTitle('Account Action'),
                  const SizedBox(height: 10),
                  DCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: InkWell(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Log out of agency?'),
                            content: const Text(
                              'You will need to enter your email and password to manage this distributor account again.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: DColors.red),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && onLogout != null) {
                          onLogout!();
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: DColors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.logout_rounded, color: DColors.red, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Log Out Agency Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: DColors.red,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sign out of this distributor session',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 90), // Bottom breathing room for floating navbar
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DistributorBusinessDetailsPage()));
  }

  Widget _missingDocsBanner(BuildContext context) {
    return InkWell(
      onTap: () => _openEdit(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DColors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DColors.red.withOpacity(0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.error_outline_rounded, color: DColors.red),
          SizedBox(width: 12),
          Expanded(
            child: Text('Add your GST, Trade Licence and FSSAI numbers to start receiving orders.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
          ),
          Icon(Icons.chevron_right_rounded, color: DColors.red),
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 21, color: AppColors.primary),
        const SizedBox(width: 14),
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(
          child: Text(value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ]),
    );
  }

  Widget _docRow(IconData icon, String label, String value, {bool last = false}) {
    final missing = value.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(children: [
        Icon(icon, size: 21, color: AppColors.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 3),
            Text(missing ? 'Not added' : value,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: missing ? DColors.red : AppColors.textPrimary,
                )),
          ]),
        ),
        missing
            ? const TagChip('Required', color: DColors.red)
            : const TagChip('Added', color: DColors.green, icon: Icons.check_rounded),
      ]),
    );
  }
}

/// Form for business details + GSTIN / Trade Licence / FSSAI.
/// Can also be used right after distributor sign-up as an onboarding step.
class DistributorBusinessDetailsPage extends StatefulWidget {
  const DistributorBusinessDetailsPage({super.key});

  @override
  State<DistributorBusinessDetailsPage> createState() => _DistributorBusinessDetailsPageState();
}

class _DistributorBusinessDetailsPageState extends State<DistributorBusinessDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _agency, _owner, _phone, _email, _address, _gst, _trade, _fssai;

  // GSTIN: 2-digit state code + 10-char PAN + entity no. + 'Z' + checksum
  static final _gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

  @override
  void initState() {
    super.initState();
    final p = DistributorController.instance.profile;
    _agency = TextEditingController(text: p.agencyName);
    _owner = TextEditingController(text: p.ownerName);
    _phone = TextEditingController(text: p.phone);
    _email = TextEditingController(text: p.email);
    _address = TextEditingController(text: p.address);
    _gst = TextEditingController(text: p.gstNo);
    _trade = TextEditingController(text: p.tradeLicenseNo);
    _fssai = TextEditingController(text: p.fssaiNo);
  }

  @override
  void dispose() {
    for (final t in [_agency, _owner, _phone, _email, _address, _gst, _trade, _fssai]) {
      t.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final c = DistributorController.instance;
    c.updateProfile(c.profile.copyWith(
      agencyName: _agency.text.trim(),
      ownerName: _owner.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      gstNo: _gst.text.trim().toUpperCase(),
      tradeLicenseNo: _trade.text.trim().toUpperCase(),
      fssaiNo: _fssai.text.trim(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business details saved')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DistributorHeader(
              title: 'Business Details',
              subtitle: 'These appear on every bill you print',
              showBack: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle('Agency'),
                const SizedBox(height: 12),
                _field(_agency, 'Agency name', Icons.store_mall_directory_outlined, validator: _required),
                _field(_owner, 'Owner name', Icons.person_outline_rounded, validator: _required),
                _field(_phone, 'Contact number', Icons.call_outlined,
                    keyboard: TextInputType.phone,
                    prefix: '+91 ',
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    validator: (v) => (v == null || v.trim().length != 10) ? 'Enter a 10-digit mobile number' : null),
                _field(_email, 'Email', Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress),
                _field(_address, 'Agency address', Icons.location_on_outlined, maxLines: 2, validator: _required),
                const SizedBox(height: 14),
                const SectionTitle('Licences & Compliance'),
                const SizedBox(height: 12),
                _field(_gst, 'GST No. (GSTIN)', Icons.receipt_long_outlined,
                    hint: 'e.g. 19ABCDE1234F1Z5',
                    caps: true,
                    formatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    validator: (v) {
                      final s = (v ?? '').trim().toUpperCase();
                      if (s.isEmpty) return 'GST number is required';
                      if (!_gstRegex.hasMatch(s)) return 'Enter a valid 15-character GSTIN';
                      return null;
                    }),
                _field(_trade, 'Trade Licence No.', Icons.badge_outlined,
                    caps: true, validator: (v) => _required(v, 'Trade licence number is required')),
                _field(_fssai, 'FSSAI Licence No.', Icons.verified_user_outlined,
                    hint: '14-digit number',
                    keyboard: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
                    validator: (v) => (v ?? '').trim().length != 14 ? 'FSSAI number must be 14 digits' : null),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Save Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? v, [String msg = 'This field is required']) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    String? prefix,
    int maxLines = 1,
    bool caps = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: formatters,
        textCapitalization: caps
            ? TextCapitalization.characters
            : (keyboard == null ? TextCapitalization.words : TextCapitalization.none),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}
