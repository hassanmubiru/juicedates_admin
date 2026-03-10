import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class AppConfigScreen extends StatefulWidget {
  const AppConfigScreen({super.key});
  @override
  State<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends State<AppConfigScreen> {
  final _svc = AdminService();
  late Future<AppConfig> _configFuture;

  @override
  void initState() {
    super.initState();
    _configFuture = _svc.getAppConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        elevation: 0,
        title: const Text('App Config',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kMuted),
            tooltip: 'Reload',
            onPressed: () =>
                setState(() => _configFuture = _svc.getAppConfig()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<AppConfig>(
        future: _configFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kTangerine));
          }
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style: const TextStyle(color: kDanger)));
          }
          return _ConfigForm(
            config: snap.data ?? const AppConfig(),
            svc: _svc,
            onSaved: () =>
                setState(() => _configFuture = _svc.getAppConfig()),
          );
        },
      ),
    );
  }
}

class _ConfigForm extends StatefulWidget {
  final AppConfig config;
  final AdminService svc;
  final VoidCallback onSaved;
  const _ConfigForm(
      {required this.config, required this.svc, required this.onSaved});
  @override
  State<_ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<_ConfigForm> {
  late bool _maintenanceMode;
  late bool _registrationEnabled;
  late bool _photoVerificationRequired;
  late bool _ageVerificationRequired;
  late TextEditingController _freeLikesCtrl;
  late TextEditingController _premiumLikesCtrl;
  late TextEditingController _boostDurationCtrl;
  late TextEditingController _boostPriceCtrl;
  late TextEditingController _premiumPriceCtrl;
  late TextEditingController _minAgeCtrl;
  late TextEditingController _maxAgeCtrl;
  late TextEditingController _maxDistCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    _maintenanceMode = c.maintenanceMode;
    _registrationEnabled = c.registrationEnabled;
    _photoVerificationRequired = c.photoVerificationRequired;
    _ageVerificationRequired = c.ageVerificationRequired;
    _freeLikesCtrl = TextEditingController(text: '${c.freeDailyLikes}');
    _premiumLikesCtrl =
        TextEditingController(text: '${c.premiumDailyLikes}');
    _boostDurationCtrl =
        TextEditingController(text: '${c.boostDurationMinutes}');
    _boostPriceCtrl =
        TextEditingController(text: c.boostPriceUsd.toStringAsFixed(2));
    _premiumPriceCtrl = TextEditingController(
        text: c.premiumMonthlyUsd.toStringAsFixed(2));
    _minAgeCtrl = TextEditingController(text: '${c.minAge}');
    _maxAgeCtrl = TextEditingController(text: '${c.maxAge}');
    _maxDistCtrl =
        TextEditingController(text: c.maxDistanceKm.toStringAsFixed(0));
  }

