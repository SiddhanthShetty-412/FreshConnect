const express = require('express');
const mongoose = require('mongoose');
const Message = require('../models/Message');
const User = require('../models/User');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get conversation between two users
router.get('/:userId1/:userId2', authenticateToken, async (req, res) => {
  try {
    const { userId1, userId2 } = req.params;
    
    // Verify the requesting user is part of the conversation
    if (req.user.userId !== userId1 && req.user.userId !== userId2) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const messages = await Message.find({
      $or: [
        { senderId: userId1, receiverId: userId2 },
        { senderId: userId2, receiverId: userId1 }
      ]
    })
    .sort({ createdAt: 1 })
    .populate('senderId', 'name phone role')
    .populate('receiverId', 'name phone role');

    // Mark messages as read for the requesting user
    await Message.updateMany(
      {
        receiverId: req.user.userId,
        senderId: { $in: [userId1, userId2] },
        isRead: false
      },
      { isRead: true }
    );

    res.json({
      success: true,
      messages: messages.map(msg => ({
        _id: msg._id,
        senderId: msg.senderId._id,
        receiverId: msg.receiverId._id,
        content: msg.content,
        orderDetails: msg.orderDetails,
        timestamp: msg.createdAt,
        isRead: msg.isRead
      }))
    });

  } catch (error) {
    console.error('Get conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch messages'
    });
  }
});

// Send message
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { receiverId, content, orderDetails } = req.body;
    const senderId = req.user.userId;

    if (!receiverId || !content.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Receiver ID and content are required'
      });
    }

    // Verify receiver exists
    const receiver = await User.findById(receiverId);
    if (!receiver) {
      return res.status(404).json({
        success: false,
        message: 'Receiver not found'
      });
    }

    const message = new Message({
      senderId,
      receiverId,
      content: content.trim(),
      orderDetails
    });

    await message.save();
    await message.populate('senderId', 'name phone role');
    await message.populate('receiverId', 'name phone role');

    res.status(201).json({
      success: true,
      message: {
        _id: message._id,
        senderId: message.senderId._id,
        receiverId: message.receiverId._id,
        content: message.content,
        orderDetails: message.orderDetails,
        timestamp: message.createdAt,
        isRead: message.isRead
      }
    });

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send message'
    });
  }
});

// Get user's conversations
router.get('/conversations', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get all conversations where user is involved
    const conversations = await Message.aggregate([
      {
        $match: {
          $or: [
            { senderId: mongoose.Types.ObjectId(userId) },
            { receiverId: mongoose.Types.ObjectId(userId) }
          ]
        }
      },
      {
        $sort: { createdAt: -1 }
      },
      {
        $group: {
          _id: {
            $cond: {
              if: { $eq: ['$senderId', mongoose.Types.ObjectId(userId)] },
              then: '$receiverId',
              else: '$senderId'
            }
          },
          lastMessage: { $first: '$$ROOT' },
          unreadCount: {
            $sum: {
              $cond: {
                if: {
                  $and: [
                    { $eq: ['$receiverId', mongoose.Types.ObjectId(userId)] },
                    { $eq: ['$isRead', false] }
                  ]
                },
                then: 1,
                else: 0
              }
            }
          }
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'user'
        }
      },
      {
        $unwind: '$user'
      },
      {
        $project: {
          user: {
            _id: '$user._id',
            name: '$user.name',
            phone: '$user.phone',
            role: '$user.role',
            location: '$user.location'
          },
          lastMessage: {
            _id: '$lastMessage._id',
            content: '$lastMessage.content',
            timestamp: '$lastMessage.createdAt',
            senderId: '$lastMessage.senderId',
            receiverId: '$lastMessage.receiverId'
          },
          unreadCount: 1
        }
      },
      {
        $sort: { 'lastMessage.timestamp': -1 }
      }
    ]);

    res.json({
      success: true,
      conversations
    });

  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch conversations'
    });
  }
});

module.exports = router;