import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/biometric_service.dart';

/// Temporary debug widget to test biometric service
/// Add this to your settings screen to debug payment biometric issues
class BiometricDebugWidget extends StatelessWidget {
  const BiometricDebugWidget({super.key});

  Future<Map<String, dynamic>> _getDebugInfo() async {
    final authBox = await Hive.openBox('authBox');
    final userId = authBox.get('userId', defaultValue: '');
    final phone = authBox.get('phone', defaultValue: '');
    final effectiveUserId = userId.isNotEmpty ? userId : phone;

    final biometricService = BiometricService();
    final prefs = await SharedPreferences.getInstance();

    // Check all states
    final loginEnabled = await biometricService.isLoginEnabled(effectiveUserId);
    final paymentEnabled = await biometricService.isPaymentEnabled(effectiveUserId);
    final hasLoginPassword = await biometricService.getLoginPassword(effectiveUserId);
    final hasTransactionPin = await biometricService.getTransactionPin(effectiveUserId);
    
    // Check raw preferences
    final rawLoginPref = prefs.getBool('biometric_login_enabled_$effectiveUserId');
    final rawPaymentPref = prefs.getBool('biometric_payment_enabled_$effectiveUserId');

    return {
      'userId': userId,
      'phone': phone,
      'effectiveUserId': effectiveUserId,
      'loginEnabled': loginEnabled,
      'paymentEnabled': paymentEnabled,
      'hasLoginPassword': hasLoginPassword != null,
      'hasTransactionPin': hasTransactionPin != null,
      'rawLoginPref': rawLoginPref,
      'rawPaymentPref': rawPaymentPref,
      'allPrefsKeys': prefs.getKeys().where((k) => k.contains(effectiveUserId)).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🔍 Biometric Debug Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final info = await _getDebugInfo();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Biometric Debug'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('User ID: ${info['userId']}'),
                            Text('Phone: ${info['phone']}'),
                            Text('Effective ID: ${info['effectiveUserId']}'),
                            const Divider(),
                            Text('Login Enabled: ${info['loginEnabled']}'),
                            Text('Payment Enabled: ${info['paymentEnabled']}'),
                            const Divider(),
                            Text('Has Login Password: ${info['hasLoginPassword']}'),
                            Text('Has Transaction PIN: ${info['hasTransactionPin']}'),
                            const Divider(),
                            Text('Raw Login Pref: ${info['rawLoginPref']}'),
                            Text('Raw Payment Pref: ${info['rawPaymentPref']}'),
                            const Divider(),
                            const Text('Pref Keys:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...((info['allPrefsKeys'] as List).map((k) => Text('  - $k'))),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Show Debug Info'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                final authBox = await Hive.openBox('authBox');
                final userId = authBox.get('userId', defaultValue: '');
                final phone = authBox.get('phone', defaultValue: '');
                final effectiveUserId = userId.isNotEmpty ? userId : phone;

                final biometricService = BiometricService();
                
                // Force enable payment biometric
                await biometricService.setPaymentEnabled(effectiveUserId, true);
                await biometricService.saveTransactionPin(effectiveUserId, '1234');
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Force enabled payment biometric with PIN 1234'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Force Enable Payment (Test PIN: 1234)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final authBox = await Hive.openBox('authBox');
                final userId = authBox.get('userId', defaultValue: '');
                final phone = authBox.get('phone', defaultValue: '');
                final effectiveUserId = userId.isNotEmpty ? userId : phone;

                final biometricService = BiometricService();
                await biometricService.completeReset(effectiveUserId);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete biometric reset done'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Reset All Biometric Data'),
            ),
          ],
        ),
      ),
    );
  }
}
