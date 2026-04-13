# Biometric User-Specific Flow Diagram

## Before Fix (Global Storage) ❌

```
Device Storage (settingsBox)
┌─────────────────────────────────┐
│ biometric_enabled: true         │ ← Global for all users
│ saved_pin: "1234"               │ ← Shared across users
│ login_biometric_enabled: true  │ ← Global for all users
│ biometric_login_password: "pwd"│ ← Shared across users
└─────────────────────────────────┘

User A logs in → Enables biometric
User A logs out
User B logs in → ❌ Inherits User A's biometric settings!
```

## After Fix (User-Specific Storage) ✅

```
Device Storage (settingsBox)
┌──────────────────────────────────────────┐
│ biometric_enabled_123: true             │ ← User A (userId=123)
│ saved_pin_123: "1234"                   │ ← User A's PIN
│ login_biometric_enabled_123: true      │ ← User A's login setting
│ biometric_login_password_123: "pwd_a"  │ ← User A's password
│                                          │
│ biometric_enabled_456: true             │ ← User B (userId=456)
│ saved_pin_456: "5678"                   │ ← User B's PIN
│ login_biometric_enabled_456: false     │ ← User B disabled login
│                                          │
│ biometric_enabled_789: false            │ ← User C (userId=789)
│                                          │ ← User C never enabled
└──────────────────────────────────────────┘

User A logs in → Checks biometric_enabled_123 → ✅ Enabled
User A logs out
User B logs in → Checks biometric_enabled_456 → ✅ Enabled (their own)
User B logs out
User C logs in → Checks biometric_enabled_789 → ✅ Disabled (as expected)
```

## Login Flow with User-Specific Biometric

```
┌─────────────────────────────────────────────────────────────┐
│                    User Logs In                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Backend validates credentials                               │
│  Returns: userId, token, user data                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Save to authBox:                                            │
│    - userId: "123"                                           │
│    - token: "abc..."                                         │
│    - phone, fullname, etc.                                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Migration Check (BiometricMigration)                        │
│  - Check if old global keys exist                            │
│  - If yes, copy to user-specific keys                        │
│  - biometric_enabled → biometric_enabled_123                 │
│  - saved_pin → saved_pin_123                                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  User navigates to Settings                                  │
│  - Load biometric_enabled_123 (user-specific)                │
│  - Load login_biometric_enabled_123 (user-specific)          │
│  - Display correct switch states                             │
└─────────────────────────────────────────────────────────────┘
```

## Enable Biometric Flow

```
┌─────────────────────────────────────────────────────────────┐
│  User taps "Enable Pay with Biometric" switch               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Navigate to EnableTransactionPinFingerprint screen          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  User enters 4-digit PIN                                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  BiometricHelper.enableTransactionBiometric(pin)             │
│  1. Get current userId from authBox                          │
│  2. Save to settingsBox:                                     │
│     - biometric_enabled_$userId = true                       │
│     - saved_pin_$userId = pin                                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Return to Settings                                          │
│  Switch shows enabled state                                  │
└─────────────────────────────────────────────────────────────┘
```

## Transaction with Biometric Flow

```
┌─────────────────────────────────────────────────────────────┐
│  User initiates transfer                                     │
│  Navigate to TransactionPin screen                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Check BiometricHelper.isTransactionBiometricEnabled()       │
│  - Gets userId from authBox                                  │
│  - Checks biometric_enabled_$userId                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                    ┌────┴────┐
                    │         │
              Enabled         Disabled
                    │         │
                    ▼         ▼
        ┌──────────────┐  ┌──────────────┐
        │ Show         │  │ Show only    │
        │ fingerprint  │  │ PIN keypad   │
        │ icon         │  │              │
        └──────┬───────┘  └──────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│  User taps fingerprint icon                                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  BiometricHelper.authenticate()                              │
│  - Device shows biometric prompt                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                    ┌────┴────┐
                    │         │
              Success      Failed
                    │         │
                    ▼         ▼
        ┌──────────────┐  ┌──────────────┐
        │ Get saved    │  │ Show error   │
        │ PIN from     │  │ message      │
        │ saved_pin_   │  │              │
        │ $userId      │  └──────────────┘
        └──────┬───────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│  Process transfer with retrieved PIN                         │
│  - Send to backend                                           │
│  - Show success/error                                        │
└─────────────────────────────────────────────────────────────┘
```

## Logout Flow

```
┌─────────────────────────────────────────────────────────────┐
│  User taps Logout                                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Get userId from authBox                                     │
│  Check login_biometric_enabled_$userId                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                    ┌────┴────┐
                    │         │
         Biometric Enabled   Disabled
                    │         │
                    ▼         ▼
        ┌──────────────┐  ┌──────────────┐
        │ Keep:        │  │ Clear all:   │
        │ - userId     │  │ - Everything │
        │ - phone      │  │   in authBox │
        │ - fullname   │  │              │
        │ - picture    │  └──────────────┘
        │ Clear:       │
        │ - token      │
        │ - refresh    │
        └──────┬───────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│  Navigate to:                                                │
│  - WelcomeBackScreen (if biometric enabled)                  │
│  - LoginScreen (if biometric disabled)                       │
└─────────────────────────────────────────────────────────────┘
```

## Multi-User Scenario

```
Timeline:

09:00 AM - User A (userId: 123) logs in
         ├─ Enables transaction biometric
         ├─ settingsBox: biometric_enabled_123 = true
         └─ settingsBox: saved_pin_123 = "1234"

10:00 AM - User A logs out
         └─ Settings remain in storage

10:30 AM - User B (userId: 456) logs in
         ├─ Checks biometric_enabled_456 → NOT FOUND
         ├─ Biometric switch shows DISABLED ✅
         └─ User B must enable their own biometric

11:00 AM - User B enables transaction biometric
         ├─ settingsBox: biometric_enabled_456 = true
         └─ settingsBox: saved_pin_456 = "5678"

12:00 PM - User B logs out
         └─ Settings remain in storage

02:00 PM - User A logs back in
         ├─ Checks biometric_enabled_123 → FOUND
         ├─ Biometric switch shows ENABLED ✅
         └─ Can use fingerprint with PIN "1234"

03:00 PM - User C (userId: 789) logs in
         ├─ Checks biometric_enabled_789 → NOT FOUND
         ├─ Biometric switch shows DISABLED ✅
         └─ Never enables biometric

Final State in settingsBox:
┌──────────────────────────────────────────┐
│ biometric_enabled_123: true             │ ← User A
│ saved_pin_123: "1234"                   │
│ biometric_enabled_456: true             │ ← User B
│ saved_pin_456: "5678"                   │
│ (no keys for User C)                    │ ← User C
└──────────────────────────────────────────┘

✅ Each user has independent settings
✅ No cross-contamination
✅ Settings persist correctly
```

## Key Takeaways

1. **User Isolation**: Each user's biometric settings are completely isolated
2. **Automatic Migration**: Old settings are automatically migrated on login
3. **Backward Compatible**: Existing users don't lose their settings
4. **Secure**: No user can access another user's biometric data
5. **Persistent**: Settings survive app restarts and device reboots
