import React, { useState, useEffect, useRef } from 'react';
import { useParams, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { messageAPI } from '../../services/api';
import { Message } from '../../types';
import { Send, ArrowLeft, Phone, MapPin } from 'lucide-react';
import { motion } from 'framer-motion';
import io from 'socket.io-client';

const ChatPage: React.FC = () => {
  const { userId } = useParams<{ userId: string }>();
  const location = useLocation();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [orderDetails, setOrderDetails] = useState({
    category: '',
    quantity: '',
    deliveryAddress: ''
  });
  const [showOrderForm, setShowOrderForm] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const socketRef = useRef<any>(null);

  const otherUserName = location.state?.supplierName || location.state?.vendorName || 'User';
  const otherUserLocation = location.state?.supplierLocation || '';
  const isSupplier = location.state?.isSupplier || false;

  useEffect(() => {
    if (!userId || !user) return;

    // Initialize socket connection
    socketRef.current = io(import.meta.env.VITE_API_URL || 'http://localhost:5000');
    
    socketRef.current.emit('join', { userId: user._id });
    
    socketRef.current.on('newMessage', (message: Message) => {
      if (message.senderId === userId || message.receiverId === userId) {
        setMessages(prev => [...prev, message]);
      }
    });

    fetchMessages();

    return () => {
      if (socketRef.current) {
        socketRef.current.disconnect();
      }
    };
  }, [userId, user]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const fetchMessages = async () => {
    if (!userId || !user) return;
    
    try {
      const data = await messageAPI.getConversation(user._id, userId);
      setMessages(data.messages || []);
    } catch (error) {
      console.error('Error fetching messages:', error);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const sendMessage = async (content: string, orderData?: any) => {
    if (!userId || !user || !content.trim()) return;

    const messageData = {
      senderId: user._id,
      receiverId: userId,
      content,
      orderDetails: orderData
    };

    try {
      const response = await messageAPI.sendMessage(messageData);
      const newMsg = response.message;
      setMessages(prev => [...prev, newMsg]);
      
      // Emit via socket
      socketRef.current?.emit('sendMessage', newMsg);
      
      setNewMessage('');
      setShowOrderForm(false);
      setOrderDetails({ category: '', quantity: '', deliveryAddress: '' });
    } catch (error) {
      console.error('Error sending message:', error);
    }
  };

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    sendMessage(newMessage);
  };

  const handleSendOrder = (e: React.FormEvent) => {
    e.preventDefault();
    const orderMessage = `New Order Request:
Category: ${orderDetails.category}
Quantity: ${orderDetails.quantity}
Delivery Address: ${orderDetails.deliveryAddress}

Please confirm availability and pricing.`;
    
    sendMessage(orderMessage, orderDetails);
  };

  return (
    <div className="max-w-4xl mx-auto h-screen flex flex-col bg-white">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <button
              onClick={() => navigate('/')}
              className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            >
              <ArrowLeft className="h-5 w-5 text-gray-600" />
            </button>
            <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
              <span className="text-green-700 font-semibold">
                {otherUserName.charAt(0).toUpperCase()}
              </span>
            </div>
            <div>
              <h2 className="font-semibold text-gray-900">{otherUserName}</h2>
              {otherUserLocation && (
                <div className="flex items-center text-sm text-gray-500">
                  <MapPin className="h-3 w-3 mr-1" />
                  {otherUserLocation}
                </div>
              )}
            </div>
          </div>
          <div className="flex items-center space-x-2">
            <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
              <Phone className="h-5 w-5 text-gray-600" />
            </button>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-6 py-4 space-y-4">
        {messages.map((message, index) => {
          const isOwnMessage = message.senderId === user?._id;
          return (
            <motion.div
              key={message._id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className={`flex ${isOwnMessage ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-xs lg:max-w-md px-4 py-2 rounded-lg ${
                  isOwnMessage
                    ? 'bg-green-600 text-white'
                    : 'bg-gray-100 text-gray-900'
                }`}
              >
                {message.orderDetails && (
                  <div className="mb-2 p-2 bg-black bg-opacity-10 rounded text-sm">
                    <strong>Order Details:</strong>
                    <br />
                    Category: {message.orderDetails.category}
                    <br />
                    Quantity: {message.orderDetails.quantity}
                    <br />
                    Address: {message.orderDetails.deliveryAddress}
                  </div>
                )}
                <p className="whitespace-pre-wrap">{message.content}</p>
                <p className={`text-xs mt-1 ${isOwnMessage ? 'text-green-100' : 'text-gray-500'}`}>
                  {new Date(message.timestamp).toLocaleTimeString()}
                </p>
              </div>
            </motion.div>
          );
        })}
        <div ref={messagesEndRef} />
      </div>

      {/* Order Form */}
      {showOrderForm && user?.role === 'vendor' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gray-50 border-t border-gray-200 px-6 py-4"
        >
          <form onSubmit={handleSendOrder} className="space-y-4">
            <h3 className="font-medium text-gray-900">Send Order Request</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <select
                value={orderDetails.category}
                onChange={(e) => setOrderDetails(prev => ({ ...prev, category: e.target.value }))}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                required
              >
                <option value="">Select Category</option>
                <option value="Vegetables">Vegetables</option>
                <option value="Fruits">Fruits</option>
                <option value="Grains">Grains</option>
                <option value="Meat">Meat</option>
                <option value="Dairy Products">Dairy Products</option>
              </select>
              <input
                type="text"
                value={orderDetails.quantity}
                onChange={(e) => setOrderDetails(prev => ({ ...prev, quantity: e.target.value }))}
                placeholder="Quantity (e.g., 10 kg)"
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                required
              />
              <input
                type="text"
                value={orderDetails.deliveryAddress}
                onChange={(e) => setOrderDetails(prev => ({ ...prev, deliveryAddress: e.target.value }))}
                placeholder="Delivery Address"
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                required
              />
            </div>
            <div className="flex space-x-2">
              <button
                type="submit"
                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
              >
                Send Order Request
              </button>
              <button
                type="button"
                onClick={() => setShowOrderForm(false)}
                className="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition-colors"
              >
                Cancel
              </button>
            </div>
          </form>
        </motion.div>
      )}

      {/* Message Input */}
      <div className="bg-white border-t border-gray-200 px-6 py-4">
        <form onSubmit={handleSendMessage} className="flex items-center space-x-4">
          {user?.role === 'vendor' && !showOrderForm && (
            <button
              type="button"
              onClick={() => setShowOrderForm(true)}
              className="px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm"
            >
              Order
            </button>
          )}
          <div className="flex-1 flex items-center space-x-2">
            <input
              type="text"
              value={newMessage}
              onChange={(e) => setNewMessage(e.target.value)}
              placeholder="Type your message..."
              className="flex-1 px-4 py-2 border border-gray-300 rounded-full focus:ring-2 focus:ring-green-500 focus:border-transparent"
            />
            <button
              type="submit"
              disabled={!newMessage.trim()}
              className="p-2 bg-green-600 text-white rounded-full hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <Send className="h-5 w-5" />
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ChatPage;