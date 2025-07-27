const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const twilio = require('twilio');
const User = require('../models/User');

const router = express.Router();

// Initialize Twilio client
const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

// Generate random 6-digit OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Send OTP
router.post('/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone || phone.length !== 10) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid 10-digit phone number'
      });
    }

    const otp = generateOTP();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // For development, we'll mock the OTP as 123456
    const mockOTP = process.env.NODE_ENV === 'development' ? '123456' : otp;

    // Update or create user with OTP
    await User.findOneAndUpdate(
      { phone },
      { 
        otp: await bcrypt.hash(mockOTP, 10),
        otpExpiry 
      },
      { upsert: true, new: true }
    );

    // In production, send actual SMS
    if (process.env.NODE_ENV === 'production' && process.env.TWILIO_ACCOUNT_SID) {
      try {
        await twilioClient.messages.create({
          body: `Your FreshConnect OTP is: ${otp}. Valid for 10 minutes.`,
          from: process.env.TWILIO_PHONE_NUMBER,
          to: `+91${phone}`
        });
      } catch (twilioError) {
        console.error('Twilio error:', twilioError);
        // Continue anyway for demo purposes
      }
    }

    console.log(`OTP for ${phone}: ${mockOTP}`); // For development testing

    res.json({
      success: true,
      message: 'OTP sent successfully',
      ...(process.env.NODE_ENV === 'development' && { otp: mockOTP }) // Include OTP in response for development
    });

  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send OTP'
    });
  }
});

// Verify OTP and Login
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
        message: 'User not found'
      });
    }

    // Check if OTP is expired
    if (user.otpExpiry < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'OTP has expired'
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
    if (!user.name || !user.role || !user.location) {
      return res.status(400).json({
        success: false,
        message: 'Please complete your profile first',
        requiresSignup: true
      });
    }

    // Update user as verified and clear OTP
    await User.findByIdAndUpdate(user._id, {
      isVerified: true,
      $unset: { otp: 1, otpExpiry: 1 }
    });

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, phone: user.phone, role: user.role },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        _id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        location: user.location,
        isVerified: true,
        createdAt: user.createdAt
      }
    });

  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify OTP'
    });
  }
});

// Signup
router.post('/signup', async (req, res) => {
  try {
    const { name, phone, role, location, categories, description, otp } = req.body;

    if (!name || !phone || !role || !location || !otp) {
      return res.status(400).json({
        success: false,
        message: 'All required fields must be provided'
      });
    }

    // Find user by phone
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
        message: 'OTP has expired'
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

    // Update user profile
    const updateData = {
      name: name.trim(),
      role,
      location,
      isVerified: true,
      $unset: { otp: 1, otpExpiry: 1 }
    };

    // Add supplier-specific fields
    if (role === 'supplier') {
      updateData.categories = categories || [];
      updateData.description = description?.trim() || '';
      updateData.rating = 4.5; // Default rating for new suppliers
    }

    const updatedUser = await User.findByIdAndUpdate(
      user._id,
      updateData,
      { new: true }
    );

    // Generate JWT token
    const token = jwt.sign(
      { userId: updatedUser._id, phone: updatedUser.phone, role: updatedUser.role },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      token,
      user: {
        _id: updatedUser._id,
        name: updatedUser.name,
        phone: updatedUser.phone,
        role: updatedUser.role,
        location: updatedUser.location,
        isVerified: true,
        createdAt: updatedUser.createdAt
      }
    });

  } catch (error) {
    console.error('Signup error:', error);
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Phone number already registered'
      });
    }
    res.status(500).json({
      success: false,
      message: 'Failed to create account'
    });
  }
});

module.exports = router;