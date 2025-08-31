const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const http = require('http');
const socketIo = require('socket.io');
const morgan = require('morgan');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const supplierRoutes = require('./routes/suppliers');
const messageRoutes = require('./routes/messages');

const app = express();
const server = http.createServer(app);

// Enhanced CORS configuration for Flutter integration
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    const allowedOrigins = [
      'http://localhost:3000', // React dev server
      'http://localhost:5000', // Express server itself
      'http://localhost:8080', // Flutter web
      'http://127.0.0.1:8080', // Flutter web alternative
      'http://10.0.2.2:5000',  // Android emulator
      'http://192.168.1.100:5000', // Physical device (update with your IP)
      'https://fresh-connect-ld38ltdnl-siddhanth-shettys-projects.vercel.app',
      'https://freshconnect-2.onrender.com/' // Production
    ];
    
    if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV === 'development') {
      callback(null, true);
    } else {
      console.log('🚫 CORS blocked origin:', origin);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));

// Socket.IO with enhanced CORS for Flutter
const io = socketIo(server, {
  cors: {
    origin: function (origin, callback) {
      // Allow requests with no origin (like mobile apps)
      if (!origin) return callback(null, true);
      
      const allowedOrigins = [
        'http://localhost:3000',
        'http://localhost:5000',
        'http://localhost:8080',
        'http://127.0.0.1:8080',
        'http://10.0.2.2:5000',
        'http://192.168.1.100:5000',
        'https://fresh-connect-ld38ltdnl-siddhanth-shettys-projects.vercel.app',
        "https://freshconnect-2.onrender.com/"
      ];
      
      if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV === 'development') {
        callback(null, true);
      } else {
        console.log('🚫 Socket.IO CORS blocked origin:', origin);
        callback(new Error('Not allowed by CORS'));
      }
    },
    methods: ["GET", "POST"],
    credentials: true
  },
  transports: ['websocket', 'polling'] // Support both WebSocket and polling
});

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('combined'));

// MongoDB Connection
const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/freshconnect';
mongoose.connect(mongoUri, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ MongoDB connected successfully'))
.catch(err => console.error('❌ MongoDB connection error:', err));

// Socket.IO Connection Management with enhanced logging
const activeUsers = new Map();

io.on('connection', (socket) => {
  console.log('🔌 User connected:', socket.id);

  socket.on('join', ({ userId }) => {
    if (userId) {
      activeUsers.set(userId, socket.id);
      socket.join(userId);
      console.log(`👤 User ${userId} joined room`);
      console.log(`📊 Active users: ${activeUsers.size}`);
    } else {
      console.log('⚠️ Join event received without userId');
    }
  });

  socket.on('sendMessage', (message) => {
    console.log('📨 Message received via Socket.IO:', message);
    const receiverSocketId = activeUsers.get(message.receiverId);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('newMessage', message);
      console.log(`📤 Message sent to ${message.receiverId}`);
    } else {
      console.log(`⚠️ Receiver ${message.receiverId} not online`);
    }
  });

  socket.on('disconnect', () => {
    // Remove user from active users
    for (const [userId, socketId] of activeUsers.entries()) {
      if (socketId === socket.id) {
        activeUsers.delete(userId);
        console.log(`👤 User ${userId} disconnected`);
        break;
      }
    }
    console.log('❌ User disconnected:', socket.id);
    console.log(`📊 Active users: ${activeUsers.size}`);
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/suppliers', supplierRoutes);
app.use('/api/messages', messageRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    activeConnections: activeUsers.size
  });
});

// Root endpoint for testing
app.get('/', (req, res) => {
  res.json({ 
    message: 'FreshConnect API Server',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('🔥 Error:', err.stack);
  res.status(500).json({ success: false, message: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📱 Flutter integration ready!`);
});

module.exports = { app, server, io };
