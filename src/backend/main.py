# main.py
from flask import Flask, request, jsonify
from pymongo import MongoClient
import random
import os

app = Flask(__name__)

# --- Database Setup ---
# It's better to get the connection string from an environment variable
db_uri = os.environ.get("DB_URI", "mongodb://localhost:27017/")
client = MongoClient(db_uri)
db = client["sketchydb"] 
leaderboard_collection = db["leaderboard"]

# --- Game Data ---
# In a real app, this would come from a database
PRODUCTS = [
    {"id": 1, "name": "A Dozen Large Eggs", "price": 4.29, "image": "/images/eggs.png"},
    {"id": 2, "name": "KitchenAid Artisan Series 5 Quart Stand Mixer", "price": 449.95, "image": "/images/kitchenaid_mixer.png"},
    {"id": 3, "name": "Toilet Paper (12 Mega Rolls)", "price": 22.50, "image": "/images/toilet_paper.png"},
    {"id": 4, "name": "Gallon of Milk", "price": 3.89, "image": "/images/milk_gallon.png"},
    {"id": 5, "name": "Amazon Fire TV Stick 4K", "price": 49.99, "image": "/images/fire_stick.png"},
    {"id": 6, "name": "Paper Towels (6 Double Rolls)", "price": 15.99, "image": "/images/paper_towels.png"},
    {"id": 7, "name": "Fujifilm Instax Mini 12 Instant Camera", "price": 79.95, "image": "/images/fujifilm_camera.png"},
    {"id": 8, "name": "A Loaf of Bread", "price": 3.49, "image": "/images/bread.png"},
    {"id": 9, "name": "Yoga Mat", "price": 34.95, "image": "/images/yoga_mat.png"},
    {"id": 10, "name": "Sonos Era 100 Speaker", "price": 249.00, "image": "/images/sonos_speaker.png"},
    {"id": 11, "name": "Laundry Detergent (92 oz)", "price": 14.97, "image": "/images/laundry_detergent.png"},
    {"id": 12, "name": "Wireless Optical Mouse", "price": 29.99, "image": "/images/mouse.png"},
    {"id": 13, "name": "Compact Travel Umbrella", "price": 24.99, "image": "/images/umbrella.png"}
]

# --- API Endpoints ---

@app.route("/product", methods=["GET"])
def get_product():
    """Returns a random product for the user to bid on."""
    product = random.choice(PRODUCTS)
    return jsonify(product)


@app.route("/bid", methods=["POST"])
def submit_bid():
    """Processes a user's bid and updates the leaderboard."""
    data = request.get_json()
    product_id = data.get("productId")
    user_bid = data.get("userBid")
    username = data.get("username")

    if not all([product_id, user_bid, username]):
        return jsonify({"error": "Missing data"}), 400

    # Find the product in our list
    product = next((p for p in PRODUCTS if p["id"] == product_id), None)
    if not product:
        return jsonify({"error": "Product not found"}), 404

    # Check the bid
    if user_bid == product["price"]:
        result_message = "You win! The price was exactly right!"
        # Update leaderboard on a correct guess
        leaderboard_collection.update_one(
            {"username": username}, 
            {"$inc": {"score": 1}}, 
            upsert=True
        )
    elif user_bid > product["price"]:
        result_message = "Too high! Try again on the next item."
    else:
        result_message = "Too low! Try again on the next item."

    return jsonify({"result": result_message})


@app.route("/leaderboard", methods=["GET"])
def get_leaderboard():
    """Returns the current leaderboard, sorted by score."""
    results = leaderboard_collection.find().sort("score", -1)
    return jsonify([{"username": doc["username"], "score": doc["score"]} for doc in results])


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)