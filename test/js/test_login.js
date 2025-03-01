// Simple script to test the login API
const axios = require('axios');

async function testLogin() {
  try {
    console.log('Testing login with admin user...');
    const params = new URLSearchParams();
    params.append('username', 'admin');
    params.append('password', 'password');

    const response = await axios.post('http://localhost:8001/api/token', params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });

    console.log('Login successful!');
    console.log('Token:', response.data.access_token);
    
    // Test getting user info
    const userResponse = await axios.get('http://localhost:8001/api/users/me', {
      headers: {
        'Authorization': `Bearer ${response.data.access_token}`
      }
    });
    
    console.log('User info:', userResponse.data);
  } catch (error) {
    console.error('Login failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error(error.message);
    }
  }
}

// Test registration
async function testRegistration() {
  try {
    console.log('Testing registration with new user...');
    const userData = {
      email: 'test@example.com',
      username: 'testuser',
      full_name: 'Test User',
      password: 'password123'
    };

    const response = await axios.post('http://localhost:8001/api/register', userData);
    console.log('Registration successful!');
    console.log('User:', response.data);
  } catch (error) {
    console.error('Registration failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error(error.message);
    }
  }
}

// Run the tests
async function runTests() {
  await testLogin();
  console.log('\n-------------------\n');
  await testRegistration();
}

runTests(); 