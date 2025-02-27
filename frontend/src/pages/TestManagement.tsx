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
  Chip,
  OutlinedInput,
  Checkbox,
  ListItemText,
} from '@mui/material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';
import { Add as AddIcon } from '@mui/icons-material';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { LocalizationProvider, DatePicker } from '@mui/x-date-pickers';

interface Analyst {
  id: number;
  username: string;
  full_name: string;
}

interface Test {
  id: number;
  internal_id: string;
  testId: string;
  sampleId: string;
  testType: string;
  method: string;
  status: string;
  startDate: string;
  testDate: string;
  completionDate: string | null;
  analysts: Analyst[];
  results: string;
}

const TestManagement: React.FC = () => {
  const [tests, setTests] = useState<Test[]>([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [testDate, setTestDate] = useState<Date | null>(new Date());
  const [analysts, setAnalysts] = useState<Analyst[]>([]);
  const [selectedAnalystIds, setSelectedAnalystIds] = useState<number[]>([]);
  
  const TEST_TYPES = ["HPLC", "GC", "Titration", "IR", "NMR"];
  
  const [newTest, setNewTest] = useState({
    internal_id: '',
    testId: '',
    sampleId: '',
    testType: '',
    method: '',
    status: 'Pending',
    results: '',
  });

  const columns: GridColDef[] = [
    { field: 'internal_id', headerName: 'Internal ID', width: 130 },
    { field: 'testId', headerName: 'Test ID', width: 130 },
    { field: 'sampleId', headerName: 'Sample ID', width: 130 },
    { field: 'testType', headerName: 'Test Type', width: 150 },
    { field: 'method', headerName: 'Method', width: 150 },
    { field: 'status', headerName: 'Status', width: 130 },
    { field: 'startDate', headerName: 'Start Date', width: 180 },
    { field: 'testDate', headerName: 'Test Date', width: 180 },
    { field: 'completionDate', headerName: 'Completion Date', width: 180 },
    { 
      field: 'analysts', 
      headerName: 'Analysts', 
      width: 200,
      valueGetter: (params) => {
        const analysts = params.value as Analyst[];
        return analysts && Array.isArray(analysts) ? analysts.map(a => a.full_name).join(', ') : '';
      }
    },
    { field: 'results', headerName: 'Results', width: 200 },
  ];

  useEffect(() => {
    fetchTests();
    fetchAnalysts();
  }, []);

  const fetchTests = async () => {
    setLoading(true);
    try {
      // Fetch real test data from the API
      const response = await fetch('http://localhost:8000/api/tests');
      const data = await response.json();
      setTests(data);
    } catch (error) {
      console.error('Failed to fetch tests:', error);
      // Keep empty array if API fails
      setTests([]);
    } finally {
      setLoading(false);
    }
  };
  
  const fetchAnalysts = async () => {
    try {
      // Fetch real analyst data from the API
      const response = await fetch('http://localhost:8000/api/users');
      
      // Check if the response is ok before processing
      if (response.ok) {
        const data = await response.json();
        // Ensure data is an array before setting it
        if (Array.isArray(data)) {
          setAnalysts(data);
        } else {
          console.error('Analysts data is not an array:', data);
          // Fallback to default analysts if API response is not an array
          setAnalysts([
            { id: 2, username: 'Kemi', full_name: 'Olukemi OYEM' },
            { id: 3, username: 'Kartik.Patel', full_name: 'Kartik Patel' },
            { id: 4, username: 'ushma.srivastava', full_name: 'Ushma Srivastava' }
          ]);
        }
      } else {
        // Handle failed API response
        console.error('Failed to fetch analysts:', response.statusText);
        // Fallback to default analysts
        setAnalysts([
          { id: 2, username: 'Kemi', full_name: 'Olukemi OYEM' },
          { id: 3, username: 'Kartik.Patel', full_name: 'Kartik Patel' },
          { id: 4, username: 'ushma.srivastava', full_name: 'Ushma Srivastava' }
        ]);
      }
    } catch (error) {
      console.error('Failed to fetch analysts:', error);
      // Fallback to our known analysts if API fails
      setAnalysts([
        { id: 2, username: 'Kemi', full_name: 'Olukemi OYEM' },
        { id: 3, username: 'Kartik.Patel', full_name: 'Kartik Patel' },
        { id: 4, username: 'ushma.srivastava', full_name: 'Ushma Srivastava' }
      ]);
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
  
  const handleSelectChange = (event: React.ChangeEvent<{ name?: string; value: unknown }>) => {
    const name = event.target.name as string;
    const value = event.target.value;
    setNewTest((prev) => ({
      ...prev,
      [name]: value,
    }));
  };
  
  const handleAnalystsChange = (event: React.ChangeEvent<{ value: unknown }>) => {
    const value = event.target.value as number[];
    setSelectedAnalystIds(value);
  };

  const handleSubmit = async () => {
    try {
      // Ensure analysts is an array before filtering
      const analystArray = Array.isArray(analysts) ? analysts : [];
      const selectedAnalysts = analystArray.filter(analyst => selectedAnalystIds.includes(analyst.id));
      
      // Prepare the data to be sent to the API
      const testData = {
        internal_id: newTest.internal_id,
        test_id: newTest.testId,
        sample_id: newTest.sampleId,
        test_type: newTest.testType,
        method: newTest.method,
        status: newTest.status,
        results: newTest.results,
        start_date: new Date().toISOString(),
        test_date: testDate ? testDate.toISOString() : new Date().toISOString(),
        analyst_ids: selectedAnalystIds,
      };
      
      // Call the API to create a new test
      const response = await fetch('http://localhost:8000/api/tests', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testData),
      });
      
      if (!response.ok) {
        throw new Error('Failed to create test');
      }
      
      const createdTest = await response.json();
      
      // Add the new test to the local state with the format expected by the UI
      const test: Test = {
        id: createdTest.id,
        internal_id: createdTest.internal_id,
        testId: createdTest.test_id,
        sampleId: createdTest.sample_id,
        testType: createdTest.test_type,
        method: createdTest.method,
        status: createdTest.status,
        startDate: createdTest.start_date,
        testDate: createdTest.test_date,
        completionDate: createdTest.completion_date,
        analysts: selectedAnalysts,
        results: createdTest.results,
      };
      
      setTests((prev) => [...prev, test]);
      handleCloseDialog();
      resetForm();
    } catch (error) {
      console.error('Error creating test:', error);
      alert('Failed to create test. Please try again.');
    }
  };
  
  const resetForm = () => {
    setNewTest({
      internal_id: '',
      testId: '',
      sampleId: '',
      testType: '',
      method: '',
      status: 'Pending',
      results: '',
    });
    setTestDate(new Date());
    setSelectedAnalystIds([]);
  };

  // Ensure analysts is an array for rendering
  const analystsArray = Array.isArray(analysts) ? analysts : [];

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

      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>Register New Test</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="internal_id"
                  label="Internal ID"
                  fullWidth
                  value={newTest.internal_id}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
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
                <FormControl fullWidth>
                  <InputLabel>Test Type</InputLabel>
                  <Select
                    name="testType"
                    value={newTest.testType}
                    label="Test Type"
                    onChange={handleSelectChange as any}
                    required
                  >
                    {TEST_TYPES.map((type) => (
                      <MenuItem key={type} value={type}>
                        {type}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
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
                    onChange={handleSelectChange as any}
                  >
                    <MenuItem value="Pending">Pending</MenuItem>
                    <MenuItem value="In Progress">In Progress</MenuItem>
                    <MenuItem value="Completed">Completed</MenuItem>
                    <MenuItem value="Failed">Failed</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <LocalizationProvider dateAdapter={AdapterDateFns}>
                  <DatePicker
                    label="Test Date"
                    value={testDate}
                    onChange={(newValue) => setTestDate(newValue)}
                    format="yyyy-MM-dd"
                    slotProps={{ textField: { fullWidth: true } }}
                  />
                </LocalizationProvider>
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Analysts</InputLabel>
                  <Select
                    multiple
                    value={selectedAnalystIds}
                    onChange={handleAnalystsChange as any}
                    input={<OutlinedInput label="Analysts" />}
                    renderValue={(selected) => (
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {(selected as number[]).map((value) => {
                          const analyst = analystsArray.find(a => a.id === value);
                          return (
                            <Chip 
                              key={value} 
                              label={analyst ? analyst.full_name : value} 
                            />
                          );
                        })}
                      </Box>
                    )}
                  >
                    {analystsArray.map((analyst) => (
                      <MenuItem key={analyst.id} value={analyst.id}>
                        <Checkbox checked={selectedAnalystIds.indexOf(analyst.id) > -1} />
                        <ListItemText primary={analyst.full_name} />
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
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