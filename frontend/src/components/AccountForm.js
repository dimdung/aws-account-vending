import React, { useState } from 'react';
import { createAccount } from '../services/api';

function AccountForm({ onSuccess, onError }) {
  const [formData, setFormData] = useState({
    accountName: '',
    accountEmail: '',
    ouName: 'Sandbox',
    metadata: {}
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    
    try {
      const response = await createAccount(formData);
      onSuccess(response.data);
    } catch (err) {
      onError(err);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  return (
    <form onSubmit={handleSubmit} className="account-form">
      <div className="form-group">
        <label htmlFor="accountName">Account Name</label>
        <input
          type="text"
          id="accountName"
          name="accountName"
          value={formData.accountName}
          onChange={handleChange}
          required
          minLength="3"
          maxLength="64"
        />
      </div>
      
      <div className="form-group">
        <label htmlFor="accountEmail">Email Address</label>
        <input
          type="email"
          id="accountEmail"
          name="accountEmail"
          value={formData.accountEmail}
          onChange={handleChange}
          required
        />
      </div>
      
      <div className="form-group">
        <label htmlFor="ouName">Organizational Unit</label>
        <select
          id="ouName"
          name="ouName"
          value={formData.ouName}
          onChange={handleChange}
          required
        >
          <option value="Sandbox">Sandbox</option>
          <option value="Development">Development</option>
          <option value="Production">Production</option>
        </select>
      </div>
      
      <button type="submit" disabled={isSubmitting} className="submit-button">
        {isSubmitting ? 'Creating Account...' : 'Create Account'}
      </button>
    </form>
  );
}

export default AccountForm;
