import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, AuthContextType, SignupData } from '../types';
import { authAPI } from '../services/api';
import toast from 'react-hot-toast';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem('token');
    const userData = localStorage.getItem('user');
    if (token && userData) {
      setUser(JSON.parse(userData));
    }
  }, []);

  const sendOTP = async (phone: string): Promise<boolean> => {
    setIsLoading(true);
    try {
      await authAPI.sendOTP(phone);
      toast.success('OTP sent successfully!');
      return true;
    } catch (error) {
      toast.error('Failed to send OTP. Please try again.');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (phone: string, otp: string): Promise<boolean> => {
    setIsLoading(true);
    try {
      const response = await authAPI.verifyOTP(phone, otp);
      if (response.success) {
        setUser(response.user);
        localStorage.setItem('token', response.token);
        localStorage.setItem('user', JSON.stringify(response.user));
        toast.success('Login successful!');
        return true;
      }
      return false;
    } catch (error) {
      toast.error('Invalid OTP. Please try again.');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const signup = async (userData: SignupData): Promise<boolean> => {
    setIsLoading(true);
    try {
      const response = await authAPI.signup(userData);
      if (response.success) {
        setUser(response.user);
        localStorage.setItem('token', response.token);
        localStorage.setItem('user', JSON.stringify(response.user));
        toast.success('Account created successfully!');
        return true;
      }
      return false;
    } catch (error) {
      toast.error('Failed to create account. Please try again.');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    toast.success('Logged out successfully!');
  };

  return (
    <AuthContext.Provider value={{
      user,
      login,
      signup,
      logout,
      sendOTP,
      isLoading
    }}>
      {children}
    </AuthContext.Provider>
  );
};