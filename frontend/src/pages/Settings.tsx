import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Grid,
  Paper,
  Typography,
  TextField,
  Button,
  Divider,
  FormControlLabel,
  Switch,
  Tabs,
  Tab,
  Alert,
  Snackbar,
  CircularProgress,
} from '@mui/material';
import axios from 'axios';
import { useAuth } from '../contexts/AuthContext';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

interface SystemSettings {
  company_name: string;
  system_email: string;
  backup_enabled: boolean;
  backup_frequency: string;
  backup_location: string;
  email_notifications: boolean;
  auto_logout: number;
  password_expiry: number;
  require_two_factor: boolean;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`settings-tabpanel-${index}`}
      aria-labelledby={`settings-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

const Settings: React.FC = () => {
  const { user } = useAuth();
  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [settings, setSettings] = useState<SystemSettings>({
    company_name: '',
    system_email: '',
    backup_enabled: true,
    backup_frequency: 'daily',
    backup_location: '/backup',
    email_notifications: true,
    auto_logout: 30,
    password_expiry: 90,
    require_two_factor: false,
  });

  useEffect(() => {
    const fetchSettings = async () => {
      setLoading(true);
      setError(null);
      try {
        const response = await axios.get<SystemSettings>('/api/settings/');
        setSettings(response.data);
      } catch (err: any) {
        setError(err.response?.data?.detail || 'Failed to load settings');
      } finally {
        setLoading(false);
      }
    };

    fetchSettings();
  }, []);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, checked, type } = event.target;
    setSettings((prev) => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }));
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      await axios.put('/api/settings/', settings);
      setSuccess(true);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to save settings');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Typography variant="h4" component="h1" gutterBottom>
            System Settings
          </Typography>
        </Grid>

        {error && (
          <Grid item xs={12}>
            <Alert severity="error">{error}</Alert>
          </Grid>
        )}

        <Grid item xs={12}>
          <Paper sx={{ width: '100%' }}>
            <Tabs
              value={tabValue}
              onChange={handleTabChange}
              indicatorColor="primary"
              textColor="primary"
              centered
            >
              <Tab label="General" />
              <Tab label="Security" />
              <Tab label="Backup" />
            </Tabs>

            <TabPanel value={tabValue} index={0}>
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <TextField
                    name="company_name"
                    label="Company Name"
                    fullWidth
                    value={settings.company_name}
                    onChange={handleInputChange}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TextField
                    name="system_email"
                    label="System Email"
                    fullWidth
                    type="email"
                    value={settings.system_email}
                    onChange={handleInputChange}
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        name="email_notifications"
                        checked={settings.email_notifications}
                        onChange={handleInputChange}
                      />
                    }
                    label="Enable Email Notifications"
                  />
                </Grid>
              </Grid>
            </TabPanel>

            <TabPanel value={tabValue} index={1}>
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <TextField
                    name="auto_logout"
                    label="Auto Logout (minutes)"
                    fullWidth
                    type="number"
                    value={settings.auto_logout}
                    onChange={handleInputChange}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TextField
                    name="password_expiry"
                    label="Password Expiry (days)"
                    fullWidth
                    type="number"
                    value={settings.password_expiry}
                    onChange={handleInputChange}
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        name="require_two_factor"
                        checked={settings.require_two_factor}
                        onChange={handleInputChange}
                      />
                    }
                    label="Require Two-Factor Authentication"
                  />
                </Grid>
              </Grid>
            </TabPanel>

            <TabPanel value={tabValue} index={2}>
              <Grid container spacing={3}>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        name="backup_enabled"
                        checked={settings.backup_enabled}
                        onChange={handleInputChange}
                      />
                    }
                    label="Enable Automatic Backups"
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TextField
                    name="backup_frequency"
                    label="Backup Frequency"
                    fullWidth
                    value={settings.backup_frequency}
                    onChange={handleInputChange}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TextField
                    name="backup_location"
                    label="Backup Location"
                    fullWidth
                    value={settings.backup_location}
                    onChange={handleInputChange}
                  />
                </Grid>
              </Grid>
            </TabPanel>

            <Divider sx={{ mt: 3 }} />
            <Box sx={{ p: 2, display: 'flex', justifyContent: 'flex-end' }}>
              <Button
                variant="contained"
                color="primary"
                onClick={handleSave}
                disabled={saving || !user?.is_admin}
              >
                {saving ? <CircularProgress size={24} /> : 'Save Settings'}
              </Button>
            </Box>
          </Paper>
        </Grid>
      </Grid>

      <Snackbar
        open={success}
        autoHideDuration={6000}
        onClose={() => setSuccess(false)}
        message="Settings saved successfully"
      />
    </Container>
  );
};

export default Settings; 