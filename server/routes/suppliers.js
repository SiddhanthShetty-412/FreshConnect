const express = require('express');
const User = require('../models/User');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get suppliers by location and category
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { location, category } = req.query;
    
    let query = { role: 'supplier', isVerified: true };
    
    if (location) {
      query.location = location;
    }
    
    if (category) {
      query.categories = { $in: [category] };
    }

    const suppliers = await User.find(query)
      .select('-otp -otpExpiry -__v')
      .sort({ rating: -1, totalOrders: -1 });

    res.json({
      success: true,
      suppliers
    });

  } catch (error) {
    console.error('Get suppliers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch suppliers'
    });
  }
});

// Get supplier by ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const supplier = await User.findOne({ 
      _id: id, 
      role: 'supplier', 
      isVerified: true 
    }).select('-otp -otpExpiry -__v');

    if (!supplier) {
      return res.status(404).json({
        success: false,
        message: 'Supplier not found'
      });
    }

    res.json({
      success: true,
      supplier
    });

  } catch (error) {
    console.error('Get supplier error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch supplier'
    });
  }
});

// Update supplier profile
router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { categories, description, deliveryTime } = req.body;
    console.log('User role from token:', req.user && req.user.role);

    // Verify user is a supplier
    const user = await User.findOne({ _id: userId, role: 'supplier' });
    if (!user) {
      return res.status(403).json({
        success: false,
        message: `Only suppliers can update this profile (your role: ${req.user && req.user.role ? req.user.role : 'unknown'})`
      });
    }

    const updateData = {};
    if (categories) updateData.categories = categories;
    if (description) updateData.description = description.trim();
    if (deliveryTime) updateData.deliveryTime = deliveryTime;

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true }
    ).select('-otp -otpExpiry -__v');

    res.json({
      success: true,
      message: 'Profile updated successfully',
      supplier: updatedUser
    });

  } catch (error) {
    console.error('Update supplier profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update profile'
    });
  }
});

module.exports = router;