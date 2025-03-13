/**
 * Creates a .env.local file for the frontend from the root .env file
 */
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

// Find paths
const rootDir = path.resolve(__dirname, '../..');
const rootEnvPath = path.join(rootDir, '.env');
const frontendEnvPath = path.join(__dirname, '..', '.env.local');

// Check if root .env exists
if (!fs.existsSync(rootEnvPath)) {
  console.error(`Root .env file not found at ${rootEnvPath}`);
  console.error('Please create a .env file in the root directory');
  process.exit(1);
}

// Read root .env file
const rootEnv = dotenv.parse(fs.readFileSync(rootEnvPath));

// Create frontend environment variables
const frontendEnv = {
  // API URL based on environment
  REACT_APP_API_URL: rootEnv.ENVIRONMENT === 'production' 
    ? `http://localhost:${rootEnv.PROD_BACKEND_PORT}/api`
    : `http://localhost:${rootEnv.DEV_BACKEND_PORT}/api`,
  
  // Port based on environment
  PORT: rootEnv.ENVIRONMENT === 'production'
    ? rootEnv.PROD_FRONTEND_PORT
    : rootEnv.DEV_FRONTEND_PORT,
  
  // Application settings
  REACT_APP_APP_NAME: 'FreeLIMS Inventory',
  REACT_APP_VERSION: '0.1.0',
  REACT_APP_COMPANY_NAME: rootEnv.COMPANY_NAME || 'Your Company',
  
  // Environment
  REACT_APP_ENVIRONMENT: rootEnv.ENVIRONMENT,
};

// Write frontend .env.local file
const frontendEnvContent = Object.entries(frontendEnv)
  .map(([key, value]) => `${key}=${value}`)
  .join('\n');

fs.writeFileSync(frontendEnvPath, frontendEnvContent);

console.log(`Created frontend environment file at ${frontendEnvPath}`);
console.log('Frontend environment variables:', frontendEnv); 