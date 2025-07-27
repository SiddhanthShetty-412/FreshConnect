import axios from 'axios';
import { SignupData, User, Supplier, Message } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const authAPI = {
  sendOTP: async (phone: string) => {
    const response = await api.post('/auth/send-otp', { phone });
    return response.data;
  },

  verifyOTP: async (phone: string, otp: string) => {
    const response = await api.post('/auth/verify-otp', { phone, otp });
    return response.data;
  },

  signup: async (userData: SignupData) => {
    const response = await api.post('/auth/signup', userData);
    return response.data;
  },
};

export const supplierAPI = {
  getByLocation: async (location: string, category?: string) => {
    const response = await api.get(`/suppliers?location=${location}&category=${category || ''}`);
    return response.data;
  },

  getById: async (id: string) => {
    const response = await api.get(`/suppliers/${id}`);
    return response.data;
  },

  updateProfile: async (data: Partial<Supplier>) => {
    const response = await api.put('/suppliers/profile', data);
    return response.data;
  },
};

export const messageAPI = {
  getConversation: async (userId1: string, userId2: string) => {
    const response = await api.get(`/messages/${userId1}/${userId2}`);
    return response.data;
  },

  sendMessage: async (message: Partial<Message>) => {
    const response = await api.post('/messages', message);
    return response.data;
  },

  getConversations: async () => {
    const response = await api.get('/messages/conversations');
    return response.data;
  },
};

export default api;