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

## 🏗️ Project Structure & Architecture

The project has been recently refactored into an **Enterprise-Grade Architecture** following Clean Architecture principles and Domain-Driven Design (DDD).

### Backend (NestJS)
- **Modular Design**: Each feature is encapsulated in its own module with dedicated Controllers, Services, and Schemas.
- **Strict Input Validation**: Every request payload is validated using **DTOs (Data Transfer Objects)** and `class-validator`.
- **Global Error Handling**: Standardized error responses across the entire API via a custom `AllExceptionsFilter`.
- **Security**: Hardened with **Helmet**, **Compression**, and JWT-based Role Guards.
- **Documentation**: Integrated **Swagger/OpenAPI** for real-time API exploration.

### Frontend (Flutter)
- **Controller-Based State Management**: Logic is decoupled from UI using the **Controller/ChangeNotifier** pattern.
- **Domain-Driven Repository Pattern**: All data access is abstracted through Repositories that return strongly-typed **Entities** and **Models**.
- **Unified Network Layer**: A generic `ApiClient` handles all HTTP communication with standardized error mapping and session management.
- **Widget Modularization**: Large screens have been broken down into small, reusable feature-specific widgets.

```text
LocalCommerceApp/
├── server/             # NestJS API & MongoDB Logic
│   ├── src/            
│   │   ├── common/     # Filters, Guards, Interceptors, DTOs
│   │   ├── modules/    # Auth, Users, Shops, Products, Cart, Orders Modules
│   │   └── main.ts     # Bootstrap with Global Filters/Pipes
├── frontend/           # Flutter Mobile Application
│   └── lib/
│       ├── core/       # Network (ApiClient), Theme, Design System, Constants
│       ├── features/   # Feature-sliced modules (Data/Domain/Presentation)
│       ├── shared/     # Reusable global widgets (NetworkImage, Buttons)
│       └── main.dart   # App Entrypoint & Provider registration
```

---

## 🤝 Contributing
Feel free to fork this project and submit pull requests for any features or bug fixes.

---

## 📜 License
This project is licensed under the MIT License.
