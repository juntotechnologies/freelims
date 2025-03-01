// Test script to mimic frontend requests to the backend API
const axios = require('axios');

const API_URL = 'http://localhost:8001/api';

// Function to test login
async function testLogin() {
  try {
    console.log('Testing login with URLSearchParams (correct way)...');
    
    // Create URLSearchParams object (this is what the frontend is supposed to do)
    const params = new URLSearchParams();
    params.append('username', 'test_user2');
    params.append('password', 'test123');
    
    // Send the request with proper content type
    const response = await axios.post(`${API_URL}/token`, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });
    
    console.log('Login successful!');
    console.log('Token:', response.data.access_token);
    return response.data;
  } catch (error) {
    console.error('Login error:', error.response?.data || error.message);
    return null;
  }
}

// Function to test login with wrong format (JSON instead of form-urlencoded)
async function testLoginWithJsonFormat() {
  try {
    console.log('\nTesting login with JSON format (wrong way)...');
    
    // Send JSON data instead of form-urlencoded
    const response = await axios.post(`${API_URL}/token`, {
      username: 'test_user2',
      password: 'test123'
    });
    
    console.log('Login successful!');
    console.log('Token:', response.data.access_token);
    return response.data;
  } catch (error) {
    console.error('Login error:', error.response?.status, error.response?.data || error.message);
    return null;
  }
}

// Function to test login with FormData (another incorrect way)
async function testLoginWithFormData() {
  try {
    console.log('\nTesting login with FormData (potentially problematic)...');
    
    // Create FormData object
    const formData = new FormData();
    formData.append('username', 'test_user2');
    formData.append('password', 'test123');
    
    // Send the request
    const response = await axios.post(`${API_URL}/token`, formData);
    
    console.log('Login successful!');
    console.log('Token:', response.data.access_token);
    return response.data;
  } catch (error) {
    console.error('Login error:', error.response?.status, error.response?.data || error.message);
    return null;
  }
}

// Function to test registration
async function testRegistration() {
  try {
    console.log('\nTesting registration...');
    
    // Registration data
    const userData = {
      email: `test_${Date.now()}@example.com`, // Using timestamp to create unique email
      username: `test_user_${Date.now()}`, // Using timestamp to create unique username
      full_name: 'Test User',
      password: 'test123'
    };
    
    // Send registration request
    const response = await axios.post(`${API_URL}/register`, userData);
    
    console.log('Registration successful!');
    console.log('User:', response.data);
    return response.data;
  } catch (error) {
    console.error('Registration error:', error.response?.status, error.response?.data || error.message);
    return null;
  }
}

// Main function to run all tests
async function runTests() {
  // Test correct login
  await testLogin();
  
  // Test incorrect format login
  await testLoginWithJsonFormat();
  
  // Test with FormData
  try {
    await testLoginWithFormData();
  } catch (error) {
    console.error('FormData test error:', error.message);
  }
  
  // Test registration
  await testRegistration();
}

// Run the tests
runTests().catch(err => console.error('Test error:', err)); 