# Payment Biometric Switch Fix

## Problem
When enabling "Pay with Biometric":
- Success message appears
- Switch doesn't turn ON
- Transaction screen says "biometric authentication not enabled"

## Root Cause
The switch UI was using nested FutureBuilders that weren't properly rebuilding when returning from the enable screen. The FutureBuilder was caching the old state and not responding to the `setState()` call.

## Solution Implemented
Replaced complex nested FutureBuilders with direct state variables:

1. **Removed**: `_switchRebuildKey` counter (wasn't working)
2. **Simplified**: Switch now directly uses `biometricEnabled` and `loginBiometricEnabled` state variables
3. **Fixed**: `_loadBiometricSetting()` now properly updates state with `mounted` check
4. **Improved**: Switch logic is cleaner and more predictable

## Changes Made

### `lib/feature/settings/presentation/account_settings.dart`
- Removed nested FutureBuilder complexity
- Switch now reads from state variables directly: `loginBiometricEnabled` and `biometricEnabled`
- Both enable and disable flows now call `_loadBiometricSetting()` to refresh state
- Added `mounted` check before `setState()` to prevent errors

## Testing Steps

1. **Enable Payment Biometric**:
   ```
   Settings → Payment Settings → Pay with [Biometric]
   Toggle ON → Enter PIN → Authenticate with biometric
   ```
   Expected: Switch turns ON immediately after returning

2. **Verify in Transaction**:
   ```
   Dashboard → Send Money → Enter amount → Enter recipient
   Transaction PIN screen should show biometric icon
   ```
   Expected: Biometric icon appears and works

3. **Disable Payment Biometric**:
   ```
   Settings → Payment Settings → Pay with [Biometric]
   Toggle OFF
   ```
   Expected: Switch turns OFF immediately

4. **Check Console Logs**:
   Look for these debug prints:
   ```
   🔐 Attempting to enable payment biometric for user: [userId]
   🔐 Enable payment biometric result: true
   🔐 Verification after enable:
      - isEnabled: true
      - hasSavedPin: true
   🔐 Payment biometric enabled for user: [userId]
   🔄 Biometric settings reloaded: login=false, payment=true
   ```

## Debug Commands

If still not working, check SharedPreferences:
```dart
final prefs = await SharedPreferences.getInstance();
final keys = prefs.getKeys();
print('All keys: $keys');
print('Payment enabled: ${prefs.getBool('biometric_payment_enabled_[userId]')}');
```

Check FlutterSecureStorage:
```dart
final storage = FlutterSecureStorage();
final pin = await storage.read(key: 'biometric_transaction_pin_[userId]');
print('Saved PIN exists: ${pin != null}');
```
