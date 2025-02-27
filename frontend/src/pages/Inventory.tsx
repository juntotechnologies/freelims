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
} from '@mui/material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import RemoveIcon from '@mui/icons-material/Remove';
import { DateTimePicker } from '@mui/x-date-pickers/DateTimePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
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

  const columns: GridColDef[] = [
    { field: 'id', headerName: 'ID', width: 90 },
    { field: 'chemical_name', headerName: 'Chemical', width: 200, valueGetter: (params) => params.row.chemical.name },
    { field: 'cas_number', headerName: 'CAS Number', width: 130, valueGetter: (params) => params.row.chemical.cas_number },
    { field: 'location_name', headerName: 'Location', width: 130, valueGetter: (params) => params.row.location.name },
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

  useEffect(() => {
    fetchInventory();
    fetchChemicals();
    fetchLocations();
  }, []);

  const fetchInventory = async () => {
    setLoading(true);
    try {
      const response = await axios.get<InventoryItem[]>('/api/inventory/items');
      setItems(response.data);
    } catch (err) {
      setError('Failed to fetch inventory items');
    } finally {
      setLoading(false);
    }
  };

  const fetchChemicals = async () => {
    try {
      const response = await axios.get<Chemical[]>('/api/chemicals');
      setChemicals(response.data);
    } catch (err) {
      setError('Failed to fetch chemicals');
    }
  };

  const fetchLocations = async () => {
    try {
      const response = await axios.get<Location[]>('/api/locations');
      setLocations(response.data);
    } catch (err) {
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
        await axios.put(`/api/inventory/items/${selectedItem.id}`, {
          chemical_id: parseInt(newItem.chemical_id),
          location_id: parseInt(newItem.location_id),
          quantity: parseFloat(newItem.quantity),
          unit: newItem.unit,
          batch_number: newItem.batch_number,
          expiration_date: newItem.expiration_date?.toISOString(),
        });
        setSuccess('Inventory item updated successfully');
      } else {
        await axios.post('/api/inventory/items', {
          chemical_id: parseInt(newItem.chemical_id),
          location_id: parseInt(newItem.location_id),
          quantity: parseFloat(newItem.quantity),
          unit: newItem.unit,
          batch_number: newItem.batch_number,
          expiration_date: newItem.expiration_date?.toISOString(),
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
      await axios.post('/api/inventory/changes', {
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

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4">Inventory Management</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
        >
          Add New Item
        </Button>
      </Box>

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
            <Grid item xs={6}>
              <TextField
                fullWidth
                label="Unit"
                value={newItem.unit}
                onChange={(e) => setNewItem({ ...newItem, unit: e.target.value })}
              />
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
                <DateTimePicker
                  label="Expiration Date"
                  value={newItem.expiration_date}
                  onChange={(date) => setNewItem({ ...newItem, expiration_date: date })}
                  slotProps={{
                    textField: {
                      fullWidth: true
                    }
                  }}
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

      <Snackbar
        open={!!error || !!success}
        autoHideDuration={6000}
        onClose={() => {
          setError(null);
          setSuccess(null);
        }}
      >
        <Alert
          severity={error ? 'error' : 'success'}
          onClose={() => {
            setError(null);
            setSuccess(null);
          }}
        >
          {error || success}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Inventory; 