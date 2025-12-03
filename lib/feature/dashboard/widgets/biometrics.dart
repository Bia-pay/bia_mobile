import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class BiometricToggleSwitch extends StatefulWidget {
  const BiometricToggleSwitch({super.key});

  @override
  State<BiometricToggleSwitch> createState() => _BiometricToggleSwitchState();
}

class _BiometricToggleSwitchState extends State<BiometricToggleSwitch> {
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final box = await Hive.openBox('settings');
    final saved = box.get('biometric_enabled', defaultValue: false);
    setState(() => _isEnabled = saved);
    debugPrint("✅ Biometric setting loaded: $_isEnabled");
  }

  Future<void> _toggleBiometric(bool value) async {
    final box = await Hive.openBox('settings');
    await box.put('biometric_enabled', value);
    setState(() => _isEnabled = value);
    debugPrint(
      "🔐 Biometric authentication is now: ${value ? 'ENABLED' : 'DISABLED'}",
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Enable Biometric Authentication'),
      value: _isEnabled,
      onChanged: _toggleBiometric,
      activeColor: Colors.green,
    );
  }
}
