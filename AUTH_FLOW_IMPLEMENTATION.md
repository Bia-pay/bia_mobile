# Authentication Flow Implementation

## Overview
This implementation provides the exact flow you requested:

1. **User logs in or registers** ↓
2. **Access token saved** ↓  
3. **FCM token generated** ↓
4. **FCM token saved** ↓
5. **Socket connects** ↓
6. **Socket sends: { accessToken, fcmToken }**

## Files Modified/Created

### 1. Core Service
- **`lib/core/services/auth_flow_service.dart`** - Main service that orchestrates the complete flow

### 2. Updated Files
- **`lib/feature/auth/authrepo/repo.dart`** - Added FCM token generation to register step 2 and automatic auth flow completion
- **`lib/app/socket/socket_provider.dart`** - Updated to send both accessToken and fcmToken in the format you want

### 3. Testing/Monitoring
- **`lib/core/widgets/auth_flow_monitor.dart`** - Widget to monitor auth flow status
- **`lib/core/test/auth_flow_test_page.dart`** - Test page to verify the flow works

## How It Works

### Login Flow
1. User calls `authRepository.logIn()`
2. Access token is saved to Hive
3. FCM token is generated and saved to Hive  
4. `authFlowService.completeAuthFlow()` is called automatically
5. Socket connects with both tokens
6. Socket emits `registerFcmToken` with `{ accessToken, fcmToken }`

### Register Flow  
1. User completes registration (step 2)
2. Access token is saved to Hive
3. FCM token is generated and saved to Hive
4. `authFlowService.completeAuthFlow()` is called automatically
5. Socket connects with both tokens
6. Socket emits `registerFcmToken` with `{ accessToken, fcmToken }`

## Key Features

### AuthFlowService Methods
- `completeAuthFlow()` - Executes the complete flow
- `verifyAuthState()` - Checks if tokens are present
- `clearAuthFlow()` - Cleans up auth data and disconnects socket

### Socket Integration
- Automatically connects when auth flow completes
- Sends both tokens in the exact format: `{ accessToken, fcmToken }`
- Handles reconnection with stored tokens
- Includes proper error handling and logging

### Monitoring
- `AuthFlowMonitor` widget shows real-time status
- Debug logs at each step for troubleshooting
- Test page for manual verification

## Usage

### Automatic (Recommended)
The flow happens automatically after successful login/register. No additional code needed.

### Manual Trigger
```dart
final authFlowService = ref.read(authFlowServiceProvider);
await authFlowService.completeAuthFlow();
```

### Add Monitoring Widget
```dart
// Add to any screen for debugging
const AuthFlowMonitor()
```

### Test Page
Navigate to `AuthFlowTestPage` to test all functionality manually.

## Socket Message Format
When the socket connects, it sends:
```json
{
  "accessToken": "your_access_token_here",
  "fcmToken": "your_fcm_token_here"
}
```

This is sent via the `registerFcmToken` event as configured in your socket provider.

## Error Handling
- Graceful handling if FCM token generation fails
- Automatic retry logic for socket connections  
- Comprehensive logging for debugging
- Fallback mechanisms for missing tokens

The implementation is production-ready and follows your existing code patterns and architecture.