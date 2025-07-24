import React, { useState, useRef, useEffect } from 'react';
import CanvasDraw from 'react-canvas-draw';
import './App.css';

// --- Helper Components ---
const LoginScreen = ({ onLogin }) => {
  const [username, setUsername] = useState('');
  const handleLogin = () => {
    if (username.trim()) {
      onLogin(username.trim());
    }
  };
  return (
    <div className="login-container">
      <h1>Wiz Sketch AI</h1>
      <p>Enter your name to start playing!</p>
      <input
        type="text"
        placeholder="Your Name"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
        onKeyPress={(e) => e.key === 'Enter' && handleLogin()}
        className="username-input"
      />
      <button onClick={handleLogin} className="action-button">Start Drawing</button>
    </div>
  );
};

const Leaderboard = ({ scores }) => (
  <div className="leaderboard-container">
    <h3>Leaderboard</h3>
    <ol>
      {scores.length > 0 ? (
        scores.map((score, index) => (
          <li key={index}>
            <span>{score.username}</span>
            <span>{score.score}</span>
          </li>
        ))
      ) : (
        <p>No scores yet. Be the first!</p>
      )}
    </ol>
  </div>
);


// --- Main App Component ---
function App() {
  const [username, setUsername] = useState('');
  const [prompt, setPrompt] = useState('');
  const [prediction, setPrediction] = useState('');
  const [isCorrect, setIsCorrect] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [leaderboard, setLeaderboard] = useState([]);
  const canvasRef = useRef(null);

  // Fetch initial data (prompt and leaderboard)
  const fetchInitialData = () => {
    // Fetch a random prompt
    fetch('/api/prompt')
      .then(res => res.json())
      .then(data => setPrompt(data.prompt))
      .catch(err => console.error("Error fetching prompt:", err));
    
    // Fetch leaderboard scores
    fetch('/api/leaderboard')
      .then(res => res.json())
      .then(data => setLeaderboard(data.scores))
      .catch(err => console.error("Error fetching leaderboard:", err));
  };

  useEffect(() => {
    if (username) {
      fetchInitialData();
    }
  }, [username]);

  const handleGuess = () => {
    if (!canvasRef.current) return;
    setIsLoading(true);
    setPrediction('');
    setIsCorrect(null);

    const base64Image = canvasRef.current.getDataURL('png').split(',')[1];

    fetch('/api/classify', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ image: base64Image, username, prompt }),
    })
    .then(response => response.json())
    .then(data => {
      setPrediction(data.prediction);
      setIsCorrect(data.is_correct);
      setIsLoading(false);
      // If the guess was correct, refresh the leaderboard
      if (data.is_correct) {
        fetch('/api/leaderboard')
          .then(res => res.json())
          .then(data => setLeaderboard(data.scores));
      }
    })
    .catch(error => {
      console.error('Error:', error);
      setPrediction('Error: Could not get a prediction.');
      setIsLoading(false);
    });
  };

  const handleNextRound = () => {
    canvasRef.current.clear();
    setPrediction('');
    setIsCorrect(null);
    // Fetch a new prompt for the next round
    fetch('/api/prompt')
      .then(res => res.json())
      .then(data => setPrompt(data.prompt));
  };

  if (!username) {
    return <LoginScreen onLogin={setUsername} />;
  }

  return (
    <div className="App">
      <header className="App-header">
        <Leaderboard scores={leaderboard} />
        <div className="game-container">
          <h1>Wiz Sketch AI</h1>
          <p>Your turn, {username}! Please draw:</p>
          <h2 className="prompt-text">{prompt}</h2>
          
          <div className="canvas-container">
            <CanvasDraw
              ref={canvasRef}
              brushColor="#FFFFFF"
              backgroundColor="#282c34"
              lazyRadius={8}
              brushRadius={5}
              canvasWidth={400}
              canvasHeight={400}
              hideGrid={true}
            />
          </div>

          <div className="controls">
            {!prediction && (
              <>
                <button onClick={handleGuess} disabled={isLoading} className="action-button">
                  {isLoading ? 'Guessing...' : 'Guess'}
                </button>
                <button onClick={() => canvasRef.current.clear()} className="clear-button">
                  Clear
                </button>
              </>
            )}
          </div>

          {prediction && (
            <div className="prediction-container">
              <h2>AI Prediction: <span className="prediction-text">{prediction}</span></h2>
              {isCorrect === true && <p className="result-correct">Correct! 🎉</p>}
              {isCorrect === false && <p className="result-incorrect">Not quite, try again!</p>}
              <button onClick={handleNextRound} className="action-button">Next Round</button>
            </div>
          )}
        </div>
      </header>
    </div>
  );
}

export default App;