import React from 'react';
import LiveEditor from './components/LiveEditor';
import './App.css';

function App() {
  // In a real application, these would come from authentication and routing
  const documentId = 'doc-123';
  const userId = 'user-456';

  return (
    <div className="app">
      <header className="app-header">
        <h1>Collaborative Document Editor</h1>
      </header>
      <main className="app-main">
        <LiveEditor documentId={documentId} userId={userId} />
      </main>
    </div>
  );
}

export default App;
