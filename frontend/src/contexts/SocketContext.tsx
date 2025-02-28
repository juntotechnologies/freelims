import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { io, Socket } from 'socket.io-client';
import { useQueryClient } from 'react-query';
import { useAuth } from './AuthContext';

// Define types
interface SocketContextType {
  socket: Socket | null;
  connected: boolean;
  subscribeToResource: (resource: string) => void;
  unsubscribeFromResource: (resource: string) => void;
}

// Get API URL from environment or use default
const API_URL = process.env.REACT_APP_API_URL || '';
// Extract the base URL without "/api" for WebSocket connection
const BASE_URL = API_URL.replace(/\/api$/, '');
const WS_URL = BASE_URL || 'http://localhost:8001';

// Create context with default values
const SocketContext = createContext<SocketContextType | undefined>(undefined);

// Custom hook to use the socket context
export const useSocket = () => {
  const context = useContext(SocketContext);
  if (!context) {
    throw new Error('useSocket must be used within a SocketProvider');
  }
  return context;
};

// SocketProvider component
export const SocketProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [connected, setConnected] = useState(false);
  const { isAuthenticated } = useAuth();
  const queryClient = useQueryClient();

  // Initialize socket connection when authenticated
  useEffect(() => {
    if (!isAuthenticated) {
      // Cleanup socket if user logs out
      if (socket) {
        socket.disconnect();
        setSocket(null);
        setConnected(false);
      }
      return;
    }

    console.log('Initializing Socket.IO connection to:', `${WS_URL}/ws`);
    const socketIo = io(`${WS_URL}/ws`, {
      transports: ['websocket'],
      autoConnect: true,
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 10,
      path: '' // Important: clear the default path since we specify it in the URL
    });

    // Socket event listeners
    socketIo.on('connect', () => {
      console.log('Socket.IO connected with ID:', socketIo.id);
      setConnected(true);
    });

    socketIo.on('disconnect', () => {
      console.log('Socket.IO disconnected');
      setConnected(false);
    });

    socketIo.on('connect_error', (error) => {
      console.error('Socket.IO connection error:', error);
      setConnected(false);
    });

    // Handle inventory updates
    socketIo.on('inventory_updated', (data) => {
      console.log('Received inventory update:', data);
      // Invalidate the inventory query to trigger a refetch
      queryClient.invalidateQueries('inventory');
    });

    // Handle experiment updates
    socketIo.on('experiments_updated', (data) => {
      console.log('Received experiment update:', data);
      queryClient.invalidateQueries('experiments');
    });

    // Handle sample updates
    socketIo.on('samples_updated', (data) => {
      console.log('Received sample update:', data);
      queryClient.invalidateQueries('samples');
    });

    // Handle test updates
    socketIo.on('tests_updated', (data) => {
      console.log('Received test update:', data);
      queryClient.invalidateQueries('tests');
    });

    // Store the socket instance
    setSocket(socketIo);

    // Cleanup on unmount
    return () => {
      console.log('Cleaning up Socket.IO connection');
      socketIo.disconnect();
      setSocket(null);
      setConnected(false);
    };
  }, [isAuthenticated, queryClient]);

  // Function to subscribe to updates for a specific resource
  const subscribeToResource = (resource: string) => {
    if (socket && connected) {
      console.log(`Subscribing to ${resource} updates`);
      socket.emit('subscribe', { resource });
    } else {
      console.warn(`Cannot subscribe to ${resource}: socket disconnected`);
    }
  };

  // Function to unsubscribe from updates for a specific resource
  const unsubscribeFromResource = (resource: string) => {
    if (socket && connected) {
      console.log(`Unsubscribing from ${resource} updates`);
      socket.emit('unsubscribe', { resource });
    }
  };

  return (
    <SocketContext.Provider value={{ socket, connected, subscribeToResource, unsubscribeFromResource }}>
      {children}
    </SocketContext.Provider>
  );
}; 