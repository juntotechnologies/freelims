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
 * Tests page for managing laboratory tests
 */
const Tests: React.FC = () => {
  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 4 }}>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
          <Typography variant="h4" component="h1" gutterBottom>
            Tests
          </Typography>
          <Button 
            variant="contained" 
            color="primary" 
            startIcon={<AddIcon />}
          >
            New Test
          </Button>
        </Box>
        
        <Paper sx={{ p: 3, mb: 4 }}>
          <Typography variant="body1" paragraph>
            This page is under development. Test management functionality will be available soon.
          </Typography>
          
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Planned Features
                  </Typography>
                  <Typography variant="body2" component="ul">
                    <li>Create and manage test protocols</li>
                    <li>Schedule tests and assign personnel</li>
                    <li>Record test results and observations</li>
                    <li>Generate test reports</li>
                    <li>Track test sample history</li>
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
                    The tests module is currently in development. Check back soon for updates or contact your system administrator for more information.
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

export default Tests; 