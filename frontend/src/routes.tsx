import React from 'react';
import { Navigate, RouteObject } from 'react-router-dom';
import AuthLayout from './components/layouts/AuthLayout';
import DashboardLayout from './components/layouts/DashboardLayout';
import Login from './pages/Login';
import Register from './pages/Register';
import Inventory from './pages/Inventory';
import LocationAuditLogs from './pages/LocationAuditLogs';
import NotFound from './pages/NotFound';
import { useAuth } from './contexts/AuthContext';

// Protected route wrapper component
const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated } = useAuth();
  
  if (!isAuthenticated) {
    return <Navigate to="/login" />;
  }
  
  return <>{children}</>;
};

// Public route wrapper component (redirects to inventory if already authenticated)
const PublicRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated } = useAuth();
  
  if (isAuthenticated) {
    return <Navigate to="/inventory" />;
  }
  
  return <>{children}</>;
};

// Define routes
const routes: RouteObject[] = [
  {
    path: '/',
    element: <Navigate to="/inventory" />,
  },
  {
    path: '/',
    element: <AuthLayout />,
    children: [
      {
        path: 'login',
        element: (
          <PublicRoute>
            <Login />
          </PublicRoute>
        ),
      },
      {
        path: 'register',
        element: (
          <PublicRoute>
            <Register />
          </PublicRoute>
        ),
      },
    ],
  },
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <DashboardLayout />
      </ProtectedRoute>
    ),
    children: [
      {
        path: 'inventory',
        element: <Inventory />,
      },
      {
        path: 'audit/locations',
        element: <LocationAuditLogs />,
      },
    ],
  },
  {
    path: '*',
    element: <NotFound />,
  },
];

export default routes; 