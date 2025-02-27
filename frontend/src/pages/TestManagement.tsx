import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Container,
  Grid,
  Typography,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Paper,
} from '@mui/material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';
import { Add as AddIcon } from '@mui/icons-material';

interface Test {
  id: number;
  testId: string;
  sampleId: string;
  testType: string;
  method: string;
  status: string;
  startDate: string;
  completionDate: string | null;
  analyst: string;
  results: string;
}

const TestManagement: React.FC = () => {
  const [tests, setTests] = useState<Test[]>([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [newTest, setNewTest] = useState({
    testId: '',
    sampleId: '',
    testType: '',
    method: '',
    status: 'Pending',
    analyst: '',
    results: '',
  });

  const columns: GridColDef[] = [
    { field: 'testId', headerName: 'Test ID', width: 130 },
    { field: 'sampleId', headerName: 'Sample ID', width: 130 },
    { field: 'testType', headerName: 'Test Type', width: 150 },
    { field: 'method', headerName: 'Method', width: 150 },
    { field: 'status', headerName: 'Status', width: 130 },
    { field: 'startDate', headerName: 'Start Date', width: 180 },
    { field: 'completionDate', headerName: 'Completion Date', width: 180 },
    { field: 'analyst', headerName: 'Analyst', width: 150 },
    { field: 'results', headerName: 'Results', width: 200 },
  ];

  useEffect(() => {
    fetchTests();
  }, []);

  const fetchTests = async () => {
    setLoading(true);
    try {
      // Your fetch logic here
      setTests([]); // Replace with actual API call
    } catch (error) {
      console.error('Failed to fetch tests:', error);
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

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = event.target;
    setNewTest((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = () => {
    const test: Test = {
      id: tests.length + 1,
      ...newTest,
      startDate: new Date().toISOString(),
      completionDate: null,
    };
    setTests((prev) => [...prev, test]);
    handleCloseDialog();
    setNewTest({
      testId: '',
      sampleId: '',
      testType: '',
      method: '',
      status: 'Pending',
      analyst: '',
      results: '',
    });
  };

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
            <Typography variant="h4" component="h1">
              Test Management
            </Typography>
            <Button
              variant="contained"
              color="primary"
              startIcon={<AddIcon />}
              onClick={handleOpenDialog}
            >
              New Test
            </Button>
          </Box>
        </Grid>

        <Grid item xs={12}>
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
                rows={tests}
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
        </Grid>
      </Grid>

      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>Register New Test</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="testId"
                  label="Test ID"
                  fullWidth
                  value={newTest.testId}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="sampleId"
                  label="Sample ID"
                  fullWidth
                  value={newTest.sampleId}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="testType"
                  label="Test Type"
                  fullWidth
                  value={newTest.testType}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="method"
                  label="Method"
                  fullWidth
                  value={newTest.method}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Status</InputLabel>
                  <Select
                    name="status"
                    value={newTest.status}
                    label="Status"
                    onChange={(e) => handleInputChange(e as any)}
                  >
                    <MenuItem value="Pending">Pending</MenuItem>
                    <MenuItem value="In Progress">In Progress</MenuItem>
                    <MenuItem value="Completed">Completed</MenuItem>
                    <MenuItem value="Failed">Failed</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="analyst"
                  label="Analyst"
                  fullWidth
                  value={newTest.analyst}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  name="results"
                  label="Results"
                  fullWidth
                  multiline
                  rows={3}
                  value={newTest.results}
                  onChange={handleInputChange}
                />
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button onClick={handleSubmit} variant="contained" color="primary">
            Register Test
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default TestManagement; 