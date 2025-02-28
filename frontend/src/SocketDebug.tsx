import React, { useEffect } from 'react';
import { Button, Typography, Box, Paper } from '@mui/material';
import { useSocket } from './contexts/SocketContext';

const SocketDebug: React.FC = () => {
  const { connected, socket, subscribeToResource } = useSocket();
  
  useEffect(() => {
    // Log API URL from environment
    console.log('API URL from env:', process.env.REACT_APP_API_URL);
    console.log('WebSocket connection status:', connected ? 'Connected' : 'Disconnected');
    
    if (socket) {
      console.log('Socket instance:', socket);
      console.log('Socket ID:', socket.id);
      console.log('Socket connected:', socket.connected);
      console.log('Socket options:', socket.io.opts);
    }
  }, [connected, socket]);
  
  const handleSubscribe = () => {
    subscribeToResource('inventory');
  };
  
  const handleTestEmit = () => {
    if (socket && socket.connected) {
      console.log('Emitting test event');
      socket.emit('ping', { message: 'Hello from client' });
    } else {
      console.error('Socket not connected, cannot emit');
    }
  };
  
  return (
    <Paper sx={{ p: 3, m: 2 }}>
      <Typography variant="h5" gutterBottom>WebSocket Debug</Typography>
      
      <Box sx={{ mb: 2 }}>
        <Typography variant="subtitle1">
          Status: <strong>{connected ? '✅ Connected' : '❌ Disconnected'}</strong>
        </Typography>
        <Typography variant="body2">
          Socket ID: {socket?.id || 'Not connected'}
        </Typography>
      </Box>
      
      <Box sx={{ display: 'flex', gap: 2 }}>
        <Button 
          variant="contained" 
          color="primary" 
          onClick={handleSubscribe}
          disabled={!connected}
        >
          Subscribe to Inventory
        </Button>
        
        <Button 
          variant="outlined" 
          color="secondary" 
          onClick={handleTestEmit}
          disabled={!connected}
        >
          Test Emit
        </Button>
      </Box>
    </Paper>
  );
};

export default SocketDebug; 