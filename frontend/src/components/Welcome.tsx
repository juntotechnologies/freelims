import React, { useEffect, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Typography } from '@mui/material';

const Welcome: React.FC = () => {
  const { user } = useAuth();
  
  return (
    <Typography variant="h4">
      Welcome, {user?.full_name}
    </Typography>
  );
};

export default Welcome; 