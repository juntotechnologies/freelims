import React, { useState, useEffect } from 'react';
import { 
  Box, 
  Typography, 
  Container, 
  Paper, 
  FormControl, 
  InputLabel, 
  Select, 
  MenuItem,
  TextField,
  Button,
  Grid,
  Card,
  CardContent,
  Divider,
  Chip,
  Stack,
  SelectChangeEvent
} from '@mui/material';
import { DateTimePicker } from '@mui/x-date-pickers/DateTimePicker';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { DataGrid, GridColDef } from '@mui/x-data-grid';
import axios from 'axios';
import { format } from 'date-fns';

// Define interfaces
interface LocationAudit {
  id: number;
  location_id: number;
  user_id: number;
  field_name: string;
  old_value: string;
  new_value: string;
  action: string;
  timestamp: string;
  user?: {
    username: string;
    full_name: string;
  };
  location?: {
    name: string;
  };
}

interface Location {
  id: number;
  name: string;
  description?: string;
}

const LocationAuditLogs: React.FC = () => {
  // State variables
  const [auditLogs, setAuditLogs] = useState<LocationAudit[]>([]);
  const [locations, setLocations] = useState<Location[]>([]);
  const [selectedLocationId, setSelectedLocationId] = useState<number | string>('');
  const [actionFilter, setActionFilter] = useState<string>('');
  const [startDate, setStartDate] = useState<Date | null>(null);
  const [endDate, setEndDate] = useState<Date | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  
  // Fetch locations on component mount
  useEffect(() => {
    fetchLocations();
  }, []);
  
  // Fetch audit logs when filters change
  useEffect(() => {
    fetchAuditLogs();
  }, [selectedLocationId, actionFilter, startDate, endDate]);
  
  // Fetch locations from API
  const fetchLocations = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get<Location[]>(`${process.env.REACT_APP_API_URL}/locations/`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setLocations(response.data);
    } catch (error) {
      console.error('Error fetching locations:', error);
      setError('Failed to fetch locations');
    }
  };
  
  // Fetch audit logs from API
  const fetchAuditLogs = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const token = localStorage.getItem('token');
      let url = `${process.env.REACT_APP_API_URL}/locations/audit-logs/`;
      
      // If a specific location is selected, use the location-specific endpoint
      if (selectedLocationId && selectedLocationId !== 'all') {
        url = `${process.env.REACT_APP_API_URL}/locations/${selectedLocationId}/audit-logs/`;
      }
      
      // Build query parameters
      const params: any = {};
      if (selectedLocationId && selectedLocationId !== 'all' && selectedLocationId !== '') {
        params.location_id = selectedLocationId;
      }
      if (actionFilter) {
        params.action = actionFilter;
      }
      if (startDate) {
        params.start_date = startDate.toISOString();
      }
      if (endDate) {
        params.end_date = endDate.toISOString();
      }
      
      const response = await axios.get<LocationAudit[]>(url, {
        headers: { Authorization: `Bearer ${token}` },
        params
      });
      
      setAuditLogs(response.data);
    } catch (error) {
      console.error('Error fetching audit logs:', error);
      setError('Failed to fetch audit logs');
    } finally {
      setLoading(false);
    }
  };
  
  // Handle location selection change
  const handleLocationChange = (event: SelectChangeEvent<number | string>) => {
    setSelectedLocationId(event.target.value);
  };
  
  // Handle action filter change
  const handleActionChange = (event: SelectChangeEvent) => {
    setActionFilter(event.target.value);
  };
  
  // Clear all filters
  const handleClearFilters = () => {
    setSelectedLocationId('');
    setActionFilter('');
    setStartDate(null);
    setEndDate(null);
  };
  
  // Format date for display
  const formatDate = (dateString: string): string => {
    try {
      return format(new Date(dateString), 'PPpp');
    } catch (error) {
      return 'Invalid date';
    }
  };
  
  // Define columns for the data grid
  const columns: GridColDef[] = [
    { field: 'id', headerName: 'ID', width: 70 },
    { 
      field: 'location', 
      headerName: 'Location', 
      width: 150,
      valueGetter: (params) => {
        const locationId = params.row.location_id;
        const location = locations.find(loc => loc.id === locationId);
        return location ? location.name : `Location ID: ${locationId}`;
      }
    },
    { field: 'field_name', headerName: 'Field', width: 120 },
    { field: 'old_value', headerName: 'Old Value', width: 200 },
    { field: 'new_value', headerName: 'New Value', width: 200 },
    { 
      field: 'action', 
      headerName: 'Action', 
      width: 120,
      renderCell: (params) => {
        const action = params.value as string;
        let color;
        
        switch (action) {
          case 'CREATE':
            color = 'success';
            break;
          case 'UPDATE':
            color = 'primary';
            break;
          case 'DELETE':
            color = 'error';
            break;
          default:
            color = 'default';
        }
        
        return <Chip label={action} color={color as any} size="small" />;
      }
    },
    { 
      field: 'timestamp', 
      headerName: 'Timestamp', 
      width: 200,
      valueGetter: (params) => formatDate(params.value as string)
    },
    { 
      field: 'user_id', 
      headerName: 'User', 
      width: 150,
      // This would ideally use user data from the API
      valueGetter: (params) => {
        // In a real implementation, you would fetch user details or include them in the API response
        return `User ID: ${params.value}`;
      }
    },
  ];
  
  return (
    <Container maxWidth="xl">
      <Box sx={{ my: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Location Audit Logs
        </Typography>
        
        <Paper sx={{ p: 3, mb: 4 }}>
          <Typography variant="h6" sx={{ mb: 2 }}>
            Filters
          </Typography>
          
          <Grid container spacing={3}>
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel id="location-select-label">Location</InputLabel>
                <Select
                  labelId="location-select-label"
                  id="location-select"
                  value={selectedLocationId}
                  label="Location"
                  onChange={handleLocationChange}
                >
                  <MenuItem value="">
                    <em>All Locations</em>
                  </MenuItem>
                  {locations.map((location) => (
                    <MenuItem key={location.id} value={location.id}>
                      {location.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel id="action-select-label">Action</InputLabel>
                <Select
                  labelId="action-select-label"
                  id="action-select"
                  value={actionFilter}
                  label="Action"
                  onChange={handleActionChange}
                >
                  <MenuItem value="">
                    <em>All Actions</em>
                  </MenuItem>
                  <MenuItem value="CREATE">Create</MenuItem>
                  <MenuItem value="UPDATE">Update</MenuItem>
                  <MenuItem value="DELETE">Delete</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            
            <LocalizationProvider dateAdapter={AdapterDateFns}>
              <Grid item xs={12} md={3}>
                <DateTimePicker
                  label="Start Date"
                  value={startDate}
                  onChange={(newValue) => setStartDate(newValue)}
                  slotProps={{ textField: { fullWidth: true } }}
                />
              </Grid>
              
              <Grid item xs={12} md={3}>
                <DateTimePicker
                  label="End Date"
                  value={endDate}
                  onChange={(newValue) => setEndDate(newValue)}
                  slotProps={{ textField: { fullWidth: true } }}
                />
              </Grid>
            </LocalizationProvider>
          </Grid>
          
          <Box sx={{ mt: 3, display: 'flex', justifyContent: 'flex-end' }}>
            <Button variant="outlined" onClick={handleClearFilters} sx={{ mr: 2 }}>
              Clear Filters
            </Button>
            <Button variant="contained" onClick={fetchAuditLogs}>
              Apply Filters
            </Button>
          </Box>
        </Paper>
        
        {error && (
          <Paper sx={{ p: 2, mb: 4, bgcolor: '#fff4f4' }}>
            <Typography color="error">{error}</Typography>
          </Paper>
        )}
        
        <Paper sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={auditLogs}
            columns={columns}
            loading={loading}
            initialState={{
              pagination: {
                paginationModel: { page: 0, pageSize: 25 },
              },
              sorting: {
                sortModel: [{ field: 'timestamp', sort: 'desc' }],
              },
            }}
            pageSizeOptions={[10, 25, 50, 100]}
            checkboxSelection={false}
            disableRowSelectionOnClick
          />
        </Paper>
      </Box>
    </Container>
  );
};

export default LocationAuditLogs; 