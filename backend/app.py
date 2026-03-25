from flask import Flask
from pymongo import MongoClient
from dotenv import load_dotenv
import os

load_dotenv() 

app = Flask(__name__)

MONGO_URI = os.getenv("MONGO_URI")

client = MongoClient(MONGO_URI)
db = client["local_commerce"]

@app.route("/")
def home():
    return "MongoDB Connected ✅"

if __name__ == "__main__":
    app.run(debug=True)