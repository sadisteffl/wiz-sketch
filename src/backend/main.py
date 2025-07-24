from flask import Flask, request, jsonify
import torch
from torchvision import transforms
from PIL import Image
import base64
import io
from pymongo import MongoClient

app = Flask(__name__)

# MongoDB setup
client = MongoClient("mongodb://<db_user>:<db_password>@<vm_public_ip>:27017/")
db = client["pictionary"]
collection = db["leaderboard"]

# List of drawable items
CLASSES = [
    "cat", "dog", "car", "house", "tree", "bicycle", "airplane", "flower", "guitar", "chair",
    "horse", "boat", "train", "clock", "fish", "banana", "apple", "sun", "moon", "star"
]

@app.route("/classify", methods=["POST"])
def classify():
    username = request.json.get("username")
    data = request.json.get("image")
    image = Image.open(io.BytesIO(base64.b64decode(data)))

    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor()
    ])
    tensor = transform(image).unsqueeze(0)

    # Simulated prediction
    prediction = CLASSES[int(torch.randint(0, len(CLASSES), (1,)).item())]

    if username:
        collection.update_one({"username": username}, {"$inc": {"score": 1}}, upsert=True)

    return jsonify({"prediction": prediction})

@app.route("/leaderboard", methods=["GET"])
def leaderboard():
    results = collection.find().sort("score", -1)
    return jsonify([{"username": doc["username"], "score": doc["score"]} for doc in results])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)