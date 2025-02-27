import React, { useState } from 'react';
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
  Tabs,
  Tab,
} from '@mui/material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';
import { Add as AddIcon } from '@mui/icons-material';

interface QCCheck {
  id: number;
  checkId: string;
  type: string;
  equipment: string;
  parameter: string;
  specification: string;
  result: string;
  status: string;
  performedBy: string;
  date: string;
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`qc-tabpanel-${index}`}
      aria-labelledby={`qc-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

const QualityControl: React.FC = () => {
  const [tabValue, setTabValue] = useState(0);
  const [qcChecks, setQCChecks] = useState<QCCheck[]>([]);
  const [openDialog, setOpenDialog] = useState(false);
  const [newQCCheck, setNewQCCheck] = useState({
    checkId: '',
    type: '',
    equipment: '',
    parameter: '',
    specification: '',
    result: '',
    status: 'Pending',
    performedBy: '',
  });

  const columns: GridColDef[] = [
    { field: 'checkId', headerName: 'Check ID', width: 130 },
    { field: 'type', headerName: 'Type', width: 150 },
    { field: 'equipment', headerName: 'Equipment', width: 150 },
    { field: 'parameter', headerName: 'Parameter', width: 150 },
    { field: 'specification', headerName: 'Specification', width: 150 },
    { field: 'result', headerName: 'Result', width: 150 },
    { field: 'status', headerName: 'Status', width: 130 },
    { field: 'performedBy', headerName: 'Performed By', width: 150 },
    { field: 'date', headerName: 'Date', width: 180 },
  ];

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleOpenDialog = () => {
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
  };

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = event.target;
    setNewQCCheck((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = () => {
    const qcCheck: QCCheck = {
      id: qcChecks.length + 1,
      ...newQCCheck,
      date: new Date().toISOString(),
    };
    setQCChecks((prev) => [...prev, qcCheck]);
    handleCloseDialog();
    setNewQCCheck({
      checkId: '',
      type: '',
      equipment: '',
      parameter: '',
      specification: '',
      result: '',
      status: 'Pending',
      performedBy: '',
    });
  };

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
            <Typography variant="h4" component="h1">
              Quality Control
            </Typography>
            <Button
              variant="contained"
              color="primary"
              startIcon={<AddIcon />}
              onClick={handleOpenDialog}
            >
              New QC Check
            </Button>
          </Box>
        </Grid>

        <Grid item xs={12}>
          <Paper sx={{ width: '100%' }}>
            <Tabs
              value={tabValue}
              onChange={handleTabChange}
              indicatorColor="primary"
              textColor="primary"
              centered
            >
              <Tab label="Equipment QC" />
              <Tab label="Method QC" />
              <Tab label="Standards" />
            </Tabs>

            <TabPanel value={tabValue} index={0}>
              <DataGrid
                rows={qcChecks.filter(check => check.type === 'Equipment')}
                columns={columns}
                autoHeight
                pageSizeOptions={[5, 10, 25]}
                initialState={{
                  pagination: {
                    paginationModel: { pageSize: 10, page: 0 },
                  },
                }}
                disableRowSelectionOnClick
              />
            </TabPanel>

            <TabPanel value={tabValue} index={1}>
              <DataGrid
                rows={qcChecks.filter(check => check.type === 'Method')}
                columns={columns}
                autoHeight
                pageSizeOptions={[5, 10, 25]}
                initialState={{
                  pagination: {
                    paginationModel: { pageSize: 10, page: 0 },
                  },
                }}
                disableRowSelectionOnClick
              />
            </TabPanel>

            <TabPanel value={tabValue} index={2}>
              <DataGrid
                rows={qcChecks.filter(check => check.type === 'Standard')}
                columns={columns}
                autoHeight
                pageSizeOptions={[5, 10, 25]}
                initialState={{
                  pagination: {
                    paginationModel: { pageSize: 10, page: 0 },
                  },
                }}
                disableRowSelectionOnClick
              />
            </TabPanel>
          </Paper>
        </Grid>
      </Grid>

      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>New Quality Control Check</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="checkId"
                  label="Check ID"
                  fullWidth
                  value={newQCCheck.checkId}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Type</InputLabel>
                  <Select
                    name="type"
                    value={newQCCheck.type}
                    label="Type"
                    onChange={(e) => handleInputChange(e as any)}
                  >
                    <MenuItem value="Equipment">Equipment</MenuItem>
                    <MenuItem value="Method">Method</MenuItem>
                    <MenuItem value="Standard">Standard</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="equipment"
                  label="Equipment"
                  fullWidth
                  value={newQCCheck.equipment}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="parameter"
                  label="Parameter"
                  fullWidth
                  value={newQCCheck.parameter}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  name="specification"
                  label="Specification"
                  fullWidth
                  value={newQCCheck.specification}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  name="result"
                  label="Result"
                  fullWidth
                  multiline
                  rows={2}
                  value={newQCCheck.result}
                  onChange={handleInputChange}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Status</InputLabel>
                  <Select
                    name="status"
                    value={newQCCheck.status}
                    label="Status"
                    onChange={(e) => handleInputChange(e as any)}
                  >
                    <MenuItem value="Pending">Pending</MenuItem>
                    <MenuItem value="Pass">Pass</MenuItem>
                    <MenuItem value="Fail">Fail</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  name="performedBy"
                  label="Performed By"
                  fullWidth
                  value={newQCCheck.performedBy}
                  onChange={handleInputChange}
                  required
                />
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button onClick={handleSubmit} variant="contained" color="primary">
            Save QC Check
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default QualityControl; 