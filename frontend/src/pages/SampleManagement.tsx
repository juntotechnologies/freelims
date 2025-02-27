import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  IconButton,
  Typography,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  SelectChangeEvent,
} from '@mui/material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import AddIcon from '@mui/icons-material/Add';

interface Sample {
  id: number;
  sampleId: string;
  productName: string;
  quantity: number;
  unit: string;
  batchNumber: string;
  lotNumber: string;
  manufacturer: string;
  entryDate: string;
  status: string;
  priority: string;
  assignedTo: string;
  comments: string;
}

type NewSample = Omit<Sample, 'id'>;

const unitOptions = [
  'mg',
  'g',
  'kg',
  'lb',
  'mL',
  'L',
  'oz',
  'unit',
];

const SampleManagement: React.FC = () => {
  const [samples, setSamples] = useState<Sample[]>([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [newSample, setNewSample] = useState<NewSample>({
    sampleId: '',
    productName: '',
    quantity: 0,
    unit: 'g',
    batchNumber: '',
    lotNumber: '',
    manufacturer: '',
    entryDate: new Date().toISOString(),
    status: 'Pending',
    priority: 'Normal',
    assignedTo: '',
    comments: '',
  });

  const columns: GridColDef[] = [
    { field: 'sampleId', headerName: 'Sample ID', width: 130 },
    { field: 'productName', headerName: 'Product Name', width: 200 },
    { 
      field: 'quantity', 
      headerName: 'Quantity', 
      width: 130,
      renderCell: (params) => `${params.row.quantity} ${params.row.unit}`,
    },
    { field: 'batchNumber', headerName: 'Batch #', width: 130 },
    { field: 'lotNumber', headerName: 'Lot #', width: 130 },
    { field: 'manufacturer', headerName: 'Manufacturer', width: 150 },
    { 
      field: 'entryDate', 
      headerName: 'Entry Date', 
      width: 150,
      valueFormatter: (params) => new Date(params.value).toLocaleDateString(),
    },
    { field: 'status', headerName: 'Status', width: 130 },
    { field: 'priority', headerName: 'Priority', width: 130 },
    { field: 'assignedTo', headerName: 'Assigned To', width: 150 },
    { field: 'comments', headerName: 'Comments', width: 200 },
  ];

  useEffect(() => {
    fetchSamples();
  }, []);

  const fetchSamples = async () => {
    setLoading(true);
    try {
      // Your fetch logic here
      setSamples([]); // Replace with actual API call
    } catch (error) {
      console.error('Failed to fetch samples:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDialog = () => {
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
  };

  const handleInputChange = (
    event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement> | SelectChangeEvent
  ) => {
    const { name, value } = event.target;
    
    if (name === 'quantity') {
      // Allow empty input or valid positive numbers (including decimals)
      if (value === '' || /^\d*\.?\d*$/.test(value)) {
        const numValue = value === '' ? 0 : parseFloat(value);
        setNewSample((prev) => ({
          ...prev,
          [name]: numValue,
        }));
      }
    } else {
      setNewSample((prev) => ({
        ...prev,
        [name]: value,
      }));
    }
  };

  const handleDateChange = (date: Date | null) => {
    if (date) {
      setNewSample((prev) => ({
        ...prev,
        entryDate: date.toISOString(),
      }));
    }
  };

  const handleSubmit = () => {
    const sample: Sample = {
      id: samples.length + 1,
      ...newSample,
    };
    setSamples((prev) => [...prev, sample]);
    handleCloseDialog();
    setNewSample({
      sampleId: '',
      productName: '',
      quantity: 0,
      unit: 'g',
      batchNumber: '',
      lotNumber: '',
      manufacturer: '',
      entryDate: new Date().toISOString(),
      status: 'Pending',
      priority: 'Normal',
      assignedTo: '',
      comments: '',
    });
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4">Sample Management</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
        >
          Add New Sample
        </Button>
      </Box>

      <DataGrid
        rows={samples}
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

      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>Register New Sample</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="sampleId"
                  label="Sample ID"
                  fullWidth
                  value={newSample.sampleId}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="productName"
                  label="Product Name"
                  fullWidth
                  value={newSample.productName}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <Grid container spacing={2}>
                  <Grid item xs={8}>
                    <TextField
                      name="quantity"
                      label="Quantity"
                      type="text"
                      fullWidth
                      value={newSample.quantity}
                      onChange={handleInputChange}
                      required
                      sx={{
                        '& input::-webkit-outer-spin-button, & input::-webkit-inner-spin-button': {
                          display: 'none',
                        },
                        '& input[type=number]': {
                          MozAppearance: 'textfield',
                        },
                      }}
                    />
                  </Grid>
                  <Grid item xs={4}>
                    <FormControl fullWidth>
                      <InputLabel>Unit</InputLabel>
                      <Select
                        name="unit"
                        value={newSample.unit}
                        label="Unit"
                        onChange={handleInputChange}
                      >
                        {unitOptions.map((unit) => (
                          <MenuItem key={unit} value={unit}>
                            {unit}
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>
                </Grid>
              </Grid>
              <Grid item xs={12} sm={6}>
                <LocalizationProvider dateAdapter={AdapterDateFns}>
                  <DatePicker
                    label="Entry Date"
                    value={new Date(newSample.entryDate)}
                    onChange={handleDateChange}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        required: true,
                      },
                    }}
                  />
                </LocalizationProvider>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="batchNumber"
                  label="Batch Number"
                  fullWidth
                  value={newSample.batchNumber}
                  onChange={handleInputChange}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="lotNumber"
                  label="Lot Number"
                  fullWidth
                  value={newSample.lotNumber}
                  onChange={handleInputChange}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="manufacturer"
                  label="Manufacturer"
                  fullWidth
                  value={newSample.manufacturer}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Priority</InputLabel>
                  <Select
                    name="priority"
                    value={newSample.priority}
                    label="Priority"
                    onChange={handleInputChange}
                  >
                    <MenuItem value="Low">Low</MenuItem>
                    <MenuItem value="Normal">Normal</MenuItem>
                    <MenuItem value="High">High</MenuItem>
                    <MenuItem value="Urgent">Urgent</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="assignedTo"
                  label="Assigned To"
                  fullWidth
                  value={newSample.assignedTo}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  name="comments"
                  label="Comments"
                  fullWidth
                  multiline
                  rows={3}
                  value={newSample.comments}
                  onChange={handleInputChange}
                  placeholder="Add any additional notes or comments about the sample"
                />
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button onClick={handleSubmit} variant="contained" color="primary">
            Register Sample
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default SampleManagement; 