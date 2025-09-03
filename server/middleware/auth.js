const jwt = require('jsonwebtoken');
const User = require('../models/User');

const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  console.log('Authorization header:', authHeader);
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    console.log('No token provided');
    return res.status(401).json({
      success: false,
      message: 'No token provided'
    });
  }

  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
    console.log('Decoded token:', decoded);
  } catch (error) {
    console.error('JWT verification error:', error);
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired' });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, message: 'Invalid token' });
    }
    if (error.name === 'NotBeforeError') {
      return res.status(401).json({ success: false, message: 'Token not active yet' });
    }
    return res.status(500).json({ success: false, message: 'Authentication failed' });
  }

  try {
    // Support two token types:
    // 1) Normal user token: includes userId
    // 2) Temp token for completing profile: includes { phone, purpose: 'complete_profile' }
    if (decoded && decoded.userId) {
      const user = await User.findById(decoded.userId);
      if (!user || !user.isVerified) {
        return res.status(401).json({ success: false, message: 'User not found or not verified' });
      }
      req.user = { userId: user._id.toString(), phone: user.phone, role: user.role };
      return next();
    }

    if (decoded && decoded.purpose === 'complete_profile' && decoded.phone) {
      // Allow access for completing profile; downstream can use req.user.phone
      req.user = { userId: null, phone: decoded.phone, role: null };
      return next();
    }

    return res.status(401).json({ success: false, message: 'Invalid token payload' });
  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(500).json({ success: false, message: 'Authentication failed' });
  }
};

module.exports = { authenticateToken };