import React from 'react';
import { useRoutes } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import theme from './theme';
import routes from './routes';

// Routes component that uses the routes configuration
const AppRoutes: React.FC = () => {
  const routing = useRoutes(routes);
  return routing;
};

const App: React.FC = () => {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AppRoutes />
    </ThemeProvider>
  );
};

export default App; 