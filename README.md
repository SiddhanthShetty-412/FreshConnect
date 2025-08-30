# FreshConnect - Street Vendor Supply Chain Platform

A comprehensive platform connecting street food vendors with fresh suppliers, addressing quality, safety, and supply chain challenges in India's street food ecosystem.

## 🚀 Features

### For Vendors
- **Location-based Supplier Discovery**: Find suppliers in Vasai, Nalla Sopara, and Virar
- **Category-wise Filtering**: Search for Vegetables, Fruits, Grains, Meat, and Dairy Products
- **Supplier Ratings**: View ratings based on freshness, delivery time, and reliability
- **Real-time Chat**: Direct communication with suppliers
- **Order Management**: Place orders with specific delivery addresses
- **Mobile-friendly Interface**: Designed for easy use by street vendors

### For Suppliers
- **Business Profile**: Showcase your products and services
- **Order Management**: Track and manage incoming orders
- **Real-time Communication**: Chat with vendors
- **Performance Analytics**: View ratings, total orders, and response times
- **Multi-category Support**: Offer products across multiple categories

### Technical Features
- **Phone-based Authentication**: Simple OTP-based login system
- **Real-time Messaging**: Socket.io powered chat system
- **Responsive Design**: Works seamlessly on mobile and desktop
- **Production-ready**: Built with scalability and performance in mind
- **Multi-platform Support**: Web (React) and Mobile (Flutter) applications

## 🛠️ Tech Stack

### Frontend Options
#### Web Application (React)
- **React 18** with TypeScript
- **Tailwind CSS** for styling
- **Framer Motion** for animations
- **React Router** for navigation
- **Socket.io Client** for real-time features
- **Axios** for API calls
- **React Hot Toast** for notifications

#### Mobile Application (Flutter)
- **Flutter** with Dart
- **Provider** for state management
- **Socket.io Client** for real-time messaging
- **HTTP** package for API calls
- **Shared Preferences** for local storage
- **Cross-platform** support (Android, iOS, Web)

### Backend
- **Node.js** with Express.js
- **MongoDB** with Mongoose ODM
- **Socket.io** for real-time communication
- **JWT** for authentication
- **Twilio** for SMS OTP (production)
- **bcryptjs** for password hashing

## 📱 Setup Instructions

### Prerequisites
- Node.js (v16 or higher)
- MongoDB (local or cloud)
- Flutter SDK (for mobile app)
- Twilio account (for production SMS)

### 1. Clone and Install Dependencies

```bash
# Clone the repository
git clone <your-repo-url>
cd freshconnect

# Install backend dependencies
cd server
npm install
cd ..

# For Web Frontend (React)
npm install

# For Mobile Frontend (Flutter)
cd frontend
flutter pub get
cd ..
```

### 2. Environment Configuration

#### Backend Environment
Create `server/.env` file:
```env
MONGODB_URI=mongodb://localhost:27017/freshconnect
JWT_SECRET=your_super_secret_jwt_key_here
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone_number
NODE_ENV=development
PORT=5000
```

#### Web Frontend Environment
Create `.env` in the root directory:
```env
VITE_API_URL=http://localhost:5000/api
```

### 3. Database Setup

Make sure MongoDB is running locally or update `MONGODB_URI` with your MongoDB Atlas connection string.

### 4. Running the Application

#### Option 1: Web Application (React)

**Start Backend Server:**
```bash
cd server
npm run dev
```
The backend will run on `http://localhost:5000`

**Start Frontend (in a new terminal):**
```bash
npm run dev
```
The frontend will run on `http://localhost:5173`

#### Option 2: Mobile Application (Flutter)

**Start Backend Server:**
```bash
cd server
npm run dev
```

**Start Flutter App:**
```bash
cd frontend
flutter run
```

#### Option 3: Quick Start (Integration Scripts)

**Windows:**
```bash
start-integration.bat
```

**Unix/Linux/macOS:**
```bash
./start-integration.sh
```

### 5. Testing the Integration

**Test Backend:**
```bash
node test-integration.js
```

**Development OTP:**
- In development mode, the OTP is fixed as `123456` for easy testing
- The OTP is also logged to the console when sent

**Test Users:**
1. Create a vendor account with location (Vasai/Nalla Sopara/Virar)
2. Create a supplier account with categories
3. Test the chat and order functionality

## 🔌 Integration Features

### Real-time Communication
- **Socket.IO**: Both web and mobile apps support real-time messaging
- **Cross-platform**: Messages sync between web and mobile applications
- **Offline Support**: Messages are stored and synced when connection is restored

### Authentication
- **JWT Tokens**: Secure authentication across all platforms
- **Phone Verification**: OTP-based verification for both web and mobile
- **Session Management**: Automatic token refresh and logout

### API Compatibility
- **RESTful APIs**: Standard HTTP endpoints for all operations
- **Real-time Events**: Socket.IO events for live updates
- **Error Handling**: Consistent error responses across platforms

## 🚀 Deployment

### Backend Deployment (Railway/Render/Vercel)
1. Push your code to GitHub
2. Connect your repository to your preferred platform
3. Set all environment variables
4. Deploy

### Web Frontend Deployment (Netlify/Vercel)
1. Build the frontend: `npm run build`
2. Deploy the `dist` folder to your platform
3. Update environment variable `VITE_API_URL` to your backend URL

### Mobile App Deployment
1. **Android**: Build APK or AAB and upload to Google Play Store
2. **iOS**: Build and upload to App Store Connect
3. **Web**: Build for web and deploy to any static hosting

### Database (MongoDB Atlas)
1. Create a MongoDB Atlas cluster
2. Update `MONGODB_URI` in your backend environment variables
3. Whitelist your deployment IP addresses

## 📋 API Endpoints

### Authentication
- `POST /api/auth/send-otp` - Send OTP to phone number
- `POST /api/auth/verify-otp` - Verify OTP and login
- `POST /api/auth/signup` - Create new user account

### Suppliers
- `GET /api/suppliers` - Get suppliers by location and category
- `GET /api/suppliers/:id` - Get supplier details
- `PUT /api/suppliers/profile` - Update supplier profile

### Messages
- `GET /api/messages/:userId1/:userId2` - Get conversation
- `POST /api/messages` - Send message
- `GET /api/messages/conversations` - Get user's conversations

### Health
- `GET /api/health` - Server health check
- `GET /` - Server information

## 🎨 Design Philosophy

The platform is designed with street vendors in mind:
- **Simple Navigation**: Large buttons and clear typography
- **Phone-first**: OTP-based authentication
- **Visual Feedback**: Clear indicators for freshness and reliability
- **Minimal Steps**: Streamlined ordering process
- **Local Focus**: Location-based supplier discovery
- **Cross-platform**: Consistent experience across web and mobile

## 🔒 Security Features

- JWT-based authentication
- Phone number verification via OTP
- Input validation and sanitization
- Rate limiting (can be added)
- CORS configuration
- Environment variable protection
- Secure token storage (SharedPreferences in Flutter)

## 📚 Documentation

- [Integration Guide](INTEGRATION_GUIDE.md) - Detailed Flutter-Node.js integration guide
- [API Documentation](API_DOCS.md) - Complete API reference
- [Deployment Guide](DEPLOYMENT.md) - Step-by-step deployment instructions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on both web and mobile
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

For support or questions, please create an issue in the repository or contact the development team.

---

**Built with ❤️ for India's street food vendors**