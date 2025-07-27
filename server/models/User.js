const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  phone: {
    type: String,
    required: true,
    unique: true,
    validate: {
      validator: function(v) {
        return /^[0-9]{10}$/.test(v);
      },
      message: 'Phone number must be 10 digits'
    }
  },
  role: {
    type: String,
    enum: ['vendor', 'supplier'],
    required: true
  },
  location: {
    type: String,
    enum: ['Vasai', 'Nalla Sopara', 'Virar'],
    required: true
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  // Supplier specific fields
  categories: [{
    type: String,
    enum: ['Vegetables', 'Fruits', 'Grains', 'Meat', 'Dairy Products']
  }],
  description: {
    type: String,
    trim: true
  },
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  totalOrders: {
    type: Number,
    default: 0
  },
  deliveryTime: {
    type: String,
    default: '2-4 hours'
  },
  stockAvailability: {
    type: Boolean,
    default: true
  },
  // OTP related fields
  otp: {
    type: String
  },
  otpExpiry: {
    type: Date
  }
}, {
  timestamps: true
});

// Create indexes for better query performance
userSchema.index({ phone: 1 });
userSchema.index({ role: 1, location: 1 });
userSchema.index({ categories: 1 });

module.exports = mongoose.model('User', userSchema);