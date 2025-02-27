import axios from 'axios';

// Get the API URL from environment variable, or use a default
const apiUrl = process.env.REACT_APP_API_URL || '/api';

console.log('Using API URL:', apiUrl);

// Create an axios instance with the API URL
const api = axios.create({
  baseURL: apiUrl,
  headers: {
    'Content-Type': 'application/json',
  },
  // Add a longer timeout for slow connections
  timeout: 10000,
});

// Add request interceptor to include auth token from local storage
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
      console.log(`API Request to ${config.url} with auth token`);
    } else {
      console.log(`API Request to ${config.url} without auth token`);
    }
    return config;
  },
  (error) => {
    console.error('API Request Error:', error);
    return Promise.reject(error);
  }
);

// Add response interceptor to handle common errors
api.interceptors.response.use(
  (response) => {
    console.log(`API Response from ${response.config.url}:`, response.status);
    return response;
  },
  (error) => {
    if (error.response) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      console.error('API Error Response:', {
        url: error.config?.url,
        status: error.response.status,
        data: error.response.data,
      });
      
      // Handle 401 Unauthorized by clearing token and redirecting to login
      if (error.response.status === 401) {
        console.warn('Authentication failed, clearing token');
        localStorage.removeItem('token');
        // Redirect to login page if needed
        // window.location.href = '/login';
      }
    } else if (error.request) {
      // The request was made but no response was received
      console.error('API No Response:', {
        url: error.config?.url,
        request: error.request,
      });
    } else {
      // Something happened in setting up the request
      console.error('API Setup Error:', error.message);
    }
    
    return Promise.reject(error);
  }
);

// Test the API connection
export const testApiConnection = async () => {
  try {
    console.log('Testing API connection to', `${apiUrl}/health`);
    const response = await api.get('/health');
    console.log('API connection test result:', response.data);
    return { success: true, data: response.data };
  } catch (error) {
    console.error('API connection test failed:', error);
    return { success: false, error };
  }
};

// Call this on app initialization to check API health
testApiConnection();

export default api; 