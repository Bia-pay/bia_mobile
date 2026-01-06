# Socket.IO Troubleshooting Guide

## Current Issue: "transport close"

The "transport close" error indicates the Socket.IO connection is being dropped. This is common and the system should automatically reconnect.

## ✅ What I Fixed

1. **Added transport fallback** - Now uses both WebSocket and polling
2. **Improved reconnection logic** - Better handling of different disconnect reasons
3. **Fixed compilation errors** - Updated debug widget to use Socket.IO methods
4. **Added connection tests** - New utility to test server connectivity

## 🔧 How to Debug

### 1. Use the Debug Widget
Add this to any screen to test the connection:

```dart
import 'package:bia/app/socket/socket_debug_widget.dart';

// In your widget:
SocketDebugWidget()
```

### 2. Run Connection Tests
The debug widget has a "Test Connection" button that will:
- ✅ Check if server is reachable
- ✅ Test Socket.IO endpoint
- ✅ Verify authentication token

### 3. Monitor Console Logs
Look for these patterns:

**Good Connection:**
```
🔌 User is logged in, connecting Socket.IO...
🔌 Attempting Socket.IO connection...
🔌 Connecting to: https://api.bia.com.ng
✅ Socket.IO connected successfully
🔐 Socket.IO authenticated: [auth response]
```

**Connection Issues:**
```
🔌 Socket.IO disconnected: transport close
🔄 Scheduling reconnection attempt 1/5 in 5s...
```

## 🚨 Common Issues & Solutions

### 1. "transport close" (Your Current Issue)
**Cause:** Network instability or server dropping connections
**Solution:** 
- ✅ Already implemented auto-reconnection
- ✅ Added transport fallback (WebSocket → Polling)
- The app should reconnect automatically

### 2. "Connection timeout"
**Cause:** Server not responding
**Solutions:**
- Check if backend Socket.IO server is running
- Verify server URL in `AppConstants.baseUrl`
- Test with connection test utility

### 3. "Authentication error"
**Cause:** Invalid or expired token
**Solutions:**
- Check token in Hive storage
- Verify token format (should be JWT)
- Test auth endpoint with connection utility

### 4. "Socket.IO endpoint not found"
**Cause:** Backend doesn't have Socket.IO server
**Solutions:**
- Ensure backend has Socket.IO installed
- Check if Socket.IO server is running on correct port
- Verify endpoint configuration

## 🔍 Backend Requirements

Your backend needs:

### 1. Socket.IO Server Setup
```javascript
const io = require('socket.io')(server, {
  cors: {
    origin: "*", // Configure for production
    methods: ["GET", "POST"]
  },
  transports: ['websocket', 'polling'] // Allow both transports
});
```

### 2. Authentication Handler
```javascript
io.use((socket, next) => {
  const token = socket.handshake.auth.token || 
                socket.handshake.headers.authorization?.replace('Bearer ', '');
  
  if (isValidToken(token)) {
    socket.userId = getUserIdFromToken(token);
    next();
  } else {
    next(new Error('Authentication error'));
  }
});
```

### 3. Connection Handler
```javascript
io.on('connection', (socket) => {
  console.log('User connected:', socket.userId);
  
  // Handle authentication confirmation
  socket.on('authenticate', (data) => {
    socket.emit('authenticated', { success: true, userId: socket.userId });
  });
  
  // Handle ping/pong
  socket.on('ping', (data) => {
    socket.emit('pong', { ...data, serverTime: Date.now() });
  });
  
  // Send real-time updates
  socket.emit('balance_update', { balance: getUserBalance(socket.userId) });
});
```

## 📱 Testing Steps

1. **Open the app** - Should auto-connect if logged in
2. **Check console** - Look for connection success messages
3. **Use debug widget** - Test connection manually
4. **Run connection tests** - Verify server connectivity
5. **Test reconnection** - Turn off/on WiFi to test auto-reconnect

## 🎯 Expected Behavior

- ✅ Auto-connect when user is logged in
- ✅ Auto-reconnect on network issues (5 attempts)
- ✅ Fallback from WebSocket to polling if needed
- ✅ Show connection status in debug widget
- ✅ Handle different disconnect reasons appropriately

## 📞 Next Steps

1. **Test the current setup** - The "transport close" should now auto-reconnect
2. **Verify backend** - Ensure Socket.IO server is properly configured
3. **Monitor logs** - Check if reconnection is working
4. **Use debug tools** - Test connection and auth with the new utilities

The Socket.IO implementation is now much more robust than the previous WebSocket setup and should handle connection issues gracefully.