# Socket.IO Endpoints Documentation

This document describes all the Socket.IO events and endpoints available in the oneone-backend application.

## Connection Setup

The Socket.IO server is configured with CORS enabled for all origins and supports GET and POST methods.

## Client Events (Events the client can emit)

### 1. `connect-user`
**Purpose**: Authenticate and connect a user to the socket server

**Data Required**:
```javascript
{
  uid: string,        // Firebase UID of the user
  name: string        // Display name of the user
}
```

**Server Response**:
- **Success**: User is registered and connected
  - Emits `user-connected` to all other clients
  - Emits `connected-users` to the connecting client with list of online users
- **Error**: Emits `connect-error` with error message

**Database Updates**:
- Sets user status to 'online'
- Updates `socketId` with current socket ID
- Updates `lastLogin` timestamp

---

### 2. `register_fcm_token`
**Purpose**: Register Firebase Cloud Messaging token for push notifications

**Data Required**:
```javascript
{
  uniqueCode: string, // User's unique code
  token: string       // FCM token
}
```

**Server Response**: No direct response, token is stored internally

---

### 3. `offer` (WebRTC)
**Purpose**: Send WebRTC offer to initiate a call

**Data Required**:
```javascript
{
  sender: string,     // Sender's unique code
  receiver: string,   // Receiver's unique code
  sdp: string,        // WebRTC SDP offer
  senderName: string  // Sender's display name
}
```

**Server Response**:
- Forwards offer to receiver if they're online
- If receiver is offline, sends FCM push notification with call details
- Establishes active connection tracking

**FCM Notification** (if receiver offline):
```javascript
{
  type: "call",
  sender: string,
  senderName: string,
  sdp: string
}
```

---

### 4. `answer` (WebRTC)
**Purpose**: Send WebRTC answer in response to an offer

**Data Required**:
```javascript
{
  sender: string,     // Answerer's unique code
  receiver: string,   // Caller's unique code
  sdp: string         // WebRTC SDP answer
}
```

**Server Response**: Forwards answer to the original caller (only for active connections)

---

### 5. `ice-candidate` (WebRTC)
**Purpose**: Exchange ICE candidates for WebRTC connection establishment

**Data Required**:
```javascript
{
  sender: string,           // Sender's unique code
  receiver: string,         // Receiver's unique code
  candidate: string,        // ICE candidate
  sdpMid: string,          // SDP media identification
  sdpMLineIndex: number    // SDP media line index
}
```

**Server Response**: Forwards ICE candidate to receiver (only for active connections)

---

### 6. `send-message`
**Purpose**: Send a text message to another user

**Data Required**:
```javascript
{
  sender: string,     // Sender's unique code
  receiver: string,   // Receiver's unique code
  text: string        // Message content
}
```

**Server Response**: Forwards message to receiver if they're online

---

## Server Events (Events the server emits to clients)

### 1. `your-unique-code`
**Triggered**: Immediately upon connection
**Purpose**: Provides the client with their socket ID as a unique identifier

**Data**:
```javascript
string  // Socket ID (e.g., "abc123def456")
```

---

### 2. `connected-users`
**Triggered**: After successful `connect-user` event
**Purpose**: Provides list of currently connected users

**Data**:
```javascript
[
  {
    name: string,        // User's display name
    uniqueCode: string   // User's unique code
  },
  // ... more users
]
```

---

### 3. `user-connected`
**Triggered**: When a new user connects
**Purpose**: Notifies all clients about a new user joining

**Data**:
```javascript
{
  name: string,        // New user's display name
  uniqueCode: string   // New user's unique code
}
```

---

### 4. `user-disconnected`
**Triggered**: When a user disconnects
**Purpose**: Notifies all clients about a user leaving

**Data**:
```javascript
{
  uniqueCode: string   // Disconnected user's unique code
}
```

---

### 5. `offer` (WebRTC)
**Triggered**: When receiving a WebRTC offer
**Purpose**: Delivers WebRTC offer to the intended recipient

**Data**:
```javascript
{
  sdp: string,       // WebRTC SDP offer
  sender: string,    // Caller's unique code
  receiver: string   // Receiver's unique code
}
```

---

### 6. `answer` (WebRTC)
**Triggered**: When receiving a WebRTC answer
**Purpose**: Delivers WebRTC answer to the original caller

**Data**:
```javascript
{
  sdp: string,       // WebRTC SDP answer
  sender: string,    // Answerer's unique code
  receiver: string   // Original caller's unique code
}
```

---

### 7. `ice-candidate` (WebRTC)
**Triggered**: When receiving ICE candidates
**Purpose**: Delivers ICE candidates for WebRTC connection

**Data**:
```javascript
{
  candidate: string,        // ICE candidate
  sdpMid: string,          // SDP media identification
  sdpMLineIndex: number,   // SDP media line index
  sender: string,          // Sender's unique code
  receiver: string         // Receiver's unique code
}
```

---

### 8. `receive-message`
**Triggered**: When receiving a text message
**Purpose**: Delivers text message to the recipient

**Data**:
```javascript
{
  text: string,      // Message content
  sender: string,    // Sender's unique code
  receiver: string   // Receiver's unique code
}
```

---

### 9. `connect-error`
**Triggered**: When connection or authentication fails
**Purpose**: Notifies client of connection errors

**Data**:
```javascript
{
  message: string    // Error description
}
```

---

## Connection Management

### User Status Tracking
- Users are tracked in memory with their socket ID, name, unique code, and UID
- Database is updated with online/offline status and socket ID
- Active WebRTC connections are tracked to prevent unauthorized signaling

### Automatic Cleanup
- On disconnect, user status is set to offline in database
- Socket ID is cleared from database
- Active connections involving the disconnected user are removed
- All other users are notified of the disconnection

### Security Features
- WebRTC signaling is only allowed between users with active connections
- User authentication is required before accessing most features
- FCM tokens are mapped to unique codes for targeted notifications

## Usage Examples

### Basic Connection Flow
```javascript
// 1. Connect to socket
const socket = io('your-server-url');

// 2. Get unique code
socket.on('your-unique-code', (code) => {
  console.log('My unique code:', code);
});

// 3. Authenticate user
socket.emit('connect-user', {
  uid: 'firebase-uid',
  name: 'John Doe'
});

// 4. Handle connected users
socket.on('connected-users', (users) => {
  console.log('Online users:', users);
});
```

### WebRTC Call Flow
```javascript
// 1. Send offer
socket.emit('offer', {
  sender: 'my-unique-code',
  receiver: 'target-unique-code',
  sdp: offerSDP,
  senderName: 'John Doe'
});

// 2. Handle incoming offer
socket.on('offer', (data) => {
  // Process WebRTC offer
  handleOffer(data.sdp);
});

// 3. Send answer
socket.emit('answer', {
  sender: 'my-unique-code',
  receiver: 'caller-unique-code',
  sdp: answerSDP
});
```

### Messaging Flow
```javascript
// Send message
socket.emit('send-message', {
  sender: 'my-unique-code',
  receiver: 'target-unique-code',
  text: 'Hello, how are you?'
});

// Receive message
socket.on('receive-message', (data) => {
  console.log(`${data.sender}: ${data.text}`);
});
```
