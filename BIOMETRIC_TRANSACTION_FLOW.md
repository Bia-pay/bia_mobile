# Biometric Transaction Flow - Visual Guide

## User Journey

### Scenario 1: First Time Setup

```
┌─────────────────────────────────────┐
│   Settings > Account Settings       │
│   > Security Settings               │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Toggle "Pay with Fingerprint" ON   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Enter Transaction PIN Screen       │
│  [Enter your 4-digit PIN]           │
│  [ ] [ ] [ ] [ ]                    │
│                                     │
│  [Keypad: 1 2 3 4 5 6 7 8 9 0]     │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  ✅ Fingerprint enabled!            │
│  PIN saved securely                 │
└─────────────────────────────────────┘
```

### Scenario 2: Making a Transaction (Biometric Enabled)

```
┌─────────────────────────────────────┐
│   Send Money Flow                   │
│   Enter recipient & amount          │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Transaction PIN Screen            │
│                                     │
│   🔒 Enter Transaction PIN          │
│                                     │
│   You can use your Fingerprint      │
│   for faster confirmation           │
│                                     │
│   ● ● ● ●  (PIN dots)              │
│                                     │
│   [Keypad: 1 2 3 4 5 6 7 8 9]      │
│   [⌫]  [0]  [👆 Fingerprint]       │
└─────────────────────────────────────┘
              ↓
         User taps 👆
              ↓
┌─────────────────────────────────────┐
│   📱 Device Biometric Prompt        │
│                                     │
│   "Authenticate to complete         │
│    transaction"                     │
│                                     │
│   [Place finger on sensor]          │
└─────────────────────────────────────┘
              ↓
         ✅ Success
              ↓
┌─────────────────────────────────────┐
│   Transaction Processing...         │
│   Using saved PIN                   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   ✅ Transaction Successful!        │
└─────────────────────────────────────┘
```

### Scenario 3: Making a Transaction (Manual PIN)

```
┌─────────────────────────────────────┐
│   Transaction PIN Screen            │
│                                     │
│   🔒 Enter Transaction PIN          │
│                                     │
│   ● ● ○ ○  (2 digits entered)      │
│                                     │
│   [Keypad: 1 2 3 4 5 6 7 8 9]      │
│   [⌫]  [0]  [👆 Fingerprint]       │
└─────────────────────────────────────┘
              ↓
    User enters 4 digits
              ↓
┌─────────────────────────────────────┐
│   ● ● ● ●  (4 digits entered)      │
│                                     │
│   [Keypad: 1 2 3 4 5 6 7 8 9]      │
│   [⌫]  [0]  [👆 Fingerprint]       │
└─────────────────────────────────────┘
              ↓
    User taps 👆 (or ✓ if disabled)
              ↓
┌─────────────────────────────────────┐
│   Transaction Processing...         │
│   Using entered PIN                 │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   ✅ Transaction Successful!        │
└─────────────────────────────────────┘
```

### Scenario 4: Biometric Not Available

```
┌─────────────────────────────────────┐
│   Transaction PIN Screen            │
│                                     │
│   🔒 Enter Transaction PIN          │
│                                     │
│   ● ○ ○ ○  (1 digit entered)       │
│                                     │
│   [Keypad: 1 2 3 4 5 6 7 8 9]      │
│   [⌫]  [0]  [✓ Confirm]            │
│                                     │
│   (Checkmark shown instead of       │
│    fingerprint icon)                │
└─────────────────────────────────────┘
```

## UI States

### Right Action Button States

| Condition | Icon | Background | Action |
|-----------|------|------------|--------|
| Biometric enabled & available | 👆 Fingerprint SVG | Transparent | Trigger biometric auth |
| Biometric authenticating | ⏳ Loading spinner | Transparent | Disabled |
| Biometric disabled/unavailable | ✓ Checkmark | Primary color | Process with manual PIN |

## Code Flow

```
initState()
    ↓
_initializeBiometric()
    ↓
Check device capabilities
    ↓
Load user settings
    ↓
Update UI state
    ↓
User interaction
    ↓
┌─────────────────┬─────────────────┐
│  Tap Fingerprint│  Enter PIN      │
│  Icon           │  Manually       │
└────────┬────────┴────────┬────────┘
         ↓                 ↓
_authenticateWith    _processTransfer()
Biometric()              ↓
         ↓          Validate PIN
Device biometric         ↓
prompt              _processTransferWith
         ↓          Pin(enteredPin)
If success              ↓
         ↓          ┌────┴────┐
_processTransferWith│         │
Pin(savedPin)       │         │
         ↓          ↓         ↓
         └──────────┴─────────┘
                    ↓
            API call to send money
                    ↓
            Navigate to success screen
```

## Error Handling Flow

```
User taps biometric icon
         ↓
Check prerequisites
         ↓
┌────────┴────────┐
│ All checks pass │
└────────┬────────┘
         ↓
Trigger biometric
         ↓
┌────────┴────────────────────┐
│                             │
✅ Success              ❌ Failure
│                             │
Process transaction     Show error message
│                             │
Navigate to success     Allow retry
```

## Integration Points

### 1. BiometricHelper Service
- Centralized biometric logic
- Used across the app (login, transactions, etc.)
- Handles device compatibility

### 2. Hive Storage
- Secure local storage
- Stores user preferences
- Stores encrypted PIN

### 3. Dashboard Controller
- Handles transaction API calls
- Manages transaction state
- Processes responses

### 4. Router
- Navigation flow
- Success/error screens
- Deep linking support

## Testing Scenarios

1. ✅ Device with fingerprint sensor
2. ✅ Device with Face ID
3. ✅ Device without biometric
4. ✅ Biometric enabled in settings
5. ✅ Biometric disabled in settings
6. ✅ Biometric authentication success
7. ✅ Biometric authentication failure
8. ✅ Manual PIN entry
9. ✅ Wrong PIN entered
10. ✅ Network error during transaction
11. ✅ App backgrounded during authentication
12. ✅ Multiple rapid taps on biometric icon
