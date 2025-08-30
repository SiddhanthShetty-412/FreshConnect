# FreshConnect Flutter-Node.js Integration Guide

This guide explains how to integrate the Flutter frontend with the Node.js backend for the FreshConnect application.

## 🏗️ Architecture Overview

```
┌─────────────────┐    HTTP/REST API    ┌─────────────────┐
│   Flutter App   │ ◄─────────────────► │  Node.js Server │
│   (Frontend)    │                     │   (Backend)     │
└─────────────────┘                     └─────────────────┘
         │                                        │
         │ Socket.IO (Real-time)                  │
         └────────────────────────────────────────┘
```

## 📱 Flutter Frontend Configuration

### API Configuration (`lib/services/api_config.dart`)

The Flutter app automatically detects the platform and uses the appropriate base URL:

- **Android Emulator**: `http://10.0.2.2:5000`
- **iOS Simulator**: `http://localhost:5000`
- **Web**: `http://localhost:5000`
- **Physical Devices**: `http://192.168.1.100:5000` (update with your local IP)

### Environment Variables

To switch between development and production:

```bash
# Development (default)
flutter run

# Production
flutter run --dart-define=PRODUCTION=true
```

## 🖥️ Node.js Backend Configuration

### Server Setup

1. **Install dependencies**:
   ```bash
   cd server
   npm install
   ```

2. **Environment variables** (create `.env` file):
   ```env
   NODE_ENV=development
   PORT=5000
   MONGODB_URI=mongodb://localhost:27017/freshconnect
   JWT_SECRET=your_jwt_secret_here
   TWILIO_ACCOUNT_SID=your_twilio_sid
   TWILIO_AUTH_TOKEN=your_twilio_token
   ```

3. **Start the server**:
   ```bash
   npm run dev  # Development with nodemon
   npm start    # Production
   ```

### CORS Configuration

The server is configured to accept requests from:
- Flutter web apps (`localhost:8080`)
- Android emulators (`10.0.2.2:5000`)
- iOS simulators (`localhost:5000`)
- Physical devices (configurable IP)

## 🔌 Socket.IO Integration

### Real-time Messaging

The app uses Socket.IO for real-time messaging:

1. **Connection**: Flutter connects to Socket.IO when user logs in
2. **Join Room**: User joins their personal room using their user ID
3. **Message Sending**: Messages are sent via both REST API (persistence) and Socket.IO (real-time)
4. **Message Receiving**: Real-time messages are received via Socket.IO events

### Socket.IO Events

- `join`: User joins their personal room
- `sendMessage`: Send a message to another user
- `newMessage`: Receive a new message from another user

## 🚀 Getting Started

### 1. Start the Backend

```bash
cd server
npm install
npm run dev
```

Verify the server is running:
```bash
curl http://localhost:5000/api/health
```

### 2. Start the Flutter App

```bash
cd frontend
flutter pub get
flutter run
```

### 3. Test the Integration

1. **Health Check**: The app should connect to the backend automatically
2. **Authentication**: Try logging in/registering
3. **Real-time Messaging**: Send messages between users
4. **Socket.IO**: Check console logs for connection status

## 🔧 Troubleshooting

### Common Issues

1. **CORS Errors**:
   - Ensure the server is running on the correct port
   - Check that your device's IP is in the allowed origins
   - For physical devices, update the IP in `api_config.dart`

2. **Socket.IO Connection Issues**:
   - Check network connectivity
   - Verify the server URL is correct
   - Check console logs for connection errors

3. **Authentication Issues**:
   - Ensure JWT tokens are being sent correctly
   - Check that the user is properly logged in

### Debug Mode

Enable debug logging in Flutter:

```dart
// In your main.dart
import 'package:flutter/foundation.dart';

void main() {
  if (kDebugMode) {
    print('🔍 Debug mode enabled');
  }
  runApp(MyApp());
}
```

### Network Configuration

For physical devices, find your local IP:

```bash
# Windows
ipconfig

# macOS/Linux
ifconfig
```

Update `api_config.dart` with your actual IP address.

## 📊 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/send-otp` - Send OTP
- `POST /api/auth/verify-otp` - Verify OTP
- `POST /api/auth/signup` - Complete signup

### Suppliers
- `GET /api/suppliers` - Get suppliers list
- `GET /api/suppliers/:id` - Get supplier details
- `PUT /api/suppliers/profile` - Update supplier profile

### Messages
- `GET /api/messages/conversations` - Get user conversations
- `GET /api/messages/:u1/:u2` - Get conversation messages
- `POST /api/messages` - Send a message

### Health
- `GET /api/health` - Server health check
- `GET /` - Server info

## 🔒 Security Considerations

1. **JWT Tokens**: Stored securely in SharedPreferences
2. **CORS**: Configured to allow only trusted origins
3. **Input Validation**: Server validates all inputs
4. **Rate Limiting**: Consider implementing rate limiting for production

## 🚀 Deployment

### Development
- Backend: `localhost:5000`
- Flutter: Uses local configuration

### Production
- Backend: Deploy to Vercel/Heroku/AWS
- Flutter: Build with production configuration
- Update environment variables accordingly

## 📝 Testing

### Manual Testing
1. Test authentication flow
2. Test real-time messaging
3. Test supplier listing and details
4. Test cross-platform compatibility

### Automated Testing
```bash
# Backend tests
cd server
npm test

# Flutter tests
cd frontend
flutter test
```

## 🤝 Contributing

When making changes:
1. Update both frontend and backend accordingly
2. Test the integration thoroughly
3. Update this guide if needed
4. Follow the existing code patterns

## 📞 Support

For integration issues:
1. Check the console logs
2. Verify network connectivity
3. Test with the health endpoint
4. Review the CORS configuration
