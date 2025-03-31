import { useEffect, useState } from 'react';

function App() {
  const [message, setMessage] = useState('');

  useEffect(() => {
    const fetchMessage = async () => {
      try {
        const res = await fetch('http://backend-service:8000/');
        const data = await res.json();
        setMessage(data.message);
      } catch (err) {
        console.error(err);
      }
    };
    fetchMessage();
  }, []);

  return (
    <div>
      <h1>React + FastAPI + MySQL</h1>
      <p>Backend Message: {message}</p>
    </div>
  );
}

export default App;