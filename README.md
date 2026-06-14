# 🛒 Local Commerce App

A full-stack hyperlocal commerce platform connecting **Customers**, **Shopkeepers**, and **Distributors**. Built with **Flutter** (Frontend), **NestJS** (Backend), and **MongoDB Atlas** (Database).

---

## 🚀 Features

- **Multi-Role Auth**: Separate dashboards and flows for Customers, Shopkeepers, and Distributors (JWT + Role Guards).
- **Customer App**: Browse shops, search products/shops, manage cart, place orders, and track order status.
- **Shopkeeper Dashboard**: Incoming order management with one-tap status updates (Placed → Processing → Dispatched → Delivered), inventory management, analytics, and shop verification.
- **Distributor Module**: List and connect with local distributors.
- **Full-Stack Cart**: Real-time cart with backend persistence per user.
- **Order Lifecycle**: Complete order flow — cart → checkout → status tracking (Placed, Processing, Dispatched, Delivered).
- **Inventory Management**: Add/edit/delete products with stock tracking and low-stock alerts.
- **Shop Verification**: Document upload and admin review workflow.
- **Premium UI**: Glassmorphism, animated cards, custom design system with dark tokens.

---

## 🛠️ Tech Stack

| Layer | Tech |
|---|---|
| Frontend | Flutter (Dart), Provider, Hive, flutter_animate |
| Backend | NestJS (TypeScript), Mongoose |
| Database | MongoDB Atlas |
| Auth | JWT + bcrypt, Role-based Guards |
| Media | Cloudinary (product images) |
| Docs | Swagger/OpenAPI (`/api`) |

---

## ⚙️ Setup

### 1. Backend (NestJS)
```bash
cd server
npm install
```
Copy `.env.example` to `.env` and fill in your values:
```env
MONGODB_URI=mongodb+srv://<user>:<pass>@<cluster>.mongodb.net/<db>
PORT=5001
JWT_SECRET=your_secret_here
JWT_EXPIRES_IN=7d
```
```bash
npm run start:dev
```
API docs available at `http://localhost:5001/api`

### 2. Frontend (Flutter)
```bash
cd frontend
flutter pub get
```
Update `frontend/lib/core/network/api_client.dart` with your backend base URL:
- **Emulator**: `http://10.0.2.2:5001`
- **Physical device / Web**: `http://<your-local-ip>:5001`

```bash
flutter run -d chrome    # Web
flutter run              # Mobile
```

---

## 🏗️ Project Structure

```
LocalCommerceApp/
├── server/                   # NestJS API
│   └── src/
│       ├── common/           # Filters, Guards, Interceptors
│       └── modules/
│           ├── auth/         # JWT auth, login, register
│           ├── users/        # User profiles
│           ├── shops/        # Shop CRUD & verification
│           ├── products/     # Product & inventory management
│           ├── cart/         # Cart persistence
│           └── orders/       # Order lifecycle & status updates
├── frontend/                 # Flutter app
│   └── lib/
│       ├── core/             # ApiClient, design system, constants
│       └── features/
│           ├── auth/         # Login, register, welcome
│           ├── customer/     # Customer dashboard, cart, checkout
│           ├── shopkeeper/   # Shopkeeper dashboard, inventory
│           ├── distributor/  # Distributor listing
│           ├── shop/         # Shop models & browsing
│           ├── orders/       # Order models & tracking
│           └── products/     # Product models
└── admin/                    # Admin panel (optional)
```

---

## 📦 Order Status Flow

```
Placed → Processing → Dispatched → Delivered
```
Shopkeepers update status from their dashboard with one tap per stage.

---

## 📜 License
MIT
