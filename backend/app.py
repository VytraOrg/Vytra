from flask import Flask, jsonify, request
from pymongo import MongoClient
from dotenv import load_dotenv
from bson.objectid import ObjectId
from flask_cors import CORS
from werkzeug.security import check_password_hash, generate_password_hash
import os

load_dotenv() 

app = Flask(__name__)
CORS(app)

MONGO_URI = os.getenv("MONGO_URI")

client = MongoClient(MONGO_URI)
db = client["local_commerce"]

products_col = db["products"]
carts_col = db["carts"]
orders_col = db["orders"]
users_col = db["users"]


def serialize_doc(doc):
    doc["id"] = str(doc.pop("_id"))
    return doc


def parse_object_id(value):
    try:
        return ObjectId(value)
    except Exception:
        return None


def derive_customer_id(email):
    normalized = email.strip().lower()
    return "".join(char if char.isalnum() else "_" for char in normalized)

@app.route("/")
def home():
    return "MongoDB Connected ✅"


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


@app.route("/api/auth/register", methods=["POST"])
def register_user():
    data = request.get_json(silent=True) or {}
    name = str(data.get("name", "")).strip()
    email = str(data.get("email", "")).strip().lower()
    password = str(data.get("password", ""))
    role = str(data.get("role", "Customer")).strip()
    business_name = str(data.get("businessName", "")).strip()

    if not name or not email or not password:
        return jsonify({"error": "name, email and password are required"}), 400
    if "@" not in email:
        return jsonify({"error": "Invalid email"}), 400
    if len(password) < 6:
        return jsonify({"error": "Password must be at least 6 characters"}), 400

    existing_user = users_col.find_one({"email": email})
    if existing_user:
        return jsonify({"error": "Account already exists for this email"}), 409

    customer_id = derive_customer_id(email)
    user_doc = {
        "name": name,
        "email": email,
        "passwordHash": generate_password_hash(password),
        "role": role,
        "businessName": business_name,
        "customerId": customer_id,
    }
    inserted = users_col.insert_one(user_doc)
    created = users_col.find_one({"_id": inserted.inserted_id})

    return jsonify({
        "message": "Account created successfully",
        "user": {
            "id": str(created["_id"]),
            "name": created.get("name", ""),
            "email": created.get("email", ""),
            "role": created.get("role", "Customer"),
            "businessName": created.get("businessName", ""),
            "customerId": created.get("customerId", ""),
        },
    }), 201


@app.route("/api/auth/login", methods=["POST"])
def login_user():
    data = request.get_json(silent=True) or {}
    email = str(data.get("email", "")).strip().lower()
    password = str(data.get("password", ""))

    if not email or not password:
        return jsonify({"error": "email and password are required"}), 400

    user = users_col.find_one({"email": email})
    if not user or not check_password_hash(user.get("passwordHash", ""), password):
        return jsonify({"error": "Invalid email or password"}), 401

    return jsonify({
        "message": "Login successful",
        "user": {
            "id": str(user["_id"]),
            "name": user.get("name", ""),
            "email": user.get("email", ""),
            "role": user.get("role", "Customer"),
            "businessName": user.get("businessName", ""),
            "customerId": user.get("customerId", derive_customer_id(email)),
        },
    })


@app.route("/api/products", methods=["GET"])
def get_products():
    shop_name = request.args.get("shop")
    query = {"shopName": shop_name} if shop_name else {}
    products = [serialize_doc(product) for product in products_col.find(query)]
    return jsonify(products)


@app.route("/api/products", methods=["POST"])
def create_product():
    data = request.get_json(silent=True) or {}
    required_fields = ["name", "price", "shopName"]
    missing = [field for field in required_fields if field not in data]
    if missing:
        return jsonify({"error": f"Missing required fields: {', '.join(missing)}"}), 400

    payload = {
        "name": data["name"],
        "price": float(data["price"]),
        "shopName": data["shopName"],
        "description": data.get("description", ""),
        "unit": data.get("unit", "1 pc"),
    }
    inserted = products_col.insert_one(payload)
    created = products_col.find_one({"_id": inserted.inserted_id})
    return jsonify(serialize_doc(created)), 201


