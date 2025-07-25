import React, { useRef, useState, useEffect } from "react";
import axios from "axios";

// Helper styles object
const styles = {
  container: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    fontFamily: 'Arial, sans-serif',
    backgroundColor: '#f0f2f5',
    minHeight: '100vh',
    padding: '20px',
  },
  header: {
    color: '#333',
    marginBottom: '20px',
  },
  prompt: {
    color: '#555',
    marginBottom: '15px',
    fontSize: '1.5em',
    fontWeight: 'bold',
  },
  input: {
    padding: '10px',
    fontSize: '1em',
    border: '1px solid #ccc',
    borderRadius: '8px',
    marginBottom: '15px',
    width: '300px',
    textAlign: 'center',
  },
  canvas: {
    border: '2px solid #ddd',
    borderRadius: '8px',
    boxShadow: '0 4px 8px rgba(0,0,0,0.1)',
    cursor: 'crosshair',
  },
  buttonContainer: {
    marginTop: '15px',
    display: 'flex',
    gap: '10px',
  },
  button: {
    padding: '10px 20px',
    fontSize: '1em',
    border: 'none',
    borderRadius: '8px',
    cursor: 'pointer',
    color: 'white',
    fontWeight: 'bold',
    transition: 'background-color 0.3s ease',
  },
  clearButton: {
    backgroundColor: '#f44336', // Red
  },
  submitButton: {
    backgroundColor: '#4CAF50', // Green
  },
  prediction: {
    marginTop: '20px',
    fontSize: '1.2em',
    color: '#333',
    fontWeight: 'bold',
  }
};

const DrawingCanvas = () => {
  const canvasRef = useRef(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [prediction, setPrediction] = useState("");
  const [username, setUsername] = useState("");
  const [drawingPrompt, setDrawingPrompt] = useState("Loading...");

  useEffect(() => {
    const fetchPrompt = async () => {
      try {
        const response = await axios.get(`${process.env.REACT_APP_API_URL}/prompt`);
        setDrawingPrompt(response.data.prompt);
      } catch (error) {
        console.error("Error fetching drawing prompt:", error);
        setDrawingPrompt("Could not load prompt.");
      }
    };
    fetchPrompt();
  }, []);

  const startDrawing = ({ nativeEvent }) => {
    const { offsetX, offsetY } = nativeEvent;
    const ctx = canvasRef.current.getContext("2d");
    ctx.beginPath();
    ctx.moveTo(offsetX, offsetY);
    ctx.lineWidth = 3; // Make the drawing line thicker
    ctx.lineCap = "round"; // Make the line ends rounded
    setIsDrawing(true);
  };

  const draw = ({ nativeEvent }) => {
    if (!isDrawing) return;
    const { offsetX, offsetY } = nativeEvent;
    const ctx = canvasRef.current.getContext("2d");
    ctx.lineTo(offsetX, offsetY);
    ctx.stroke();
  };

  const stopDrawing = () => {
    setIsDrawing(false);
  };

  const clearCanvas = () => {
    const canvas = canvasRef.current;
    const ctx = canvas.getContext("2d");
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    setPrediction("");
  };

  const submitDrawing = async () => {
    if (!username) {
        alert("Please enter a username before submitting!");
        return;
    }
    const canvas = canvasRef.current;
    const dataUrl = canvas.toDataURL("image/png");
    const base64Image = dataUrl.split(",")[1];

    try {
      const response = await axios.post(`${process.env.REACT_APP_API_URL}/classify`, {
        image: base64Image,
        username
      });
      setPrediction(response.data.prediction);
    } catch (error) {
      console.error("Error sending drawing:", error);
    }
  };

  return (
    <div style={styles.container}>
      <h1 style={styles.header}>AI Pictionary</h1>
      <h2 style={styles.prompt}>Your prompt: {drawingPrompt}</h2>
      <input
        type="text"
        placeholder="Enter your username"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
        style={styles.input}
      />
      <canvas
        ref={canvasRef}
        width={500}
        height={500}
        onMouseDown={startDrawing}
        onMouseMove={draw}
        onMouseUp={stopDrawing}
        onMouseLeave={stopDrawing}
        style={styles.canvas}
      />
      <div style={styles.buttonContainer}>
        <button 
            style={{...styles.button, ...styles.clearButton}} 
            onClick={clearCanvas}
        >
            Clear
        </button>
        <button 
            style={{...styles.button, ...styles.submitButton}} 
            onClick={submitDrawing}
        >
            Submit
        </button>
      </div>
      {prediction && <p style={styles.prediction}>AI Guess: {prediction}</p>}
    </div>
  );
};

export default DrawingCanvas;