# 🛒 Vytra - Hyperlocal Commerce Platform

Vytra is an enterprise-grade, 3-sided hyperlocal commerce platform connecting **Customers**, **Shopkeepers**, and **Distributors**. Built with **Flutter** (Frontend), **NestJS** (Backend), and **MongoDB Atlas** (Database).

---

## 🚀 Key Features

### 🔍 Intelligent Hyperlocal Search Engine
- **Tokenized Weighted Search**: Multi-field search across product names, categories, and descriptions with relevance scoring.
- **Hyperlocal GPS Proximity**: MongoDB `$geoNear` aggregation sorts nearest stores first with live distance badges (`📍 1.2 km away`) and proximity score boosts.
- **Regional & Colloquial Synonyms**: Seamless multi-dialect support (e.g. `aloo/alu` $\leftrightarrow$ `potato`, `doodh` $\leftrightarrow$ `milk`, `pyaz` $\leftrightarrow$ `onion`, `sabun` $\leftrightarrow$ `soap`).
- **Typo Tolerance & Spell Correction**: Levenshtein distance matching with automatic fallback queries and *"Did you mean?"* recovery chips.
- **Real-Time Autocomplete**: Debounced instant search suggestions and category hints.
- **Persistent Search History**: Local search history with 1-tap delete and instant "Clear All".

### 👥 Multi-Role Ecosystem
- **Customer Experience**: Store discovery by category & proximity, product browsing, full-stack persistent cart, and live order tracking.
- **Shopkeeper Operations**: Instant order fulfillment workflow (Placed → Processing → Dispatched → Delivered), inventory management with low-stock alerts, and store verification.
- **Distributor Network**: B2B bulk sourcing and store discovery for local retailers.

### 🛡️ Architecture & Security
- **Authentication**: JWT authentication with refresh token rotation and role-based guards.
- **Security & Headers**: Helmet, rate-limiting (`ThrottlerModule`), and granular CORS configuration.
- **Caching**: Non-blocking Redis cache layer with graceful offline resilience.
- **Interactive Documentation**: Integrated Swagger/OpenAPI at `/docs`.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Dart), Provider, Hive, Geolocator, flutter_animate |
| **Backend** | NestJS (TypeScript), Mongoose, Helmet, Compression |
| **Database** | MongoDB Atlas (Geospatial 2dsphere & compound text indexes) |
| **Cache** | Redis (ioredis) |
| **Auth** | JWT + bcrypt, Role-based Guards |
| **Media** | Cloudinary |
| **API Docs** | Swagger / OpenAPI (`/docs`) |

---

## ⚙️ Quick Start

### 1. Prerequisites
- **Node.js** (v18+) & **npm**
- **Flutter SDK** (v3.0+)
- **MongoDB Atlas** database cluster

---

### 2. Backend Setup (NestJS)

```bash
cd server
npm install
```

Create a `.env` file in the `server/` directory:

```env
PORT=5001
MONGODB_URI=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/<database>?appName=<cluster-name>
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRES_IN=7d
REDIS_URL=redis://default:<password>@<host>:<port>  # Optional
```

Run in development mode:
```bash
npm run start:dev
```
* **API Base URL**: `http://localhost:5001/api/v1`
* **Swagger API Docs**: `http://localhost:5001/docs`

---

### 3. Frontend Setup (Flutter)

```bash
cd frontend
flutter pub get
```

The app automatically switches between local backend during development and the live hosted Render backend for release builds:

```bash
# Run on Chrome Web
flutter run -d chrome

# Run on Android Emulator / Physical Device
flutter run
```

> **Note**: To force using the hosted remote backend during development, run:
> ```bash
> flutter run -d chrome --dart-define=USE_REMOTE_BACKEND=true
> ```

---

## 📡 API Overview

| Group | Method | Endpoint | Description |
|---|---|---|---|
| **Auth** | `POST` | `/api/v1/auth/register` | Register customer / shopkeeper / distributor |
| | `POST` | `/api/v1/auth/login` | JWT login with access & refresh tokens |
| | `POST` | `/api/v1/auth/refresh` | Rotate and issue new access token |
| **Shops** | `GET` | `/api/v1/shops` | List & filter shops (supports `lat`, `lng`, `shopType`, `category`) |
| | `GET` | `/api/v1/shops/my` | Get current shopkeeper's store profile |
| | `POST` | `/api/v1/shops/verify` | Submit store verification documents |
| **Products** | `GET` | `/api/v1/products/search` | Global multi-token & proximity search with synonyms |
| | `GET` | `/api/v1/products/suggestions` | Instant autocomplete suggestions |
| | `GET` | `/api/v1/products` | Paginated product list by store / category |
| | `GET` | `/api/v1/products/:id` | Single product details |
| **Cart** | `GET` | `/api/v1/cart` | Get current user's persistent cart |
| | `POST` | `/api/v1/cart/items` | Add/update item quantity in cart |
| | `DELETE` | `/api/v1/cart/items/:id` | Remove product from cart |
| **Orders** | `POST` | `/api/v1/orders` | Place a new order |
| | `GET` | `/api/v1/orders/my` | Customer order history |
| | `GET` | `/api/v1/orders/my-shop` | Shopkeeper incoming order queue |
| | `PUT` | `/api/v1/orders/:id/status` | Update order stage (`Placed` → `Processing` → `Dispatched` → `Delivered`) |

---

## 📜 License
MIT License. Built for seamless local commerce.
