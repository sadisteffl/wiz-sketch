from flask import Flask, request, jsonify
from PIL import Image
import base64
import io
import os
import random
from pymongo import MongoClient
from collections import defaultdict

app = Flask(__name__)

# --- Database Connection ---
client = MongoClient(os.environ.get("DB_URI"))
db = client.sketchydb

# --- Game Logic ---
# Expanded list of prompts focusing on Medium and Hard difficulties
PROMPTS = [
    # Medium
    "tree", "flower", "house", "car", "boat", "fish", "key", "star",
    "sun", "cloud", "bridge", "moon", "hat", "door", "cup",
    # Hard
    "bicycle", "computer", "guitar", "camera", "airplane", "spider",
    "octopus", "helicopter", "keyboard", "microscope", "satellite", "train"
]
LEADERBOARD_FILE = "wizexercise.txt"

def get_leaderboard():
    """Reads scores from the leaderboard file."""
    if not os.path.exists(LEADERBOARD_FILE):
        return []
    
    scores = defaultdict(int)
    with open(LEADERBOARD_FILE, "r") as f:
        for line in f:
            parts = line.strip().split(":")
            if len(parts) == 2:
                username, score = parts
                scores[username] = int(score)
    
    # Sort scores descending and take the top 10
    sorted_scores = sorted(scores.items(), key=lambda item: item[1], reverse=True)[:10]
    return [{"username": u, "score": s} for u, s in sorted_scores]

def update_leaderboard(username):
    """Adds one point for the given username."""
    scores = defaultdict(int)
    if os.path.exists(LEADERBOARD_FILE):
        with open(LEADERBOARD_FILE, "r") as f:
            for line in f:
                parts = line.strip().split(":")
                if len(parts) == 2:
                    user, score = parts
                    scores[user] = int(score)
    
    scores[username] += 1
    
    with open(LEADERBOARD_FILE, "w") as f:
        for user, score in scores.items():
            f.write(f"{user}:{score}\n")

def mock_ai_guesser(image_data):
    """
    Expanded Mock AI: Guesses from the prompt list based on drawing complexity.
    This makes the demo more fun and believable.
    """
    try:
        image = Image.open(io.BytesIO(base64.b64decode(image_data)))
        grayscale_image = image.convert('L')
        pixels = list(grayscale_image.getdata())
        ink_pixel_count = sum(1 for pixel in pixels if pixel < 250)
        
        # Guess based on the amount of "ink" used, focusing on more complex items
        if ink_pixel_count < 4000: return random.choice(["sun", "cloud", "star", "moon"])
        elif ink_pixel_count < 8000: return random.choice(["tree", "flower", "fish", "cup"])
        elif ink_pixel_count < 12000: return random.choice(["house", "car", "boat", "key", "door"])
        elif ink_pixel_count < 18000: return random.choice(["bridge", "hat", "guitar", "camera"])
        elif ink_pixel_count < 25000: return random.choice(["spider", "octopus", "bicycle", "train"])
        else: return random.choice(["computer", "airplane", "helicopter", "microscope", "satellite"])

    except Exception as e:
        print(f"Error in AI guesser: {e}")
        return "something mysterious ✨"

# --- API Routes ---
@app.route("/api/prompt", methods=["GET"])
def get_prompt():
    """Returns a random drawing prompt."""
    return jsonify({"prompt": random.choice(PROMPTS)})

@app.route("/api/leaderboard", methods=["GET"])
def leaderboard():
    """Returns the current leaderboard."""
    return jsonify({"scores": get_leaderboard()})

@app.route("/api/classify", methods=["POST"])
def classify():
    """Receives an image, username, and prompt, returns a guess and correctness."""
    try:
        data = request.json
        image_data = data.get("image")
        username = data.get("username")
        prompt = data.get("prompt")

        if not all([image_data, username, prompt]):
            return jsonify({"error": "Missing image, username, or prompt"}), 400

        prediction = mock_ai_guesser(image_data)
        # Check if the prediction is in the same category or is the exact prompt
        is_correct = (prediction == prompt)

        if is_correct:
            update_leaderboard(username)

        # Log the attempt to MongoDB
        db.predictions.insert_one({
            "username": username,
            "prompt": prompt,
            "prediction": prediction,
            "is_correct": is_correct
        })
        
        return jsonify({"prediction": prediction, "is_correct": is_correct})

    except Exception as e:
        print(f"Error in /api/classify: {e}")
        return jsonify({"error": "An internal error occurred"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)