  @override
  void dispose() {
    for (final c in [
      _freeLikesCtrl, _premiumLikesCtrl, _boostDurationCtrl,
      _boostPriceCtrl, _premiumPriceCtrl, _minAgeCtrl, _maxAgeCtrl, _maxDistCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = AppConfig(
      maintenanceMode: _maintenanceMode,
      registrationEnabled: _registrationEnabled,
      photoVerificationRequired: _photoVerificationRequired,
      ageVerificationRequired: _ageVerificationRequired,
      freeDailyLikes: int.tryParse(_freeLikesCtrl.text) ?? 20,
      premiumDailyLikes: int.tryParse(_premiumLikesCtrl.text) ?? 999,
      boostDurationMinutes: int.tryParse(_boostDurationCtrl.text) ?? 30,
      boostPriceUsd: double.tryParse(_boostPriceCtrl.text) ?? 3.99,
      premiumMonthlyUsd: double.tryParse(_premiumPriceCtrl.text) ?? 9.99,
      minAge: int.tryParse(_minAgeCtrl.text) ?? 18,
      maxAge: int.tryParse(_maxAgeCtrl.text) ?? 65,
      maxDistanceKm: double.tryParse(_maxDistCtrl.text) ?? 100,
    );
    await widget.svc.saveAppConfig(updated);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Config saved ✓'), backgroundColor: kSuccess),
      );
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(builder: (ctx, box) {
        final wide = box.maxWidth >= 800;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App-wide toggles
            _SectionHeader(
                icon: Icons.settings_rounded, label: 'App Switches'),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _SwitchTile(
                    title: 'Maintenance Mode',
                    subtitle: 'Show maintenance page to all users',
                    value: _maintenanceMode,
                    icon: Icons.construction_rounded,
                    activeColor: kDanger,
                    onChanged: (v) => setState(() => _maintenanceMode = v),
                  ),
                  const Divider(color: kBorder, height: 1),
                  _SwitchTile(
                    title: 'Registration Enabled',
                    subtitle: 'Allow new accounts to be created',
                    value: _registrationEnabled,
                    icon: Icons.how_to_reg_rounded,
                    activeColor: kSuccess,
                    onChanged: (v) =>
                        setState(() => _registrationEnabled = v),
                  ),
                  const Divider(color: kBorder, height: 1),
                  _SwitchTile(
                    title: 'Photo Verification Required',
                    subtitle: 'Users must pass photo review before matching',
                    value: _photoVerificationRequired,
                    icon: Icons.verified_user_rounded,
                    activeColor: kTangerine,
                    onChanged: (v) =>
                        setState(() => _photoVerificationRequired = v),
                  ),
                  const Divider(color: kBorder, height: 1),
                  _SwitchTile(
                    title: 'Age Verification Required',
                    subtitle: 'Enforce 18+ check on sign-up',
                    value: _ageVerificationRequired,
                    icon: Icons.cake_rounded,
                    activeColor: kWarning,
                    onChanged: (v) =>
                        setState(() => _ageVerificationRequired = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            _SectionHeader(
                icon: Icons.favorite_border_rounded,
                label: 'Likes & Boosts'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _NumField(
                  label: 'Free Daily Likes',
                  controller: _freeLikesCtrl,
                  width: wide ? 180 : double.infinity,
                ),
                _NumField(
                  label: 'Premium Daily Likes',
                  controller: _premiumLikesCtrl,
                  width: wide ? 180 : double.infinity,
                ),
                _NumField(
                  label: 'Boost Duration (min)',
                  controller: _boostDurationCtrl,
                  width: wide ? 180 : double.infinity,
                ),
                _NumField(
                  label: 'Boost Price (USD)',
                  controller: _boostPriceCtrl,
                  width: wide ? 180 : double.infinity,
                  isDecimal: true,
                ),
              ],
            ),

            const SizedBox(height: 28),
            _SectionHeader(
                icon: Icons.star_rounded, label: 'Subscription Pricing'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _NumField(
                  label: 'Premium / month (USD)',
                  controller: _premiumPriceCtrl,
                  width: wide ? 220 : double.infinity,
                  isDecimal: true,
                ),
              ],
            ),

            const SizedBox(height: 28),
            _SectionHeader(
                icon: Icons.tune_rounded,
                label: 'Discovery Settings'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _NumField(
                    label: 'Min Age',
                    controller: _minAgeCtrl,
                    width: wide ? 140 : double.infinity),
                _NumField(
                    label: 'Max Age',
                    controller: _maxAgeCtrl,
                    width: wide ? 140 : double.infinity),
                _NumField(
                    label: 'Max Distance (km)',
                    controller: _maxDistCtrl,
                    width: wide ? 180 : double.infinity,
                    isDecimal: true),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving…' : 'Save Configuration'),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kTangerine, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.activeColor,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
      secondary: Icon(icon, color: value ? activeColor : kMuted, size: 20),
      title:
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: kMuted, fontSize: 12)),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double width;
  final bool isDecimal;
  const _NumField({
    required this.label,
    required this.controller,
    this.width = double.infinity,
    this.isDecimal = false,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType:
            TextInputType.numberWithOptions(decimal: isDecimal),
        inputFormatters: [
          if (isDecimal)
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          else
            FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
