import React from 'react';
import { 
  Box, 
  Typography, 
  Paper, 
  Container,
  Grid,
  Card,
  CardContent,
  Button
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';

/**
 * Experiments page for managing laboratory experiments
 */
const Experiments: React.FC = () => {
  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 4 }}>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
          <Typography variant="h4" component="h1" gutterBottom>
            Experiments
          </Typography>
          <Button 
            variant="contained" 
            color="primary" 
            startIcon={<AddIcon />}
          >
            New Experiment
          </Button>
        </Box>
        
        <Paper sx={{ p: 3, mb: 4 }}>
          <Typography variant="body1" paragraph>
            This page is under development. Experiments management functionality will be available soon.
          </Typography>
          
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Planned Features
                  </Typography>
                  <Typography variant="body2" component="ul">
                    <li>Create and manage experiment protocols</li>
                    <li>Track experiment progress</li>
                    <li>Record experiment results</li>
                    <li>Link experiments to samples and inventory</li>
                    <li>Export experiment data for analysis</li>
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Coming Soon
                  </Typography>
                  <Typography variant="body2">
                    The experiments module is currently in development. Check back soon for updates or contact your system administrator for more information.
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Paper>
      </Box>
    </Container>
  );
};

export default Experiments; 