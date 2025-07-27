export interface User {
  _id: string;
  name: string;
  phone: string;
  role: 'vendor' | 'supplier';
  location: string;
  isVerified: boolean;
  createdAt: string;
}

export interface Supplier extends User {
  categories: string[];
  rating: number;
  totalOrders: number;
  deliveryTime: string;
  stockAvailability: boolean;
  description: string;
}

export interface Message {
  _id: string;
  senderId: string;
  receiverId: string;
  content: string;
  timestamp: string;
  orderDetails?: {
    category: string;
    quantity: string;
    deliveryAddress: string;
  };
}

export interface AuthContextType {
  user: User | null;
  login: (phone: string, otp: string) => Promise<boolean>;
  signup: (userData: SignupData) => Promise<boolean>;
  logout: () => void;
  sendOTP: (phone: string) => Promise<boolean>;
  isLoading: boolean;
}

export interface SignupData {
  name: string;
  phone: string;
  role: 'vendor' | 'supplier';
  location: string;
  categories?: string[];
  description?: string;
}