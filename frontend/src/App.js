import React, { useState } from 'react';
import AccountForm from './components/AccountForm';
import StatusView from './components/StatusView';
import './App.css';

function App() {
  const [requestData, setRequestData] = useState(null);
  const [error, setError] = useState(null);

  const handleSuccess = (data) => {
    setRequestData(data);
    setError(null);
  };

  const handleError = (err) => {
    setError(err);
  };

  return (
    <div className="app-container">
      <header className="app-header">
        <h1>AWS Account Provisioning</h1>
      </header>
      
      <main className="app-content">
        {!requestData ? (
          <AccountForm onSuccess={handleSuccess} onError={handleError} />
        ) : (
          <StatusView requestData={requestData} />
        )}
        
        {error && (
          <div className="error-message">
            <h3>Error</h3>
            <p>{error.message || JSON.stringify(error)}</p>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
