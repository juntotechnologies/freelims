import React from 'react';
import { Outlet, Navigate } from 'react-router-dom';
import { Container, Box, Paper, Typography } from '@mui/material';
import { useAuth } from '../../contexts/AuthContext';

const AuthLayout: React.FC = () => {
  const { isAuthenticated, loading } = useAuth();

  // If user is already authenticated, redirect to dashboard
  if (isAuthenticated && !loading) {
    return <Navigate to="/" />;
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: 'background.default',
        py: 4,
      }}
    >
      <Container maxWidth="sm">
        <Paper
          elevation={3}
          sx={{
            p: 4,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
          }}
        >
          <Typography
            component="h1"
            variant="h4"
            sx={{ mb: 4, fontWeight: 'bold', color: 'primary.main' }}
          >
            CHEM-IS-TRY Inc. LIMS
          </Typography>
          <Outlet />
        </Paper>
      </Container>
    </Box>
  );
};

export default AuthLayout; 