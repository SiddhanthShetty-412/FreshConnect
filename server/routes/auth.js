const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Check if phone exists
router.post('/check-phone', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone || phone.length !== 10 || !/^\d{10}$/.test(phone)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid 10-digit phone number'
      });
    }

    const user = await User.findOne({ phone }).select('role');
    if (user) {
      return res.json({ success: true, exists: true, role: user.role });
    }
    return res.json({ success: true, exists: false });
  } catch (error) {
    console.error('Check phone error:', error);
    res.status(500).json({ success: false, message: 'Failed to check phone' });
  }
});

// In-memory OTP store for phones awaiting verification
// Structure: { [phone: string]: { otpHash: string, expiresAt: Date } }
const otpStore = new Map();

// Initialize Twilio client conditionally
let twilioClient = null;
if (process.env.NODE_ENV === 'production' && 
    process.env.TWILIO_ACCOUNT_SID && 
    process.env.TWILIO_ACCOUNT_SID !== 'skip_for_development') {
  const twilio = require('twilio');
  twilioClient = twilio(
    process.env.TWILIO_ACCOUNT_SID,
    process.env.TWILIO_AUTH_TOKEN
  );
}

// Generate random 6-digit OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Send OTP
router.post('/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;

    // Validate phone number
    if (!phone || phone.length !== 10 || !/^\d{10}$/.test(phone)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid 10-digit phone number'
      });
    }

    const otp = generateOTP();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // For development, use fixed OTP
    const actualOTP = process.env.NODE_ENV === 'development' ? '123456' : otp;

    // Hash the OTP before storing (in-memory)
    const hashedOTP = await bcrypt.hash(actualOTP, 10);
    otpStore.set(phone, { otpHash: hashedOTP, expiresAt: otpExpiry });

    // Send SMS in production
    if (twilioClient && process.env.NODE_ENV === 'production') {
      try {
        await twilioClient.messages.create({
          body: `Your FreshConnect OTP is: ${otp}. Valid for 10 minutes.`,
          from: process.env.TWILIO_PHONE_NUMBER,
          to: `+91${phone}`
        });
        console.log(`SMS sent to +91${phone}`);
      } catch (twilioError) {
        console.error('Twilio error:', twilioError);
        // Continue anyway - don't fail the request
      }
    }

    // Log OTP for development
    if (process.env.NODE_ENV === 'development') {
      console.log(`OTP for ${phone}: ${actualOTP}`);
    }

    res.json({
      success: true,
      message: 'OTP sent successfully',
      ...(process.env.NODE_ENV === 'development' && { otp: actualOTP })
    });

  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send OTP'
    });
  }
});

// Verify OTP
router.post('/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and OTP are required'
      });
    }

    const stored = otpStore.get(phone);
    if (!stored) {
      return res.status(404).json({ success: false, message: 'Please request OTP first' });
    }
    if (stored.expiresAt < new Date()) {
      otpStore.delete(phone);
      return res.status(400).json({ success: false, message: 'OTP has expired. Please request a new one.' });
    }

    // Verify OTP
    const isOTPValid = await bcrypt.compare(otp, stored.otpHash);
    if (!isOTPValid) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // OTP is valid
    const user = await User.findOne({ phone });
    otpStore.delete(phone);

    if (user) {
      // Existing user -> issue normal JWT and return user
      const token = jwt.sign(
        { userId: user._id, phone: user.phone, role: user.role },
        process.env.JWT_SECRET || 'fallback_secret',
        { expiresIn: '7d' }
      );

      return res.json({
        success: true,
        token,
        user: {
          _id: user._id,
          name: user.name,
          phone: user.phone,
          role: user.role,
          location: user.location,
          categories: user.categories,
          description: user.description,
          isVerified: true
        }
      });
    }

    // New user -> return a temporary JWT for completing profile
    const tempToken = jwt.sign(
      { phone, purpose: 'complete_profile' },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '30m' }
    );

    return res.json({ success: true, newUser: true, token: tempToken, phone });

  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify OTP'
    });
  }
});

