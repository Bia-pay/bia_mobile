# Payment Biometric Debug Guide

## Issue
"Pay with Biometric" shows success message but:
1. Switch doesn't turn ON in settings
2. Transaction screen says "biometric authentication not enabled"

## Debug Flow

### Step 1: Enable Payment Biometric
When you tap the switch and enter PIN, check console for:

```
🔐 Attempting to enable payment biometric for user: [userId]
🔐 Entered PIN length: 4
🔐 Payment biometric enabled for user: [userId]  ← From BiometricService
🔐 Enable payment biometric result: true
🔐 Verification after enable:
   - isEnabled: true
   - hasSavedPin: true
🔄 Biometric settings reloaded: login=X, payment=true  ← From account_settings
```

### Step 2: Check Switch State
After returning to settings, the switch should show ON. Check console for:

```
🔄 Biometric settings reloaded: login=X, payment=true
```

If you see `payment=false`, the preference isn't being saved correctly.

### Step 3: Transaction Screen
When you open transaction screen, check console for:

```
🔐 TransactionPinSecure - Initializing for user: [userId]
🔐 Biometric initialized:
   - User ID: [userId]
   - Available: true
   - Enabled: true  ← Should be true
   - Has saved PIN: true  ← Should be true
   - Type: Fingerprint
```

If `Enabled: false` or `Has saved PIN: false`, something went wrong.

## Common Issues & Fixes

### Issue 1: Switch doesn't turn ON
**Cause**: FutureBuilder not rebuilding after enable
**Fix**: Added `_switchRebuildKey` that increments on reload
**Verify**: Check if `_switchRebuildKey` increments in console

### Issue 2: Transaction screen says not enabled
**Cause**: Different userId being used
**Verify**: 
```dart
// In enable screen
debugPrint('Enable userId: $effectiveUserId');

// In transaction screen  
debugPrint('Transaction userId: $effectiveUserId');

// Should be THE SAME
```

### Issue 3: PIN not saved
**Cause**: FlutterSecureStorage permission issue
**Fix**: Check if PIN is actually being saved
**Verify**:
```dart
final pin = await biometricService.getTransactionPin(userId);
debugPrint('Saved PIN exists: ${pin != null}');
```

## Manual Verification Steps

### Verify SharedPreferences
Add this debug button temporarily:

```dart
ElevatedButton(
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    final authBox = await Hive.openBox('authBox');
    final userId = authBox.get('userId', defaultValue: '');
    
    print('=== PREFERENCES DEBUG ===');
    print('UserId: $userId');
    print('Payment enabled: ${prefs.getBool('biometric_payment_enabled_$userId')}');
    print('Login enabled: ${prefs.getBool('biometric_login_enabled_$userId')}');
    print('All keys: ${prefs.getKeys()}');
  },
  child: Text('DEBUG PREFS'),
)
```

### Verify SecureStorage
Add this debug button:

```dart
ElevatedButton(
  onPressed: () async {
    final biometricService = BiometricService();
    final authBox = await Hive.openBox('authBox');
    final userId = authBox.get('userId', defaultValue: '');
    
    final pin = await biometricService.getTransactionPin(userId);
    final password = await biometricService.getLoginPassword(userId);
    
    print('=== SECURE STORAGE DEBUG ===');
    print('UserId: $userId');
    print('Has transaction PIN: ${pin != null}');
    print('Has login password: ${password != null}');
  },
  child: Text('DEBUG STORAGE'),
)
```

## Expected Console Output (Success Flow)

### 1. Enable Payment Biometric
```
🔐 Attempting to enable payment biometric for user: 12345
🔐 Entered PIN length: 4
🔐 Transaction PIN saved securely for user: 12345
🔐 Payment biometric enabled for user: 12345
🔐 Enable payment biometric result: true
🔐 Verification after enable:
   - isEnabled: true
   - hasSavedPin: true
✅ Payment biometric enabled for user: 12345
🔄 Biometric settings reloaded: login=true, payment=true
```

### 2. Open Transaction Screen
```
🔐 TransactionPinSecure - Initializing for user: 12345
🔐 Biometric initialized:
   - User ID: 12345
   - Available: true
   - Enabled: true
   - Has saved PIN: true
   - Type: Fingerprint
```

### 3. Tap Biometric Button
```
✅ Biometric authentication successful, processing transfer...
```

## Quick Fix Checklist

- [ ] Console shows "Payment biometric enabled for user: X"
- [ ] Console shows "isEnabled: true" after verification
- [ ] Console shows "hasSavedPin: true" after verification
- [ ] Console shows "_switchRebuildKey" incrementing
- [ ] Console shows "payment=true" in settings reload
- [ ] Transaction screen shows "Enabled: true"
- [ ] Transaction screen shows "Has saved PIN: true"
- [ ] Same userId in all logs

## If Still Not Working

1. **Clear app data completely** and test fresh
2. **Check userId consistency** - print it everywhere
3. **Verify FlutterSecureStorage** permissions in AndroidManifest.xml/Info.plist
4. **Check SharedPreferences** - maybe it's not persisting
5. **Add breakpoints** in BiometricService.enablePaymentBiometric()

## Next Steps

Run the app and follow the debug flow above. Share the console output and I can pinpoint the exact issue.
