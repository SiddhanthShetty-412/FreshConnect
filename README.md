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

## 🛠️ Tech Stack

### Frontend
- **React 18** with TypeScript
- **Tailwind CSS** for styling
- **Framer Motion** for animations
- **React Router** for navigation
- **Socket.io Client** for real-time features
- **Axios** for API calls
- **React Hot Toast** for notifications

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
- Twilio account (for production SMS)

### 1. Clone and Install Dependencies

```bash
# Clone the repository
git clone <your-repo-url>
cd freshconnect

# Install frontend dependencies
npm install

# Install backend dependencies
cd server
npm install
cd ..
```

### 2. Environment Configuration

Create `.env` in the root directory:
```env
VITE_API_URL=http://localhost:5000/api
```

Create `server/.env` file:
```env
MONGODB_URI=mongodb://localhost:27017/freshconnect
JWT_SECRET=your_super_secret_jwt_key_here
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone_number
FRONTEND_URL=http://localhost:5173
NODE_ENV=development
PORT=5000
```

### 3. Database Setup

Make sure MongoDB is running locally or update `MONGODB_URI` with your MongoDB Atlas connection string.

### 4. Running the Application

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

### 5. Testing the Application

**Development OTP:**
- In development mode, the OTP is fixed as `123456` for easy testing
- The OTP is also logged to the console when sent

**Test Users:**
1. Create a vendor account with location (Vasai/Nalla Sopara/Virar)
2. Create a supplier account with categories
3. Test the chat and order functionality

## 🚀 Deployment

### Frontend Deployment (Netlify)
1. Build the frontend: `npm run build`
2. Deploy the `dist` folder to Netlify
3. Update environment variable `VITE_API_URL` to your backend URL

### Backend Deployment (Railway/Render)
1. Push your code to GitHub
2. Connect your repository to Railway or Render
3. Set all environment variables
4. Deploy

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

## 🎨 Design Philosophy

The platform is designed with street vendors in mind:
- **Simple Navigation**: Large buttons and clear typography
- **Phone-first**: OTP-based authentication
- **Visual Feedback**: Clear indicators for freshness and reliability
- **Minimal Steps**: Streamlined ordering process
- **Local Focus**: Location-based supplier discovery

## 🔒 Security Features

- JWT-based authentication
- Phone number verification via OTP
- Input validation and sanitization
- Rate limiting (can be added)
- CORS configuration
- Environment variable protection

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

For support or questions, please create an issue in the repository or contact the development team.

---

**Built with ❤️ for India's street food vendors**