# 🛒 Local Commerce App

A modern, full-stack commerce solution connecting local shopkeepers, distributors, and customers. Built with **Flutter** (Frontend), **Flask** (Backend), and **MongoDB Atlas** (Database).

---

## 🚀 Features

- **Multi-Role Support**: Custom interfaces for Customers, Shopkeepers, and Distributors.
- **Real-time Inventory**: Shopkeepers can manage stock levels with low-stock alerts.
- **Premium UI**: Modern Glassmorphism and Neumorphic design elements.
- **Secure Auth**: Password hashing with Werkzeug and secure document verification.
- **Order Management**: End-to-end order flow from cart to confirmation.
- **Analytics**: Performance insights and weekly sales trends for business owners.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Flask (Python)
- **Database**: MongoDB Atlas (Cloud)
- **Authentication**: Werkzeug Security
- **Connectivity**: Automated IP Syncing for local development.

---

## ⚙️ Setup Instructions

### 1. Backend Setup (Python)
Navigate to the `backend` folder:
```bash
cd backend
pip install -r requirements.txt
```
Create a `.env` file with your MongoDB URI:
```env
MONGO_URI=mongodb+srv://your_credentials...
```
Start the server:
```bash
python app.py
```

### 2. Frontend Setup (Flutter)
Navigate to the `frontend` folder:
```bash
cd frontend
flutter pub get
```

#### **📲 Connecting a Physical Device**
If you are using a real phone (not an emulator), your app needs to know your computer's IP address.
1. Ensure your phone and PC are on the **same Wi-Fi**.
2. Run the **Auto-Sync** script:
   ```bash
   dart lib/sync_ip.dart
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```text
LocalCommerceApp/
├── backend/            # Flask API & MongoDB Logic
│   ├── app.py          # Main Server
│   └── .env            # Private Credentials
├── frontend/           # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart       # Login & Auth
│   │   ├── register.dart   # Account Creation
│   │   ├── api_config.dart # Connection Settings
│   │   └── sync_ip.dart    # IP Auto-Config Tool
│   └── pubspec.yaml    # Dependencies
└── README.md
```

---

## 🤝 Contributing
Feel free to fork this project and submit pull requests for any features or bug fixes.

---

## 📄 License
This project is licensed under the MIT License.
