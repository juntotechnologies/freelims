import React from 'react';
import { Outlet } from 'react-router-dom';
import DashboardLayout from './layouts/DashboardLayout';

/**
 * Main Layout component that wraps the application routes
 * Uses DashboardLayout for authenticated routes
 */
const Layout: React.FC = () => {
  return (
    <DashboardLayout>
      <Outlet />
    </DashboardLayout>
  );
};

export default Layout; 