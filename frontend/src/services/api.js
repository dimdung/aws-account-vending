import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://yourapi.execute-api.region.amazonaws.com/prod';

export const createAccount = async (data) => {
  try {
    const response = await axios.post(`${API_BASE_URL}/accounts`, data);
    return response;
  } catch (error) {
    console.error('Error creating account:', error);
    throw error;
  }
};

export const getRequestStatus = async (requestId) => {
  try {
    const response = await axios.get(`${API_BASE_URL}/accounts/${requestId}`);
    return response;
  } catch (error) {
    console.error('Error getting request status:', error);
    throw error;
  }
};
