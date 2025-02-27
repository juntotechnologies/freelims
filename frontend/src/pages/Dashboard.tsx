import React from 'react';
import {
  Box,
  Typography,
  Grid,
  Paper,
  Card,
  CardContent,
  Divider,
} from '@mui/material';
import {
  Science as ScienceIcon,
  Assignment as AssignmentIcon,
  Inventory as InventoryIcon,
  People as PeopleIcon,
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';

// Dashboard stat card component
interface StatCardProps {
  title: string;
  value: number;
  icon: React.ReactNode;
  color: string;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, icon, color }) => (
  <Card sx={{ height: '100%' }}>
    <CardContent>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="subtitle2" color="text.secondary">
            {title}
          </Typography>
          <Typography variant="h4" sx={{ mt: 1 }}>
            {value}
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

const recentActivities: ActivityItem[] = [
  {
    id: 1,
    action: 'Added new sample',
    user: 'John Doe',
    timestamp: '2 hours ago',
  },
  {
    id: 2,
    action: 'Updated test result',
    user: 'Jane Smith',
    timestamp: '3 hours ago',
  },
  {
    id: 3,
    action: 'Created new inventory item',
    user: 'Mike Johnson',
    timestamp: '5 hours ago',
  },
  {
    id: 4,
    action: 'Completed test',
    user: 'Sarah Williams',
    timestamp: '1 day ago',
  },
];

const Dashboard: React.FC = () => {
  const { user } = useAuth();

  return (
    <Box>
      <Typography variant="h4" sx={{ mb: 4 }}>
        Welcome, {user?.full_name || user?.username}
      </Typography>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Samples"
            value={256}
            icon={<ScienceIcon />}
            color="#4caf50"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Pending Tests"
            value={42}
            icon={<AssignmentIcon />}
            color="#ff9800"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Inventory Items"
            value={189}
            icon={<InventoryIcon />}
            color="#2196f3"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Users"
            value={18}
            icon={<PeopleIcon />}
            color="#9c27b0"
          />
        </Grid>
      </Grid>

      {/* Recent Activity */}
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" sx={{ mb: 2 }}>
          Recent Activity
        </Typography>
        <Divider sx={{ mb: 2 }} />
        {recentActivities.map((activity) => (
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
        ))}
      </Paper>
    </Box>
  );
};

export default Dashboard; 