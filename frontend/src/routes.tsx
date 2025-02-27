import React from 'react';
import { Navigate, RouteObject } from 'react-router-dom';
import AuthLayout from './components/layouts/AuthLayout';
import DashboardLayout from './components/layouts/DashboardLayout';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import SampleManagement from './pages/SampleManagement';
import TestManagement from './pages/TestManagement';
import QualityControl from './pages/QualityControl';
import Users from './pages/Users';
import Settings from './pages/Settings';
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

// Public route wrapper component (redirects to dashboard if already authenticated)
const PublicRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated } = useAuth();
  
  if (isAuthenticated) {
    return <Navigate to="/dashboard" />;
  }
  
  return <>{children}</>;
};

// Define routes
const routes: RouteObject[] = [
  {
    path: '/',
    element: <Navigate to="/dashboard" />,
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
        path: 'dashboard',
        element: <Dashboard />,
      },
      {
        path: 'inventory',
        element: <Inventory />,
      },
      {
        path: 'samples',
        element: <SampleManagement />,
      },
      {
        path: 'tests',
        element: <TestManagement />,
      },
      {
        path: 'quality-control',
        element: <QualityControl />,
      },
      {
        path: 'users',
        element: <Users />,
      },
      {
        path: 'settings',
        element: <Settings />,
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