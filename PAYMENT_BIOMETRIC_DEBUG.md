# Payment Biometric Debug Guide

## Issue
- Enable "Pay with Biometric" → Shows success message
- Switch doesn't turn ON
- Transaction screen says "biometric authentication not enabled"

## Root Cause Possibilities
1. **UserId mismatch** - Different userId between enable screen, settings screen, and transaction screen
2. **SharedPreferences not persisting** - Data not being saved correctly
3. **State not updating** - UI not refreshing after enable

## Debug Steps

### Step 1: Enable Payment Biometric
1. Go to Settings → Payment Settings → "Pay with [Biometric]"
2. Toggle ON
3. Enter your 4-digit PIN
4. Scan fingerprint
5. Check console for these logs:

```
🔐 ENABLE PAYMENT BIOMETRIC:
   - userId from authBox: [userId]
   - phone from authBox: [phone]
   - effectiveUserId: [effectiveUserId]
🔐 Attempting to enable payment biometric for user: [effectiveUserId]
🔐 Entered PIN length: 4
🔐 Biometric not available
🔐 Biometric auth result: true
🔐 Transaction PIN saved securely for user: [effectiveUserId]
🔐 Payment biometric enabled for user: [effectiveUserId]
🔐 Verification - actual value in SharedPreferences: true
🔐 Key used: biometric_payment_enabled_[effectiveUserId]
✅ Payment biometric enabled for user: [effectiveUserId]
🔐 Enable payment biometric result: true
🔐 Verification after enable:
   - isEnabled: true
   - hasSavedPin: true
```

**CRITICAL**: Note the exact `effectiveUserId` value

### Step 2: Check Settings Screen Reload
After returning to settings, check for:

```
🔐 Returned from enable screen with result: true
🔄 Loading biometric settings for userId: [userId]
🔐 isPaymentEnabled([userId]) = true (key: biometric_payment_enabled_[userId])
🔄 Biometric settings reloaded: login=..., payment=true
```

**CRITICAL**: Compare the userId here with Step 1 - they MUST match

### Step 3: Check Transaction Screen
1. Go to Dashboard → Send Money
2. Enter amount and recipient
3. On transaction PIN screen, check console:

```
🔐 TransactionPinSecure - Initializing:
   - userId from authBox: [userId]
   - phone from authBox: [phone]
   - effectiveUserId: [effectiveUserId]
🔐 isPaymentEnabled([effectiveUserId]) = true (key: biometric_payment_enabled_[effectiveUserId])
🔐 Biometric initialized:
   - Available: true
   - Enabled: true
   - Has saved PIN: true
   - Type: Fingerprint
```

**CRITICAL**: Compare the userId here with Steps 1 & 2 - they MUST all match

## Common Issues

### Issue A: UserId Mismatch
**Symptom**: Different userId values in Step 1, 2, and 3
**Example**: 
- Step 1 uses: `+1234567890` (phone)
- Step 2 uses: `12345` (userId)
- Step 3 uses: `+1234567890` (phone)

**Fix**: Standardize userId retrieval across all screens

### Issue B: SharedPreferences Not Persisting
**Symptom**: Step 1 shows `Verification - actual value: true` but Step 2 shows `false`
**Fix**: SharedPreferences issue - may need to use `await prefs.reload()` before reading

### Issue C: State Not Updating
**Symptom**: Logs show `payment=true` but switch is OFF
**Fix**: UI state issue - need to force rebuild

## Quick Test

Add this temporary code to `account_settings.dart` in `_loadBiometricSetting()`:

```dart
// After getting loginEnabled and paymentEnabled
final prefs = await SharedPreferences.getInstance();
final allKeys = prefs.getKeys().where((k) => k.contains('biometric')).toList();
debugPrint('📋 All biometric keys in SharedPreferences: $allKeys');
for (var key in allKeys) {
  debugPrint('   $key = ${prefs.get(key)}');
}
```

This will show ALL biometric preferences stored.

## Expected Full Flow Logs

```
// === ENABLE FLOW ===
🔐 ENABLE PAYMENT BIOMETRIC:
   - userId from authBox: 12345
   - phone from authBox: +1234567890
   - effectiveUserId: 12345
🔐 Attempting to enable payment biometric for user: 12345
🔐 Entered PIN length: 4
🔐 Biometric auth result: true
🔐 Transaction PIN saved securely for user: 12345
🔐 Payment biometric enabled for user: 12345
🔐 Verification - actual value in SharedPreferences: true
🔐 Key used: biometric_payment_enabled_12345
✅ Payment biometric enabled for user: 12345
🔐 Enable payment biometric result: true
🔐 Verification after enable:
   - isEnabled: true
   - hasSavedPin: true

// === SETTINGS RELOAD ===
🔐 Returned from enable screen with result: true
🔄 Loading biometric settings for userId: 12345
🔐 isPaymentEnabled(12345) = true (key: biometric_payment_enabled_12345)
🔄 Biometric settings reloaded: login=false, payment=true

// === TRANSACTION SCREEN ===
🔐 TransactionPinSecure - Initializing:
   - userId from authBox: 12345
   - phone from authBox: +1234567890
   - effectiveUserId: 12345
🔐 isPaymentEnabled(12345) = true (key: biometric_payment_enabled_12345)
🔐 Biometric initialized:
   - Available: true
   - Enabled: true
   - Has saved PIN: true
   - Type: Fingerprint
```

## Action Required

Please run the test flow and share the COMPLETE console output. The logs will reveal:
1. If userId is consistent across all screens
2. If SharedPreferences is actually saving the data
3. If the state is being loaded correctly

Copy ALL logs from the console and share them.
