import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Typography,
  Paper,
  IconButton,
  MenuItem,
  Grid,
  Alert,
  Snackbar,
  Stack,
  Card,
  CardContent,
  Select,
  InputLabel,
  FormControl,
  CircularProgress,
  Container,
} from '@mui/material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import RemoveIcon from '@mui/icons-material/Remove';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { LocalizationProvider, DatePicker } from '@mui/x-date-pickers';
import api from '../services/api';
import axios from 'axios';

interface InventoryItem {
  id: number;
  chemical: {
    id: number;
    name: string;
    cas_number: string;
  };
  location: {
    id: number;
    name: string;
  };
  quantity: number;
  unit: string;
  batch_number: string;
  expiration_date: string;
}

interface Chemical {
  id: number;
  name: string;
  cas_number: string;
}

interface Location {
  id: number;
  name: string;
  description?: string;
}

interface NewChemical {
  name: string;
  cas_number: string;
}

interface NewLocation {
  name: string;
  description?: string;
}

const Inventory: React.FC = () => {
  const [items, setItems] = useState<InventoryItem[]>([]);
  const [chemicals, setChemicals] = useState<Chemical[]>([]);
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [openUsageDialog, setOpenUsageDialog] = useState(false);
  const [selectedItem, setSelectedItem] = useState<InventoryItem | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [apiError, setApiError] = useState<boolean>(false);

  const [newItem, setNewItem] = useState({
    chemical_id: '',
    location_id: '',
    quantity: '',
    unit: '',
    batch_number: '',
    expiration_date: null as Date | null,
  });

  const [usage, setUsage] = useState({
    quantity: '',
    reason: '',
  });

  const [openChemicalDialog, setOpenChemicalDialog] = useState(false);
  const [openLocationDialog, setOpenLocationDialog] = useState(false);
  const [newChemical, setNewChemical] = useState<NewChemical>({ name: '', cas_number: '' });
  const [newLocation, setNewLocation] = useState<NewLocation>({ name: '' });
  const [editingChemical, setEditingChemical] = useState<Chemical | null>(null);
  const [editingLocation, setEditingLocation] = useState<Location | null>(null);

  const columns: GridColDef[] = [
    { field: 'id', headerName: 'ID', width: 90 },
    { 
      field: 'chemical_name', 
      headerName: 'Chemical', 
      width: 200, 
      valueGetter: (params) => params.row.chemical.name,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          <span>{params.row.chemical.name}</span>
          <IconButton 
            size="small" 
            onClick={(e) => {
              e.stopPropagation();
              handleOpenChemicalDialog(params.row.chemical);
            }}
          >
            <EditIcon fontSize="small" />
          </IconButton>
        </Box>
      ),
    },
    { 
      field: 'cas_number', 
      headerName: 'CAS Number', 
      width: 130, 
      valueGetter: (params) => params.row.chemical.cas_number 
    },
    { 
      field: 'location_name', 
      headerName: 'Location', 
      width: 130, 
      valueGetter: (params) => params.row.location.name,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          <span>{params.row.location.name}</span>
          <IconButton 
            size="small" 
            onClick={(e) => {
              e.stopPropagation();
              handleOpenLocationDialog(params.row.location);
            }}
          >
            <EditIcon fontSize="small" />
          </IconButton>
        </Box>
      ),
    },
    { field: 'quantity', headerName: 'Quantity', width: 100 },
    { field: 'unit', headerName: 'Unit', width: 100 },
    { field: 'batch_number', headerName: 'Batch/Lot #', width: 130 },
    { field: 'expiration_date', headerName: 'Expiration Date', width: 200 },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 200,
      renderCell: (params) => (
        <Box>
          <IconButton onClick={() => handleEdit(params.row)}>
            <EditIcon />
          </IconButton>
          <IconButton onClick={() => handleOpenUsageDialog(params.row)}>
            <RemoveIcon />
          </IconButton>
        </Box>
      ),
    },
  ];

  // Add units preset array
  const unitOptions = [
    'g', 'kg', 'mg', 'µg',
    'mL', 'L', 'gal', 
    'lb', 'oz', 
    'mol', 'mmol',
    'each', 'box', 'bottle', 'vial', 'ampule',
    'pack', 'set'
  ];

  useEffect(() => {
    fetchInventory();
    fetchChemicals();
    fetchLocations();
  }, []);

  // Function to ensure we have an auth token
  const ensureAuthToken = async () => {
    const token = localStorage.getItem('token');
    if (!token) {
      try {
        console.log('No auth token found, attempting to login...');
        const apiUrl = process.env.REACT_APP_API_URL || '/api';
        console.log('Using API URL for login:', apiUrl);
        
        // Create a FormData object for the authentication request
        const formData = new FormData();
        formData.append('username', 'admin');
        formData.append('password', 'password');
        
        const response = await fetch(`${apiUrl}/token`, {
          method: 'POST',
          body: formData,
        });
        
        console.log('Auth response status:', response.status);
        
        if (response.ok) {
          const data = await response.json();
          console.log('Auth response data:', data);
          localStorage.setItem('token', data.access_token);
          console.log('Successfully obtained new auth token');
          return true;
        } else {
          const errorText = await response.text();
          console.error('Failed to obtain auth token:', response.statusText, errorText);
          return false;
        }
      } catch (error) {
        console.error('Error during authentication:', error);
        return false;
      }
    }
    console.log('Using existing auth token from localStorage');
    return true;
  };

  const fetchInventory = async () => {
    // Ensure we have an auth token before making the request
    const hasToken = await ensureAuthToken();
    if (!hasToken) {
      console.error('Authentication failed. Cannot fetch inventory.');
      setError('Authentication failed. Cannot fetch inventory.');
      return;
    }

    setLoading(true);
    try {
      console.log('Fetching inventory with auth token:', localStorage.getItem('token'));
      const apiUrl = process.env.REACT_APP_API_URL || '/api';
      console.log('Using API URL for inventory:', apiUrl + '/inventory/items');
      
      const response = await api.get<InventoryItem[]>('/inventory/items');
      console.log('Inventory response:', response);
      setItems(response.data);
      setLoading(false);
    } catch (err: any) {
      console.error('Error fetching inventory:', err);
      // If we have an axios error with a response, log the details
      if (err && err.response) {
        console.error('Response status:', err.response.status);
        console.error('Response data:', err.response.data);
      }
      setError('Failed to fetch inventory items');
      setLoading(false);
    }
  };

  const fetchChemicals = async () => {
    // Ensure we have an auth token before making the request
    const hasToken = await ensureAuthToken();
    if (!hasToken) {
      console.error('Authentication failed. Cannot fetch chemicals.');
      setError('Authentication failed. Cannot fetch chemicals.');
      return;
    }
    
    try {
      console.log('Fetching chemicals with auth token:', localStorage.getItem('token'));
      const apiUrl = process.env.REACT_APP_API_URL || '/api';
      console.log('Using API URL for chemicals:', apiUrl + '/chemicals/');
      
      const response = await api.get<Chemical[]>('/chemicals/');
      console.log('Chemicals response:', response);
      setChemicals(response.data);
    } catch (err: any) {
      console.error('Error fetching chemicals:', err);
      // If we have an axios error with a response, log the details
      if (err && err.response) {
        console.error('Response status:', err.response.status);
        console.error('Response data:', err.response.data);
      }
      setError('Failed to fetch chemicals');
    }
  };

  const fetchLocations = async () => {
    // Ensure we have an auth token before making the request
    const hasToken = await ensureAuthToken();
    if (!hasToken) {
      console.error('Authentication failed. Cannot fetch locations.');
      setError('Authentication failed. Cannot fetch locations.');
      return;
    }
    
    try {
      console.log('Fetching locations with auth token:', localStorage.getItem('token'));
      const apiUrl = process.env.REACT_APP_API_URL || '/api';
      console.log('Using API URL for locations:', apiUrl + '/locations/');
      
      const response = await api.get<Location[]>('/locations/');
      console.log('Locations response:', response);
      setLocations(response.data);
    } catch (err: any) {
      console.error('Error fetching locations:', err);
      // If we have an axios error with a response, log the details
      if (err && err.response) {
        console.error('Response status:', err.response.status);
        console.error('Response data:', err.response.data);
      }
      setError('Failed to fetch locations');
    }
  };

  const handleOpenDialog = () => {
    setNewItem({
      chemical_id: '',
      location_id: '',
      quantity: '',
      unit: '',
      batch_number: '',
      expiration_date: null,
    });
    setOpenDialog(true);
  };

  const handleEdit = (item: InventoryItem) => {
    setSelectedItem(item);
    setNewItem({
      chemical_id: item.chemical.id.toString(),
      location_id: item.location.id.toString(),
      quantity: item.quantity.toString(),
      unit: item.unit,
      batch_number: item.batch_number,
      expiration_date: item.expiration_date ? new Date(item.expiration_date) : null,
    });
    setOpenDialog(true);
  };

  const handleOpenUsageDialog = (item: InventoryItem) => {
    setSelectedItem(item);
    setUsage({
      quantity: '',
      reason: '',
    });
    setOpenUsageDialog(true);
  };

  const handleSubmit = async () => {
    try {
      if (selectedItem) {
        await api.put(`/inventory/items/${selectedItem.id}`, {
          chemical_id: parseInt(newItem.chemical_id),
          location_id: parseInt(newItem.location_id),
          quantity: parseFloat(newItem.quantity),
          unit: newItem.unit,
          batch_number: newItem.batch_number,
          expiration_date: newItem.expiration_date 
            ? newItem.expiration_date.toISOString().split('T')[0] 
            : null,
        });
        setSuccess('Inventory item updated successfully');
      } else {
        await api.post('/inventory/items', {
          chemical_id: parseInt(newItem.chemical_id),
          location_id: parseInt(newItem.location_id),
          quantity: parseFloat(newItem.quantity),
          unit: newItem.unit,
          batch_number: newItem.batch_number,
          expiration_date: newItem.expiration_date 
            ? newItem.expiration_date.toISOString().split('T')[0] 
            : null,
        });
        setSuccess('Inventory item added successfully');
      }
      setOpenDialog(false);
      fetchInventory();
    } catch (err) {
      setError('Failed to save inventory item');
    }
  };

  const handleRecordUsage = async () => {
    if (!selectedItem) return;

    try {
      await api.post('/inventory/changes', {
        inventory_item_id: selectedItem.id,
        change_amount: -parseFloat(usage.quantity),
        reason: usage.reason,
      });
      setSuccess('Usage recorded successfully');
      setOpenUsageDialog(false);
      fetchInventory();
    } catch (err) {
      setError('Failed to record usage');
    }
  };

  const handleOpenChemicalDialog = (chemical?: Chemical) => {
    setError(null);
    setSuccess(null);
    
    if (chemical) {
      setEditingChemical(chemical);
      setNewChemical({ name: chemical.name, cas_number: chemical.cas_number });
    } else {
      setEditingChemical(null);
      setNewChemical({ name: '', cas_number: '' });
    }
    setOpenChemicalDialog(true);
  };

  const handleCloseChemicalDialog = () => {
    setOpenChemicalDialog(false);
    setEditingChemical(null);
    setNewChemical({ name: '', cas_number: '' });
  };

  const handleOpenLocationDialog = (location?: Location) => {
    setError(null);
    setSuccess(null);
    
    if (location) {
      setEditingLocation(location);
      setNewLocation({
        name: location.name,
        description: location.description
      });
    } else {
      setEditingLocation(null);
      setNewLocation({ name: '', description: '' });
    }
    setOpenLocationDialog(true);
  };

  const handleCloseLocationDialog = () => {
    setOpenLocationDialog(false);
    setNewLocation({ name: '', description: '' });
    setEditingLocation(null);
  };

  const handleSubmitChemical = async () => {
    // Ensure we have an auth token before making the request
    const hasToken = await ensureAuthToken();
    if (!hasToken) {
      setError('Authentication failed. Cannot save chemical.');
      return;
    }

    try {
      console.log('Saving chemical with auth token:', localStorage.getItem('token'));
      const apiUrl = process.env.REACT_APP_API_URL || '/api';
      console.log('Using API URL for saving chemical:', apiUrl + '/chemicals/');
      
      if (editingChemical) {
        const response = await api.put(`/chemicals/${editingChemical.id}`, newChemical);
        console.log('Update chemical response:', response);
        setSuccess('Chemical updated successfully');
      } else {
        const response = await api.post('/chemicals/', newChemical);
        console.log('Add chemical response:', response);
        setSuccess('Chemical added successfully');
      }
      handleCloseChemicalDialog();
      fetchChemicals();
    } catch (err: any) {
      console.error('Error saving chemical:', err);
      
      // If we have an axios error with a response, log the details
      if (err && err.response) {
        console.error('Response status:', err.response.status);
        console.error('Response data:', err.response.data);
        
        if (err.response.status === 401) {
          setError('Authentication failed. Please refresh the page and try again.');
        } else {
          setError(`Failed to save chemical: ${err.response.data.detail || err.message}`);
        }
      } else {
        setError('Failed to save chemical. Server might be unavailable.');
      }
    }
  };

  const handleSubmitLocation = async () => {
    // Ensure we have an auth token before making the request
    const hasToken = await ensureAuthToken();
    if (!hasToken) {
      setError('Authentication failed. Cannot save location.');
      return;
    }

    try {
      console.log('Saving location with auth token:', localStorage.getItem('token'));
      const apiUrl = process.env.REACT_APP_API_URL || '/api';
      console.log('Using API URL for saving location:', apiUrl + '/locations/');
      
      if (editingLocation) {
        // Update existing location
        const response = await api.put(`/locations/${editingLocation.id}`, newLocation);
        console.log('Update location response:', response);
        setSuccess('Location updated successfully');
      } else {
        // Create new location
        const response = await api.post('/locations/', newLocation);
        console.log('Add location response:', response);
        setSuccess('Location created successfully');
      }
      
      setOpenLocationDialog(false);
      setNewLocation({ name: '', description: '' });
      setEditingLocation(null);
      fetchLocations();
    } catch (err: any) {
      console.error('Error saving location:', err);
      
      // If we have an axios error with a response, log the details
      if (err && err.response) {
        console.error('Response status:', err.response.status);
        console.error('Response data:', err.response.data);
        
        if (err.response.status === 401) {
          setError('Authentication failed. Please refresh the page and try again.');
        } else {
          setError(`Failed to save location: ${err.response.data.detail || err.message}`);
        }
      } else {
        setError('Failed to save location. Server might be unavailable.');
      }
    }
  };

  return (
    <Container maxWidth="xl">
      <Typography variant="h4" gutterBottom>
        Inventory Management
      </Typography>
      
      {error && (
        <Alert 
          severity="error" 
          sx={{ mb: 2 }}
          action={
            <Button 
              color="inherit" 
              size="small"
              onClick={() => {
                setError(null);
                fetchInventory();
                fetchChemicals();
                fetchLocations();
              }}
            >
              Retry
            </Button>
          }
        >
          {error}
        </Alert>
      )}
      
      {success && (
        <Alert 
          severity="success" 
          sx={{ mb: 2 }}
          onClose={() => setSuccess(null)}
        >
          {success}
        </Alert>
      )}
      
      <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
        <Button 
          variant="contained" 
          color="primary" 
          onClick={() => setOpenDialog(true)}
        >
          Add Inventory Item
        </Button>
        <Button 
          variant="outlined" 
          color="primary" 
          onClick={() => handleOpenChemicalDialog()}
        >
          Manage Chemicals
        </Button>
        <Button 
          variant="outlined" 
          color="primary" 
          onClick={() => handleOpenLocationDialog()}
        >
          Manage Locations
        </Button>
      </Stack>

      <Paper sx={{ width: '100%', mb: 2 }}>
        <Box sx={{ 
          width: '100%', 
          '& .MuiDataGrid-root': {
            minWidth: 1200, // Minimum width before scrolling
            '@media (max-width: 1200px)': {
              '.MuiDataGrid-main': {
                overflow: 'auto',
              },
            },
          },
        }}>
          <DataGrid
            rows={items}
            columns={columns}
            initialState={{
              pagination: {
                paginationModel: {
                  pageSize: 10,
                },
              },
            }}
            pageSizeOptions={[10]}
            autoHeight
            loading={loading}
          />
        </Box>
      </Paper>

      {/* Add/Edit Dialog */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="md" fullWidth>
        <DialogTitle>{selectedItem ? 'Edit Inventory Item' : 'Add New Inventory Item'}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={6}>
              <TextField
                select
                fullWidth
                label="Chemical"
                value={newItem.chemical_id}
                onChange={(e) => setNewItem({ ...newItem, chemical_id: e.target.value })}
              >
                {chemicals.map((chemical) => (
                  <MenuItem key={chemical.id} value={chemical.id}>
                    {chemical.name} ({chemical.cas_number})
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid item xs={6}>
              <TextField
                select
                fullWidth
                label="Location"
                value={newItem.location_id}
                onChange={(e) => setNewItem({ ...newItem, location_id: e.target.value })}
              >
                {locations.map((location) => (
                  <MenuItem key={location.id} value={location.id}>
                    {location.name}
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid item xs={6}>
              <TextField
                fullWidth
                label="Quantity"
                type="text"
                value={newItem.quantity}
                onChange={(e) => {
                  const value = e.target.value;
                  if (value === '' || /^\d*\.?\d*$/.test(value)) {
                    setNewItem({ ...newItem, quantity: value });
                  }
                }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel id="unit-select-label">Unit</InputLabel>
                <Select
                  labelId="unit-select-label"
                  id="unit-select"
                  value={newItem.unit}
                  label="Unit"
                  onChange={(e) => setNewItem({ ...newItem, unit: e.target.value })}
                >
                  {unitOptions.map((unit) => (
                    <MenuItem key={unit} value={unit}>
                      {unit}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={6}>
              <TextField
                fullWidth
                label="Batch/Lot Number"
                value={newItem.batch_number}
                onChange={(e) => setNewItem({ ...newItem, batch_number: e.target.value })}
              />
            </Grid>
            <Grid item xs={6}>
              <LocalizationProvider dateAdapter={AdapterDateFns}>
                <DatePicker
                  label="Expiration Date"
                  value={newItem.expiration_date}
                  onChange={(date) => setNewItem({ ...newItem, expiration_date: date })}
                  slotProps={{
                    textField: {
                      fullWidth: true
                    }
                  }}
                  format="yyyy-MM-dd"
                />
              </LocalizationProvider>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button onClick={handleSubmit} variant="contained">
            {selectedItem ? 'Update' : 'Add'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Record Usage Dialog */}
      <Dialog open={openUsageDialog} onClose={() => setOpenUsageDialog(false)}>
        <DialogTitle>Record Chemical Usage</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <Typography variant="body1">
                Current Quantity: {selectedItem?.quantity} {selectedItem?.unit}
              </Typography>
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Usage Quantity"
                type="number"
                value={usage.quantity}
                onChange={(e) => setUsage({ ...usage, quantity: e.target.value })}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Reason"
                multiline
                rows={3}
                value={usage.reason}
                onChange={(e) => setUsage({ ...usage, reason: e.target.value })}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenUsageDialog(false)}>Cancel</Button>
          <Button onClick={handleRecordUsage} variant="contained">
            Record Usage
          </Button>
        </DialogActions>
      </Dialog>

      {/* Chemical Dialog */}
      <Dialog open={openChemicalDialog} onClose={handleCloseChemicalDialog} maxWidth="md" fullWidth>
        <DialogTitle>{editingChemical ? 'Edit Chemical' : 'Add New Chemical'}</DialogTitle>
        <DialogContent>
          <Box sx={{ mb: 2, mt: 1 }}>
            {error && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            )}
            {success && (
              <Alert severity="success" sx={{ mb: 2 }}>
                {success}
              </Alert>
            )}
            
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Chemical Name"
                  value={newChemical.name}
                  onChange={(e) => setNewChemical({ ...newChemical, name: e.target.value })}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="CAS Number"
                  value={newChemical.cas_number}
                  onChange={(e) => setNewChemical({ ...newChemical, cas_number: e.target.value })}
                />
              </Grid>
              <Grid item xs={12}>
                <Button 
                  variant="contained" 
                  color="primary" 
                  onClick={handleSubmitChemical}
                  disabled={!newChemical.name}
                >
                  {editingChemical ? 'Update Chemical' : 'Add Chemical'}
                </Button>
                {editingChemical && (
                  <Button 
                    variant="outlined" 
                    color="secondary" 
                    onClick={() => {
                      setEditingChemical(null);
                      setNewChemical({ name: '', cas_number: '' });
                    }}
                    sx={{ ml: 1 }}
                  >
                    Cancel Edit
                  </Button>
                )}
              </Grid>
            </Grid>
          </Box>

          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>
            Existing Chemicals
          </Typography>
          <Paper sx={{ width: '100%', overflow: 'hidden' }}>
            <Box sx={{ height: 400, width: '100%' }}>
              <DataGrid
                rows={chemicals}
                columns={[
                  { field: 'id', headerName: 'ID', width: 70 },
                  { field: 'name', headerName: 'Name', width: 300, flex: 1 },
                  { field: 'cas_number', headerName: 'CAS Number', width: 200 },
                  {
                    field: 'actions',
                    headerName: 'Actions',
                    width: 120,
                    renderCell: (params) => (
                      <IconButton onClick={() => handleOpenChemicalDialog(params.row)}>
                        <EditIcon />
                      </IconButton>
                    ),
                  },
                ]}
                pageSizeOptions={[5, 10]}
                initialState={{
                  pagination: { paginationModel: { pageSize: 5 } },
                }}
              />
            </Box>
          </Paper>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseChemicalDialog}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Location Dialog */}
      <Dialog open={openLocationDialog} onClose={handleCloseLocationDialog} maxWidth="md" fullWidth>
        <DialogTitle>{editingLocation ? 'Edit Location' : 'Add New Location'}</DialogTitle>
        <DialogContent>
          <Box sx={{ mb: 2, mt: 1 }}>
            {error && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            )}
            {success && (
              <Alert severity="success" sx={{ mb: 2 }}>
                {success}
              </Alert>
            )}
            
            <Typography variant="h6" gutterBottom>
              {editingLocation ? 'Edit Location' : 'Add New Location'}
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Name"
                  value={newLocation.name}
                  onChange={(e) => setNewLocation({...newLocation, name: e.target.value})}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Description"
                  value={newLocation.description || ''}
                  onChange={(e) => setNewLocation({...newLocation, description: e.target.value})}
                />
              </Grid>
              <Grid item xs={12}>
                <Button 
                  variant="contained" 
                  color="primary" 
                  onClick={handleSubmitLocation}
                  disabled={!newLocation.name}
                >
                  {editingLocation ? 'Update Location' : 'Add Location'}
                </Button>
                {editingLocation && (
                  <Button 
                    variant="outlined" 
                    color="secondary" 
                    onClick={() => {
                      setEditingLocation(null);
                      setNewLocation({ name: '', description: '' });
                    }}
                    sx={{ ml: 1 }}
                  >
                    Cancel Edit
                  </Button>
                )}
              </Grid>
            </Grid>
          </Box>

          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>
            Existing Locations
          </Typography>
          <Paper sx={{ width: '100%', overflow: 'hidden' }}>
            <Box sx={{ height: 400, width: '100%' }}>
              <DataGrid
                rows={locations}
                columns={[
                  { field: 'id', headerName: 'ID', width: 70 },
                  { field: 'name', headerName: 'Name', width: 300, flex: 1 },
                  { field: 'description', headerName: 'Description', width: 300, flex: 1 },
                  {
                    field: 'actions',
                    headerName: 'Actions',
                    width: 120,
                    renderCell: (params) => (
                      <IconButton onClick={() => handleOpenLocationDialog(params.row)}>
                        <EditIcon />
                      </IconButton>
                    ),
                  },
                ]}
                pageSizeOptions={[5, 10]}
                initialState={{
                  pagination: { paginationModel: { pageSize: 5 } },
                }}
              />
            </Box>
          </Paper>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseLocationDialog}>Close</Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default Inventory; 