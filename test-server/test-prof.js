#!/usr/bin/env node

// Simple test script to check prof service endpoints
import fetch, { FormData } from 'node-fetch';

const BASE_URL = 'http://localhost:5123';

// Test the health endpoint
console.log('Testing prof health endpoint...');
try {
  const response = await fetch(`${BASE_URL}/health`);
  const result = await response.text();
  console.log('Health response:', result);
} catch (error) {
  console.error('Health check failed:', error.message);
}

// Test creating a simple profile with minimal auth
console.log('\nTesting profile creation...');
try {
  const testUUID = 'test-uuid-12345';
  const timestamp = Date.now();
  const signature = 'test-signature';
  
  const profileData = {
    name: 'Test Author',
    email: 'test@example.com',
    bio: 'Test bio'
  };
  
  // Prof expects multipart form data with profileData as a JSON string
  const formData = new FormData();
  formData.append('profileData', JSON.stringify(profileData));
  
  const response = await fetch(`${BASE_URL}/user/${testUUID}/profile?uuid=${testUUID}&timestamp=${timestamp}&signature=${signature}`, {
    method: 'POST',
    body: formData
  });
  
  const result = await response.text();
  console.log('Profile creation response status:', response.status);
  console.log('Profile creation response:', result);
} catch (error) {
  console.error('Profile creation failed:', error.message);
}