# WebSocket Setup Guide

## Current Status
❌ **WebSocket is NOT working** - Connection times out

## Issue
The mobile app is trying to connect to:
```
wss://api.bia.com.ng/ws?token=USER_JWT_TOKEN
```

But the connection times out, which means:
- Either the WebSocket server is not running
- Or the endpoint is different from `/ws`
- Or WebSocket is not enabled on the backend

## What Works
✅ HTTP API is working fine:
- `https://api.bia.com.ng/api/v1/auth/login` - Success
- `https://api.bia.com.ng/api/v1/wallet/transactions` - Success

## Backend Requirements

### 1. WebSocket Endpoint
The backend needs to expose a WebSocket endpoint. Common patterns:
- `wss://api.bia.com.ng/ws` (currently trying this)
- `wss://api.bia.com.ng/socket`
- `wss://api.bia.com.ng/websocket`
- `wss://api.bia.com.ng/api/v1/ws`

### 2. Authentication
The mobile app sends the JWT token as a query parameter:
```
wss://api.bia.com.ng/ws?token=JWT_TOKEN_HERE
```

Alternative authentication methods:
- Send token in WebSocket headers
- Send token in first message after connection

### 3. Message Format
The app expects JSON messages with this structure:

#### Deposit Success
```json
{
  "event": "deposit_success",
  "amount": "5000",
  "data": {
    "transactionId": "TXN123",
    "timestamp": "2025-12-09T10:30:00Z"
  }
}
```

#### Transfer Received
```json
{
  "event": "transfer_received",
  "amount": "2500",
  "sender": "John Doe",
  "data": {
    "senderAccount": "1234567890",
    "reference": "REF456"
  }
}
```

#### Balance Update
```json
{
  "event": "balance_update",
  "balance": "224270"
}
```

#### Ping/Pong (for connection health check)
```json
// Client sends:
{"type": "ping"}

// Server should respond:
{"type": "pong"}
```

## Mobile App Configuration

### Enable WebSocket
In `lib/core/constants.dart`:
```dart
static const bool enableWebSocket = true; // Change to true when ready
```

### Change WebSocket Endpoint
If the endpoint is different, update in `lib/core/constants.dart`:
```dart
static const String wsUrl = 'wss://api.bia.com.ng/your-endpoint';
```

## Testing WebSocket

### 1. Test with wscat (Command Line)
```bash
# Install wscat
npm install -g wscat

# Test connection
wscat -c "wss://api.bia.com.ng/ws?token=YOUR_JWT_TOKEN"

# If connected, try sending:
{"type":"ping"}
```

### 2. Test with Browser Console
```javascript
const ws = new WebSocket('wss://api.bia.com.ng/ws?token=YOUR_JWT_TOKEN');

ws.onopen = () => console.log('✅ Connected');
ws.onerror = (error) => console.log('❌ Error:', error);
ws.onmessage = (msg) => console.log('📥 Message:', msg.data);
ws.onclose = () => console.log('🔌 Closed');

// Send test message
ws.send(JSON.stringify({type: 'ping'}));
```

### 3. Test in Mobile App
Navigate to the WebSocket test page in the app:
- Add a button somewhere: `context.push('/socket-test')`
- Or use the `SocketDebugWidget` in any page

## Backend Implementation Example (Node.js)

```javascript
const WebSocket = require('ws');
const jwt = require('jsonwebtoken');

const wss = new WebSocket.Server({ 
  port: 8080,
  path: '/ws'
});

wss.on('connection', (ws, req) => {
  // Extract token from query params
  const url = new URL(req.url, 'http://localhost');
  const token = url.searchParams.get('token');
  
  // Verify token
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.id;
    
    console.log(`✅ User ${userId} connected`);
    
    // Store connection with userId for later use
    ws.userId = userId;
    
    // Handle messages
    ws.on('message', (message) => {
      const data = JSON.parse(message);
      
      if (data.type === 'ping') {
        ws.send(JSON.stringify({ type: 'pong' }));
      }
    });
    
    // Handle disconnect
    ws.on('close', () => {
      console.log(`🔌 User ${userId} disconnected`);
    });
    
  } catch (error) {
    console.error('❌ Invalid token');
    ws.close();
  }
});

// Function to send notification to specific user
function sendToUser(userId, event, data) {
  wss.clients.forEach((client) => {
    if (client.userId === userId && client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify({ event, ...data }));
    }
  });
}

// Example: Send deposit notification
sendToUser(45, 'deposit_success', {
  amount: '5000',
  transactionId: 'TXN123'
});
```

## Troubleshooting

### Connection Timeout
- Check if WebSocket server is running
- Verify the endpoint path is correct
- Check firewall/security group settings
- Ensure SSL certificate is valid for WSS

### Connection Refused
- WebSocket server is not running on that port
- Wrong endpoint path

### 401 Unauthorized
- Token is invalid or expired
- Token verification is failing on backend

### Connection Closes Immediately
- Backend is rejecting the connection
- Check backend logs for error messages

## Next Steps

1. **Backend Team**: Implement WebSocket server at the agreed endpoint
2. **Backend Team**: Test with wscat or browser console
3. **Mobile Team**: Update `enableWebSocket = true` in constants
4. **Both Teams**: Test end-to-end with real transactions

## Questions for Backend Team

- [ ] Is WebSocket implemented on the backend?
- [ ] What is the WebSocket endpoint URL?
- [ ] How should authentication be handled? (query param, header, or message)
- [ ] What events will the backend send?
- [ ] Is there a staging/test environment to test WebSocket?
