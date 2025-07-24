from flask import Flask, request, jsonify
import torch
from torchvision import transforms
from PIL import Image
import base64
import io
import os
from pymongo import MongoClient

app = Flask(__name__)

client = MongoClient(os.environ.get("DB_URI"))
db = client.get_database()

@app.route("/api/classify", methods=["POST"])
def classify():
    data = request.json.get("image")
    image = Image.open(io.BytesIO(base64.b64decode(data)))
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor()
    ])
    tensor = transform(image).unsqueeze(0)
    prediction = "banana 🍌" if torch.rand(1).item() > 0.5 else "car 🚗"
    db.predictions.insert_one({"image": data, "prediction": prediction})
    return jsonify({"prediction": prediction})

@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
