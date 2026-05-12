# 🛒 Local Commerce App

A modern, full-stack commerce solution connecting local shopkeepers, distributors, and customers. Built with **Flutter** (Frontend), **NestJS** (Backend), and **MongoDB Atlas** (Database).

---

## 🚀 Features

- **Multi-Role Support**: Custom interfaces and logic for Customers, Shopkeepers, and Distributors.
- **Combined Global Search**: Unified search bar that simultaneously scans for **Shop Names** and **Product Names**, displaying them together for faster discovery.
- **Full-Stack Cart System**: Real-time cart management with backend persistence. Add, update, or remove items from any shop globally.
- **Order Lifecycle Tracking**: Complete checkout flow from cart to order creation, including detailed order status tracking (Processing, Shipped, Delivered).
- **Premium UI**: Modern Glassmorphism, Neumorphic design elements, haptic feedback, and dynamic profile headers.
- **Secure Auth**: JWT-based authentication with role guards, offline session persistence, and robust logout workflows.
- **High-Performance Architecture**: Backend powered by NestJS (TypeScript) with Mongoose, supporting parallel request processing and clean module boundaries.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart) with **Provider** (State Management) & **Hive** (Local Persistence)
- **Backend**: NestJS (TypeScript, Node.js)
- **Database**: MongoDB Atlas (Cloud)
- **Authentication**: JWT (JSON Web Tokens) & bcrypt
- **Design System**: Custom design tokens with support for animations and glassmorphism.

---

## ⚙️ Setup Instructions

### 1. Backend Setup (NestJS)
Navigate to the `server` folder:
```bash
cd server
npm install
```
Create a `.env` file with your environment variables:
```env
PORT=5014
MONGO_URI=mongodb+srv://your_credentials...
JWT_SECRET=your_super_secret_key_here
```
Start the server in development mode:
```bash
npm run start:dev
```

### 2. Frontend Setup (Flutter)
Navigate to the `frontend` folder:
```bash
cd frontend
flutter pub get
```

#### **🌐 Connecting to the Local Backend**
The app communicates with the backend via `frontend/lib/api_config.dart`.
1. If using an emulator, it defaults to `10.0.2.2`.
2. If using a physical device, update `ApiConfig.baseUrl` to your computer's local Wi-Fi IP address (e.g., `192.168.x.x`).
3. Run the app:
   ```bash
   flutter run
   ```

---

## 🏗️ Project Structure

```text
LocalCommerceApp/
├── server/             # NestJS API & MongoDB Logic
│   ├── src/            # Auth, Users, Shops, Products, Cart, Orders Modules
│   ├── seed.ts         # Database seeding scripts for development
│   └── .env            # Private Credentials
└── frontend/           # Flutter Mobile Application
    └── lib/
        ├── core/       # Network (ApiClient), Theme, Design System, Cache
        ├── features/   
        │   ├── auth/   # Login, Signup, Session persistence
        │   ├── shop/   # Home dashboard, Discovery, Shop/Product lists
        │   ├── cart/   # Shopping cart management
        │   ├── orders/ # Checkout flow and Order tracking
        │   └── account/# User profile and statistics
        ├── widgets/    # Reusable UI components
        └── main.dart   # App Entrypoint
```

---

## 🤝 Contributing
Feel free to fork this project and submit pull requests for any features or bug fixes.

---

## 📜 License
This project is licensed under the MIT License.