@app.route("/api/products/<product_id>", methods=["PUT"])
def update_product(product_id):
    object_id = parse_object_id(product_id)
    if not object_id:
        return jsonify({"error": "Invalid product id"}), 400

    data = request.get_json(silent=True) or {}
    allowed = ["name", "price", "shopName", "description", "unit"]
    updates = {key: data[key] for key in allowed if key in data}
    if "price" in updates:
        updates["price"] = float(updates["price"])
    if not updates:
        return jsonify({"error": "No valid fields provided"}), 400

    result = products_col.update_one({"_id": object_id}, {"$set": updates})
    if result.matched_count == 0:
        return jsonify({"error": "Product not found"}), 404

    updated = products_col.find_one({"_id": object_id})
    return jsonify(serialize_doc(updated))


@app.route("/api/products/<product_id>", methods=["DELETE"])
def delete_product(product_id):
    object_id = parse_object_id(product_id)
    if not object_id:
        return jsonify({"error": "Invalid product id"}), 400

    result = products_col.delete_one({"_id": object_id})
    if result.deleted_count == 0:
        return jsonify({"error": "Product not found"}), 404
    return jsonify({"message": "Product deleted"})


@app.route("/api/cart/<customer_id>", methods=["GET"])
def get_cart(customer_id):
    cart = carts_col.find_one({"customerId": customer_id})
    if not cart:
        return jsonify({"customerId": customer_id, "items": []})
    return jsonify(serialize_doc(cart))


@app.route("/api/cart/<customer_id>/items", methods=["POST"])
def add_to_cart(customer_id):
    data = request.get_json(silent=True) or {}
    product_id = data.get("productId")
    quantity = int(data.get("quantity", 1))
    if not product_id:
        return jsonify({"error": "productId is required"}), 400

    object_id = parse_object_id(product_id)
    if not object_id:
        return jsonify({"error": "Invalid product id"}), 400

    product = products_col.find_one({"_id": object_id})
    if not product:
        return jsonify({"error": "Product not found"}), 404

    cart = carts_col.find_one({"customerId": customer_id})
    item = {
        "productId": product_id,
        "name": product.get("name", "Product"),
        "price": float(product.get("price", 0)),
        "quantity": quantity,
    }

    if not cart:
        carts_col.insert_one({"customerId": customer_id, "items": [item]})
    else:
        items = cart.get("items", [])
        found = False
        for existing in items:
            if existing.get("productId") == product_id:
                existing["quantity"] = int(existing.get("quantity", 0)) + quantity
                found = True
                break
        if not found:
            items.append(item)
        carts_col.update_one({"_id": cart["_id"]}, {"$set": {"items": items}})

    updated = carts_col.find_one({"customerId": customer_id})
    return jsonify(serialize_doc(updated)), 201


@app.route("/api/cart/<customer_id>/items/<product_id>", methods=["DELETE"])
def remove_from_cart(customer_id, product_id):
    cart = carts_col.find_one({"customerId": customer_id})
    if not cart:
        return jsonify({"error": "Cart not found"}), 404

    items = [item for item in cart.get("items", []) if item.get("productId") != product_id]
    carts_col.update_one({"_id": cart["_id"]}, {"$set": {"items": items}})
    updated = carts_col.find_one({"_id": cart["_id"]})
    return jsonify(serialize_doc(updated))


@app.route("/api/orders", methods=["POST"])
def create_order():
    data = request.get_json(silent=True) or {}
    customer_id = data.get("customerId")
    if not customer_id:
        return jsonify({"error": "customerId is required"}), 400

    cart = carts_col.find_one({"customerId": customer_id})
    if not cart or not cart.get("items"):
        return jsonify({"error": "Cart is empty"}), 400

    items = cart.get("items", [])
    total = sum(float(item.get("price", 0)) * int(item.get("quantity", 1)) for item in items)

    order_doc = {
        "customerId": customer_id,
        "items": items,
        "total": total,
        "status": "placed",
    }
    inserted = orders_col.insert_one(order_doc)
    carts_col.update_one({"_id": cart["_id"]}, {"$set": {"items": []}})

    created = orders_col.find_one({"_id": inserted.inserted_id})
    return jsonify(serialize_doc(created)), 201


@app.route("/api/orders/<customer_id>", methods=["GET"])
def list_orders(customer_id):
    orders = [
        serialize_doc(order)
        for order in orders_col.find({"customerId": customer_id}).sort("_id", -1)
    ]
    return jsonify(orders)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)