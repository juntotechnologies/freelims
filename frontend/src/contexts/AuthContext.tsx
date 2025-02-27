import React, { createContext, useState, useContext, useEffect, ReactNode } from 'react';
import axios from 'axios';

// Get the API URL from environment variables
const API_URL = process.env.REACT_APP_API_URL || '/api';

// Define user type
export interface User {
  id: number;
  email: string;
  username: string;
  full_name: string;
  is_active: boolean;
  is_admin: boolean;
}

// Define auth context type
interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  loading: boolean;
  login: (username: string, password: string) => Promise<void>;
  register: (email: string, username: string, full_name: string, password: string) => Promise<void>;
  logout: () => void;
  error: string | null;
}

interface TokenResponse {
  access_token: string;
  token_type: string;
}

// Create context
const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Add axios interceptor to include token in requests
axios.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      // Initialize headers if they don't exist
      if (!config.headers) {
        config.headers = {};
      }
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Auth provider component
export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Check if user is already logged in on mount
  useEffect(() => {
    const checkAuth = async () => {
      const token = localStorage.getItem('token');
      if (token) {
        try {
          // Get current user info
          const response = await axios.get<User>(`${API_URL}/users/me`);
          setUser(response.data);
        } catch (err) {
          // If token is invalid, clear it
          localStorage.removeItem('token');
        }
      }
      setLoading(false);
    };

    checkAuth();
  }, []);

  // Login function
  const login = async (username: string, password: string) => {
    try {
      setError(null);
      // Use FormData for compatibility with FastAPI's OAuth2 form
      const formData = new FormData();
      formData.append('username', username);
      formData.append('password', password);

      const response = await axios.post<TokenResponse>(`${API_URL}/token`, formData);
      const { access_token } = response.data;

      // Save token to localStorage
      localStorage.setItem('token', access_token);
      
      // Get user info
      const userResponse = await axios.get<User>(`${API_URL}/users/me`);
      setUser(userResponse.data);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Login failed');
      throw err;
    }
  };

  // Register function
  const register = async (email: string, username: string, fullName: string, password: string) => {
    try {
      setError(null);
      await axios.post(`${API_URL}/register`, {
        email,
        username,
        full_name: fullName,
        password
      });
      // Auto login after registration
      await login(username, password);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Registration failed');
      throw err;
    }
  };

  // Logout function
  const logout = () => {
    localStorage.removeItem('token');
    setUser(null);
  };

  // Context value
  const value = {
    user,
    isAuthenticated: !!user,
    loading,
    login,
    register,
    logout,
    error
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

// Custom hook to use auth context
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}; 