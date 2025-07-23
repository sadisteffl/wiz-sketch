import os
import random
import base64
from io import BytesIO
from PIL import Image
from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient

app = Flask(__name__)
CORS(app) # Enable Cross-Origin Resource Sharing

try:
    with open('/mnt/secrets-store/MONGO_URI', 'r') as f:
        mongo_uri = f.read().strip()
except FileNotFoundError:
    # Fallback for local development if the secret file isn't present
    print("SECRET NOT FOUND: Using fallback MONGO_URI for local development.")
    mongo_uri = os.environ.get("MONGO_URI", "mongodb://localhost:27017/sketchydb")

client = MongoClient(mongo_uri)
db = client.sketchydb
leaderboard_collection = db.leaderboard

pictionary_words = [
    "apple", "airplane", "ant", "arrow", "angel", "arm", "axe",
    "baby", "ball", "balloon", "banana", "bed", "bee", "bell", "bench", "bicycle", "bird", "boat", "book", "bone", "bottle", "bowl", "box", "brain", "bread", "bridge", "broom", "brush", "bucket", "bus", "butterfly", "button",
    "cactus", "cake", "camera", "candle", "car", "carrot", "cat", "chain", "chair", "cheese", "cherry", "chicken", "chimney", "clock", "cloud", "clown", "coat", "comb", "computer", "cone", "cow", "crab", "crayon", "crown", "cup", "curtain",
    "diamond", "dog", "doll", "door", "dragon", "dress", "drum", "duck",
    "ear", "earth", "egg", "eggplant", "elephant", "envelope", "eye",
    "fan", "feather", "fence", "finger", "fire", "fish", "flag", "flower", "fly", "foot", "fork", "fountain", "frog",
    "ghost", "gift", "giraffe", "glasses", "globe", "glove", "goat", "grapes", "guitar", "gun",
    "hammer", "hand", "hat", "heart", "helicopter", "helmet", "horse", "hospital", "house",
    "ice cream", "igloo", "island",
    "jacket", "jar", "jeans", "jellyfish", "jet", "juice",
    "kangaroo", "key", "keyboard", "king", "kite", "knife",
    "ladder", "lamp", "leaf", "leg", "lemon", "light bulb", "lighthouse", "lightning", "lion", "lips", "lizard", "lock", "lollipop",
    "man", "map", "mask", "medal", "microphone", "microscope", "milk", "mirror", "money", "monkey", "moon", "motorcycle", "mountain", "mouse", "mouth", "mushroom",
    "nail", "necklace", "needle", "nest", "net", "nose", "notebook",
    "octopus", "orange", "oven", "owl",
    "paint", "pants", "paper", "parachute", "pear", "pen", "pencil", "penguin", "person", "piano", "picture", "pig", "pillow", "pineapple", "pizza", "planet", "plant", "plate", "pool", "potato", "pumpkin", "purse",
    "queen", "quilt",
    "rabbit", "rain", "rainbow", "ring", "river", "road", "robot", "rocket", "rocking chair", "roof", "ruler",
    "sad", "sailboat", "salt", "sandwich", "satellite", "saw", "saxophone", "scarecrow", "scissors", "scorpion", "screw", "sea", "shark", "sheep", "shield", "ship", "shirt", "shoes", "shovel", "skateboard", "skeleton", "skull", "skunk", "skyscraper", "smile", "snail", "snake", "snowflake", "soap", "sock", "spade", "spider", "spoon", "square", "stamp", "star", "starfish", "steak", "stereo", "stingray", "stomach", "stop sign", "strawberry", "sun", "sunglasses", "swan", "sword", "syringe",
    "table", "tail", "teapot", "telephone", "television", "tennis racket", "tent", "tie", "tiger", "time", "toast", "toilet", "tomato", "toothbrush", "tornado", "train", "tree", "triangle", "trophy", "truck", "trumpet", "t-shirt", "turtle",
    "umbrella", "unicorn",
    "vase", "violin", "volcano",
    "wagon", "watch", "watermelon", "whale", "wheel", "whistle", "window", "wine", "witch", "wolf", "woman", "worm",
    "yo-yo",
    "zebra", "zipper"
]

def mock_classifier(image):
    """Mock classifier that randomly guesses from the upgraded list of items."""
    return random.choice(pictionary_words)

# --- API Endpoints ---

@app.route('/api/classify', methods=['POST'])
def classify_drawing():
    """
    Receives drawing data, gets a mock classification, and updates the
    player's score in the MongoDB leaderboard.
    """
    data = request.get_json()
    if not data or 'imageData' not in data:
        return jsonify({'error': 'No image data provided in the request.'}), 400

    try:
        image_data = base64.b64decode(data['imageData'].split(',')[1])
        image = Image.open(BytesIO(image_data))
    except Exception as e:
        return jsonify({'error': f'Invalid or corrupt image data: {e}'}), 400

    guess = mock_classifier(image)
    

    player_name = data.get('player', 'Player1')
    score_to_add = 10

    try:

        leaderboard_collection.update_one(
            {'player': player_name},
            {'$inc': {'score': score_to_add}},
            upsert=True
        )
    except Exception as e:
        print(f"ERROR: Could not update leaderboard in MongoDB. {e}")
        return jsonify({'error': 'A database error occurred.'}), 500

    return jsonify({'guess': guess})

@app.route('/leaderboard', methods=['GET'])
def get_leaderboard():
    """
    Retrieves all scores from the MongoDB leaderboard, sorts them in
    descending order, and returns them as a JSON array.
    """
    scores = []
    try:
        for entry in leaderboard_collection.find().sort("score", -1):
            scores.append({
                'player': entry.get('player'),
                'score': entry.get('score')
            })
        return jsonify(scores)
    except Exception as e:
        print(f"ERROR: Could not retrieve leaderboard from MongoDB. {e}")
        return jsonify({'error': 'A database error occurred.'}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)