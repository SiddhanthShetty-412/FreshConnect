const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

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

    // Hash the OTP before storing
    const hashedOTP = await bcrypt.hash(actualOTP, 10);

    // Find existing user or create new one
    let user = await User.findOne({ phone });
    
    if (user) {
      // Update existing user with new OTP
      user.otp = hashedOTP;
      user.otpExpiry = otpExpiry;
      await user.save();
    } else {
      // Create new user with OTP (minimal data for now)
      user = new User({
        phone,
        otp: hashedOTP,
        otpExpiry,
        isVerified: false
      });
      await user.save();
    }

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

    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Please request OTP first'
      });
    }

    // Check if OTP is expired
    if (user.otpExpiry < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'OTP has expired. Please request a new one.'
      });
    }

    // Verify OTP
    const isOTPValid = await bcrypt.compare(otp, user.otp);
    if (!isOTPValid) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // Check if user profile is complete
    const isProfileComplete = user.name && user.role && user.location;

    if (isProfileComplete) {
      // Existing user with complete profile - log them in
      await User.findByIdAndUpdate(user._id, {
        isVerified: true,
        $unset: { otp: 1, otpExpiry: 1 }
      });

      const token = jwt.sign(
        { userId: user._id, phone: user.phone, role: user.role },
        process.env.JWT_SECRET || 'fallback_secret',
        { expiresIn: '7d' }
      );

      return res.json({
        success: true,
        message: 'Login successful',
        token,
        isNewUser: false,
        user: {
          _id: user._id,
          name: user.name,
          phone: user.phone,
          role: user.role,
          location: user.location,
          categories: user.categories,
          isVerified: true
        },
        redirectTo: user.role === 'vendor' ? '/vendor-dashboard' : '/supplier-dashboard'
      });
    } else {
      // New user or incomplete profile - needs to complete signup
      return res.json({
        success: true,
        message: 'OTP verified. Please complete your profile.',
        isNewUser: true,
        phone: user.phone,
        redirectTo: '/complete-signup'
      });
    }

  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify OTP'
    });
  }
});

// Complete Signup (for new users)
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

// Logout (client-side will remove token, but we can track it server-side if needed)
router.post('/logout', (req, res) => {
  res.json({
    success: true,
    message: 'Logged out successfully'
  });
});

module.exports = router;