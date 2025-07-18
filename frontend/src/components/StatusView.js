import React, { useState, useEffect } from 'react';
import { getRequestStatus } from '../services/api';

function StatusView({ requestData }) {
  const [status, setStatus] = useState(requestData);
  const [isLoading, setIsLoading] = useState(true);
  
  useEffect(() => {
    const interval = setInterval(async () => {
      try {
        const response = await getRequestStatus(status.requestId);
        setStatus(response.data);
        
        if (response.data.status === 'ACTIVE' || response.data.status === 'FAILED') {
          clearInterval(interval);
          setIsLoading(false);
        }
      } catch (err) {
        console.error('Error checking status:', err);
      }
    }, 10000);
    
    return () => clearInterval(interval);
  }, [status.requestId]);

  return (
    <div className="status-view">
      <h2>Account Provisioning Status</h2>
      
      <div className="status-details">
        <p><strong>Request ID:</strong> {status.requestId}</p>
        <p><strong>Account ID:</strong> {status.accountId || 'Pending...'}</p>
        <p><strong>Status:</strong> 
          <span className={`status-badge ${status.status?.toLowerCase()}`}>
            {status.status}
          </span>
        </p>
        
        {status.failureReason && (
          <p><strong>Failure Reason:</strong> {status.failureReason}</p>
        )}
      </div>
      
      {isLoading && (
        <div className="loading-indicator">
          <p>Checking status...</p>
        </div>
      )}
    </div>
  );
}

export default StatusView;
