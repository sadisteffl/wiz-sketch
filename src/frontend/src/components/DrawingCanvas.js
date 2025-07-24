import React, { useRef, useState } from "react";
import axios from "axios";

const DrawingCanvas = () => {
  const canvasRef = useRef(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [prediction, setPrediction] = useState("");
  const [username, setUsername] = useState("");

  const startDrawing = ({ nativeEvent }) => {
    const { offsetX, offsetY } = nativeEvent;
    const ctx = canvasRef.current.getContext("2d");
    ctx.beginPath();
    ctx.moveTo(offsetX, offsetY);
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
    <div>
      <input
        type="text"
        placeholder="Enter your username"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
      />
      <canvas
        ref={canvasRef}
        width={400}
        height={400}
        onMouseDown={startDrawing}
        onMouseMove={draw}
        onMouseUp={stopDrawing}
        onMouseLeave={stopDrawing}
        style={{ border: "1px solid black" }}
      />
      <div>
        <button onClick={clearCanvas}>Clear</button>
        <button onClick={submitDrawing}>Submit</button>
      </div>
      {prediction && <p>AI Guess: {prediction}</p>}
    </div>
  );
};

export default DrawingCanvas;
