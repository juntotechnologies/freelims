import React, { useState } from 'react';
import { TextField, Button } from '@mui/material';

interface RegisterFormData {
  email: string;     // Changed from username
  full_name: string;
  password: string;
  confirm_password: string;
}

const RegisterForm: React.FC = () => {
  const [formData, setFormData] = useState<RegisterFormData>({
    email: '',       // Changed from username
    full_name: '',
    password: '',
    confirm_password: ''
  });

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = event.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault();
    // Handle form submission
  };

  return (
    <form onSubmit={handleSubmit}>
      <TextField
        label="Email"
        type="email"
        name="email"  // Changed from username
        value={formData.email}  // Changed from username
        onChange={handleChange}
        required
        fullWidth
        margin="normal"
      />
      <TextField
        label="Full Name"
        type="text"
        name="full_name"
        value={formData.full_name}
        onChange={handleChange}
        required
        fullWidth
        margin="normal"
      />
      <TextField
        label="Password"
        type="password"
        name="password"
        value={formData.password}
        onChange={handleChange}
        required
        fullWidth
        margin="normal"
      />
      <TextField
        label="Confirm Password"
        type="password"
        name="confirm_password"
        value={formData.confirm_password}
        onChange={handleChange}
        required
        fullWidth
        margin="normal"
      />
      <Button 
        type="submit" 
        variant="contained" 
        color="primary" 
        fullWidth
      >
        Register
      </Button>
    </form>
  );
};

export default RegisterForm; 