// Complete Signup (for new users)
// Complete profile for new users (after OTP), requires token from verify-otp
router.post('/complete-profile', authenticateToken, async (req, res) => {
  try {
    const { name, role, location } = req.body;

    if (!name || !role || !location) {
      return res.status(400).json({ success: false, message: 'Name, role and location are required' });
    }

    if (!['vendor', 'supplier'].includes(role)) {
      return res.status(400).json({ success: false, message: 'Role must be either vendor or supplier' });
    }

    // If the token was a normal user token, we have userId. If it was a temp token, we may only have phone
    let user = null;
    if (req.user?.userId) {
      user = await User.findById(req.user.userId);
    }

    if (!user) {
      // Fallback: locate by phone from token payload stored by authenticateToken alternative path
      const token = req.header('Authorization')?.replace('Bearer ', '');
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
        if (decoded && decoded.phone) {
          user = await User.findOne({ phone: decoded.phone });
        }
      } catch (_) {}
    }

    if (!user) {
      // Create the user now with minimal required fields
      // Extract phone from token
      const token = req.header('Authorization')?.replace('Bearer ', '');
      let phoneFromToken = null;
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
        phoneFromToken = decoded.phone;
      } catch (_) {}

      if (!phoneFromToken) {
        return res.status(400).json({ success: false, message: 'Invalid session for completing profile' });
      }

      user = new User({ name: name.trim(), phone: phoneFromToken, role, location: location.trim(), isVerified: true });
      await user.save();
    } else {
      // Update existing placeholder user
      user.name = name.trim();
      user.role = role;
      user.location = location.trim();
      user.isVerified = true;
      await user.save();
    }

    const token = jwt.sign(
      { userId: user._id, phone: user.phone, role: user.role },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '7d' }
    );

    return res.status(200).json({
      success: true,
      message: 'Profile completed successfully',
      token,
      user: {
        _id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        location: user.location,
        categories: user.categories,
        description: user.description,
        isVerified: true
      }
    });
  } catch (error) {
    console.error('Complete profile error:', error);
    return res.status(500).json({ success: false, message: 'Failed to complete profile' });
  }
});

router.post('/signup', async (req, res) => {
  try {
    const { name, phone, role, location, categories, description } = req.body;

    // Validate required fields
    if (!name || !phone || !role || !location) {
      return res.status(400).json({
        success: false,
        message: 'Name, phone, role, and location are required'
      });
    }

    // Validate role
    if (!['vendor', 'supplier'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Role must be either vendor or supplier'
      });
    }

    // Find user by phone
    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found. Please verify your phone number first.'
      });
    }

    // Check if user already has complete profile
    if (user.name && user.role && user.location) {
      return res.status(400).json({
        success: false,
        message: 'User profile already exists. Please login instead.'
      });
    }

    // Prepare update data
    const updateData = {
      name: name.trim(),
      role,
      location: location.trim(),
      isVerified: true,
      $unset: { otp: 1, otpExpiry: 1 }
    };

    // Add supplier-specific fields
    if (role === 'supplier') {
      updateData.categories = Array.isArray(categories) ? categories : [];
      updateData.description = description?.trim() || '';
      updateData.rating = 4.5; // Default rating
      updateData.totalOrders = 0;
      updateData.responseTime = '2-3 hours';
    }

    // Add vendor-specific fields
    if (role === 'vendor') {
      updateData.businessName = name; // You can add a separate businessName field if needed
    }

    // Update user with complete profile
    const updatedUser = await User.findByIdAndUpdate(
      user._id,
      updateData,
      { new: true, runValidators: true }
    );

    // Generate JWT token
    const token = jwt.sign(
      { userId: updatedUser._id, phone: updatedUser.phone, role: updatedUser.role },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'Profile completed successfully',
      token,
      user: {
        _id: updatedUser._id,
        name: updatedUser.name,
        phone: updatedUser.phone,
        role: updatedUser.role,
        location: updatedUser.location,
        categories: updatedUser.categories,
        description: updatedUser.description,
        isVerified: true
      },
      redirectTo: updatedUser.role === 'vendor' ? '/vendor-dashboard' : '/supplier-dashboard'
    });

  } catch (error) {
    console.error('Signup error:', error);
    
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Phone number already registered with complete profile'
      });
    }
    
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: validationErrors
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to complete profile'
    });
  }
});

// Get current user (for protected routes)
router.get('/me', async (req, res) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'No token provided'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
    const user = await User.findById(decoded.userId).select('-otp -otpExpiry');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      user: {
        _id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        location: user.location,
        categories: user.categories,
        description: user.description,
        isVerified: user.isVerified
      }
    });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid token'
    });
  }
});
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-otp -otpExpiry');
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      user: {
        _id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        location: user.location,
        categories: user.categories,
        description: user.description,
        isVerified: user.isVerified
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch profile'
    });
  }
});

// Logout (client-side will remove token, but we can track it server-side if needed)
router.post('/logout', (req, res) => {
  res.json({
    success: true,
    message: 'Logged out successfully'
  });
});

module.exports = router;