import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Paper,
  Card,
  CardContent,
  Divider,
  CircularProgress,
} from '@mui/material';
import {
  Assignment as AssignmentIcon,
  Inventory as InventoryIcon,
  People as PeopleIcon,
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import axios from 'axios';

// Dashboard stat card component
interface StatCardProps {
  title: string;
  value: number | string;
  icon: React.ReactNode;
  color: string;
  loading?: boolean;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, icon, color, loading = false }) => (
  <Card sx={{ height: '100%' }}>
    <CardContent>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="subtitle2" color="text.secondary">
            {title}
          </Typography>
          <Typography variant="h4" sx={{ mt: 1 }}>
            {loading ? <CircularProgress size={24} /> : value}
          </Typography>
        </Box>
        <Box
          sx={{
            backgroundColor: `${color}20`, // 20% opacity
            borderRadius: '50%',
            p: 1,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          {React.cloneElement(icon as React.ReactElement, { sx: { color } })}
        </Box>
      </Box>
    </CardContent>
  </Card>
);

// Recent activity component
interface ActivityItem {
  id: number;
  action: string;
  user: string;
  timestamp: string;
}

const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    pendingTests: 0,
    inventoryItems: 0,
    activeUsers: 0
  });
  const [recentActivities, setRecentActivities] = useState<ActivityItem[]>([]);

  useEffect(() => {
    // In a real implementation, this would fetch actual data from the backend
    setLoading(false);
    
    // This is a placeholder - in a real implementation, 
    // you would fetch these values from API endpoints
    // For now, we're setting them to 0 as requested
    setStats({
      pendingTests: 0,
      inventoryItems: 0,
      activeUsers: 0
    });
    
    // Setting an empty array for activities as requested
    setRecentActivities([]);
  }, []);

  return (
    <Box>
      <Typography variant="h4" sx={{ mb: 4 }}>
        Welcome, {user?.full_name || user?.username}
      </Typography>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Pending Tests"
            value={stats.pendingTests}
            icon={<AssignmentIcon />}
            color="#ff9800"
            loading={loading}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Inventory Items"
            value={stats.inventoryItems}
            icon={<InventoryIcon />}
            color="#2196f3"
            loading={loading}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Active Users"
            value={stats.activeUsers}
            icon={<PeopleIcon />}
            color="#9c27b0"
            loading={loading}
          />
        </Grid>
      </Grid>

      {/* Recent Activity */}
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" sx={{ mb: 2 }}>
          Recent Activity
        </Typography>
        <Divider sx={{ mb: 2 }} />
        {recentActivities.length > 0 ? (
          recentActivities.map((activity) => (
            <Box
              key={activity.id}
              sx={{
                py: 1.5,
                borderBottom: '1px solid',
                borderColor: 'divider',
                '&:last-child': {
                  borderBottom: 'none',
                },
              }}
            >
              <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Typography variant="body1">{activity.action}</Typography>
                <Typography variant="body2" color="text.secondary">
                  {activity.timestamp}
                </Typography>
              </Box>
              <Typography variant="body2" color="text.secondary">
                by {activity.user}
              </Typography>
            </Box>
          ))
        ) : (
          <Typography variant="body2" color="text.secondary" sx={{ py: 2 }}>
            No recent activity to display
          </Typography>
        )}
      </Paper>
    </Box>
  );
};

export default Dashboard; 