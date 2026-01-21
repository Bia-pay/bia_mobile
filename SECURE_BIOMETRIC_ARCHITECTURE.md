# Secure Biometric Authentication Architecture

## ⚠️ Critical Security Principles

### What Biometric Authentication IS:
- ✅ A convenient way to unlock stored credentials
- ✅ Device-level authentication (OS verifies the user)
- ✅ A shortcut to avoid typing PIN/password
- ✅ Protection against unauthorized device access

### What Biometric Authentication IS NOT:
- ❌ NOT a replacement for backend validation
- ❌ NOT a way to authorize transactions directly
- ❌ NOT a substitute for proper authentication tokens
- ❌ NOT secure if it bypasses backend verification

## 🔒 Secure Implementation Flow

### Setup Phase (One-Time)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User Enables Biometric                                   │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. User Enters PIN                                          │
│    [User types: 1234]                                       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. App Sends PIN to Backend for Validation                 │
│    POST /api/auth/validate-pin                              │
│    Body: { "pin": "1234" }                                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Backend Validates PIN                                    │
│    - Checks against stored hash                             │
│    - Verifies user identity                                 │
│    - Generates secure token                                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Backend Returns Secure Token                             │
│    Response: {                                              │
│      "success": true,                                       │
│      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."    │
│    }                                                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. App Encrypts and Stores Token Locally                   │
│    - Token is encrypted (NOT plain text)                   │
│    - Stored in secure storage (Hive/Keychain)              │
│    - PIN is NEVER stored                                   │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Biometric Enabled ✅                                     │
└─────────────────────────────────────────────────────────────┘
```

### Transaction Phase (Every Time)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User Initiates Transaction                               │
│    Send $100 to John Doe                                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. App Shows Transaction PIN Screen                         │
│    Options:                                                 │
│    - Enter PIN manually                                     │
│    - Use biometric (if enabled)                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. User Taps Biometric Icon                                 │
│    👆 Fingerprint / 🔐 Face ID                              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. OS Performs Biometric Authentication                     │
│    - Fingerprint scan / Face recognition                    │
│    - OS validates biometric data                            │
│    - Returns success/failure to app                         │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. If Biometric Success → App Retrieves Stored Token       │
│    - Decrypts the token                                     │
│    - Token is ready to use                                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. App Sends Transaction Request with Token                 │
│    POST /api/transactions/send                              │
│    Headers: { "Authorization": "Bearer <token>" }           │
│    Body: {                                                  │
│      "recipient": "1234567890",                             │
│      "amount": 100,                                         │
│      "narration": "Payment"                                 │
│    }                                                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Backend Validates Token                                  │
│    - Verifies token signature                               │
│    - Checks token expiration                                │
│    - Validates user permissions                             │
│    - Authorizes transaction                                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. Backend Processes Transaction                            │
│    - Debits sender account                                  │
│    - Credits recipient account                              │
│    - Returns success response                               │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 9. App Shows Success Screen ✅                              │
└─────────────────────────────────────────────────────────────┘
```

## 🚨 Security Vulnerabilities in Current Implementation

### ❌ INSECURE: Storing Plain PIN

```dart
// DON'T DO THIS!
await box.put('saved_pin', userPin); // ❌ Plain PIN stored
```

**Why it's insecure:**
- Anyone with device access can read the PIN
- Malware can steal the PIN
- No backend validation
- Biometric becomes meaningless

### ❌ INSECURE: Using PIN Directly After Biometric

```dart
// DON'T DO THIS!
final savedPin = await getSavedPin(); // ❌ Retrieves plain PIN
if (biometricSuccess) {
  processTransaction(savedPin); // ❌ No backend validation
}
```

**Why it's insecure:**
- Biometric bypasses backend security
- No server-side authorization
- Transaction approved without backend knowing
- Vulnerable to local attacks

## ✅ Secure Implementation

### Secure Token Storage

```dart
// DO THIS!
class SecureBiometricService {
  // Store encrypted token (NOT PIN)
  static Future<bool> enableBiometricTransaction({
    required String authToken, // Token from backend, NOT PIN
  }) async {
    final box = await Hive.openBox('secureBiometricBox');
    final salt = _generateSalt();
    final encryptedToken = _encryptToken(authToken, salt);
    
    await box.put('biometric_auth_token', encryptedToken);
    await box.put('biometric_salt', salt);
    await box.put('biometric_enabled', true);
    
    return true;
  }
}
```

### Secure Transaction Flow

```dart
// DO THIS!
Future<void> authenticateWithBiometric() async {
  // 1. Authenticate with device biometric
  final authenticated = await LocalAuthentication.authenticate(
    localizedReason: 'Authenticate to complete transaction',
  );
  
  if (!authenticated) return;
  
  // 2. Retrieve encrypted token (NOT PIN)
  final authToken = await SecureBiometricService.getAuthTokenWithBiometric();
  
  if (authToken == null) return;
  
  // 3. Send token to backend for validation
  final response = await apiClient.post('/api/transactions/send', {
    'recipient': recipientAccount,
    'amount': amount,
    'narration': narration,
  }, headers: {
    'Authorization': 'Bearer $authToken', // Backend validates this
  });
  
  // 4. Backend authorizes transaction
  if (response.success) {
    showSuccessScreen();
  }
}
```

