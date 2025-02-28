import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { Container, CssBaseline } from '@mui/material';
import Layout from './components/Layout';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Inventory from './pages/Inventory';
import Experiments from './pages/Experiments';
import Tests from './pages/Tests';
import Settings from './pages/Settings';
import { useAuth } from './contexts/AuthContext';
import SocketDebug from './SocketDebug';
import AuthLayout from './components/layouts/AuthLayout';

function App() {
  const { isAuthenticated, user } = useAuth();

  // Protected route component
  const ProtectedRoute = ({ element }: { element: React.ReactElement }) => {
    return isAuthenticated ? element : <Navigate to="/login" />;
  };

  return (
    <>
      <CssBaseline />
      <Container maxWidth={false} disableGutters sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
        <Routes>
          <Route element={<AuthLayout />}>
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
          </Route>
          <Route path="/" element={<ProtectedRoute element={<Layout />} />}>
            <Route index element={<Dashboard />} />
            <Route path="inventory" element={<Inventory />} />
            <Route path="experiments" element={<Experiments />} />
            <Route path="tests" element={<Tests />} />
            <Route path="settings" element={<Settings />} />
            <Route path="socket-debug" element={<SocketDebug />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Container>
    </>
  );
}

export default App; 