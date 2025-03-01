// Script to test login API exactly as the frontend would
const axios = require('axios');

async function testLoginWithFormData() {
  try {
    console.log('Testing login with FormData (original method)...');
    const formData = new FormData();
    formData.append('username', 'admin');
    formData.append('password', 'password');

    // This will fail in Node.js because FormData is browser-specific
    // But this is how the original code was trying to do it
    console.log('Note: This method will fail in Node.js but is shown for comparison');
    
    // Commented out because it will fail
    /*
    const response = await axios.post('http://localhost:8001/api/token', formData);
    console.log('Login successful!');
    console.log('Token:', response.data.access_token);
    */
  } catch (error) {
    console.error('Login failed (expected in Node.js):');
    console.error(error.message);
  }
}

async function testLoginWithURLSearchParams() {
  try {
    console.log('\nTesting login with URLSearchParams (fixed method)...');
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

async function testLoginWithWrongPassword() {
  try {
    console.log('\nTesting login with wrong password...');
    const params = new URLSearchParams();
    params.append('username', 'admin');
    params.append('password', 'wrongpassword');

    const response = await axios.post('http://localhost:8001/api/token', params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });

    console.log('Login successful (unexpected)!');
    console.log('Token:', response.data.access_token);
  } catch (error) {
    console.error('Login failed (expected):');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error(error.message);
    }
  }
}

async function testRegistrationWithExistingUser() {
  try {
    console.log('\nTesting registration with existing username...');
    const userData = {
      email: 'admin2@example.com',
      username: 'admin', // This username already exists
      full_name: 'Another Admin',
      password: 'password123'
    };

    const response = await axios.post('http://localhost:8001/api/register', userData);
    console.log('Registration successful (unexpected)!');
    console.log('User:', response.data);
  } catch (error) {
    console.error('Registration failed (expected):');
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
  await testLoginWithURLSearchParams();
  await testLoginWithWrongPassword();
  await testRegistrationWithExistingUser();
}

runTests(); 