## 🔐 Backend Requirements

### Required API Endpoints

#### 1. Validate PIN and Generate Token

```
POST /api/auth/validate-pin
Request:
{
  "pin": "1234"
}

Response:
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 2592000 // 30 days
}
```

#### 2. Authorize Transaction with Token

```
POST /api/transactions/send
Headers:
{
  "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

Request:
{
  "recipient": "1234567890",
  "amount": 100,
  "narration": "Payment"
}

Response:
{
  "success": true,
  "transactionId": "TXN123456",
  "message": "Transaction successful"
}
```

## 📊 Security Comparison

| Aspect | ❌ Insecure (Current) | ✅ Secure (Recommended) |
|--------|----------------------|-------------------------|
| **PIN Storage** | Plain text in Hive | Never stored |
| **Token Storage** | None | Encrypted token |
| **Biometric Role** | Authorizes transaction | Unlocks token only |
| **Backend Validation** | None | Every transaction |
| **Attack Surface** | High (local PIN theft) | Low (token-based) |
| **Token Expiration** | N/A | Yes (30 days) |
| **Revocation** | Impossible | Easy (invalidate token) |
| **Audit Trail** | None | Full backend logs |

## 🛠️ Implementation Checklist

### Phase 1: Backend Setup
- [ ] Create `/api/auth/validate-pin` endpoint
- [ ] Implement JWT token generation
- [ ] Add token validation middleware
- [ ] Update transaction endpoints to accept tokens
- [ ] Add token expiration logic
- [ ] Implement token revocation

### Phase 2: Mobile App Update
- [ ] Remove plain PIN storage
- [ ] Implement `SecureBiometricService`
- [ ] Update enable biometric flow to call backend
- [ ] Store encrypted tokens instead of PINs
- [ ] Update transaction flow to use tokens
- [ ] Add token refresh logic

### Phase 3: Security Enhancements
- [ ] Use `flutter_secure_storage` instead of Hive
- [ ] Implement proper AES encryption
- [ ] Add certificate pinning
- [ ] Implement token rotation
- [ ] Add biometric re-authentication timeout
- [ ] Implement fraud detection

## 🔄 Migration Path

### Step 1: Add Backend Support (No Breaking Changes)
```dart
// Backend accepts both PIN and token
if (request.hasToken()) {
  validateToken(request.token);
} else if (request.hasPin()) {
  validatePin(request.pin); // Legacy support
}
```

### Step 2: Update Mobile App
```dart
// App uses token if available, falls back to PIN
if (biometricEnabled) {
  final token = await getAuthToken();
  sendTransactionWithToken(token);
} else {
  final pin = getUserEnteredPin();
  sendTransactionWithPin(pin); // Legacy
}
```

### Step 3: Deprecate PIN-based Auth
```dart
// After migration period, remove PIN support
// Only accept token-based authentication
```

## 📝 Code Examples

### Secure Setup Flow

```dart
// In enable biometric screen
Future<void> enableBiometric() async {
  final pin = pinController.text;
  
  // 1. Validate PIN with backend
  final response = await apiClient.post('/api/auth/validate-pin', {
    'pin': pin,
  });
  
  if (!response.success) {
    showError('Invalid PIN');
    return;
  }
  
  // 2. Store token (NOT PIN)
  final token = response.data['token'];
  await SecureBiometricService.enableBiometricTransaction(
    authToken: token,
  );
  
  showSuccess('Biometric enabled');
}
```

### Secure Transaction Flow

```dart
// In transaction screen
Future<void> processTransaction() async {
  String authToken;
  
  if (biometricEnabled) {
    // Get token via biometric
    authToken = await SecureBiometricService.getAuthTokenWithBiometric(
      reason: 'Authenticate transaction',
    );
  } else {
    // Get token by validating PIN
    final pin = pinController.text;
    final response = await apiClient.post('/api/auth/validate-pin', {
      'pin': pin,
    });
    authToken = response.data['token'];
  }
  
  // Send transaction with token
  final result = await apiClient.post('/api/transactions/send', {
    'recipient': recipient,
    'amount': amount,
  }, headers: {
    'Authorization': 'Bearer $authToken',
  });
  
  if (result.success) {
    showSuccess();
  }
}
```

## 🎯 Key Takeaways

1. **Never store plain PINs or passwords**
2. **Biometric = convenience, not security**
3. **Always validate with backend**
4. **Use tokens, not credentials**
5. **Encrypt everything locally**
6. **Implement token expiration**
7. **Add audit logging**
8. **Plan for token revocation**

## 📚 Additional Resources

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Biometric Authentication Guidelines](https://developer.android.com/training/sign-in/biometric-auth)
