# 🖥️ Local Commerce App — Backend (NestJS)

REST API for the Local Commerce App, built with **NestJS**, **MongoDB Atlas**, and **JWT authentication**.

---

## ⚙️ Setup

```bash
npm install
```

Copy `.env.example` → `.env` and fill in your values:

```env
MONGODB_URI=mongodb+srv://<user>:<pass>@<cluster>.mongodb.net/<db>
PORT=5001
JWT_SECRET=your_secret_here
JWT_EXPIRES_IN=7d

# Optional Redis caching
REDIS_HOST=localhost
REDIS_PORT=6379
```

---

## 🚀 Running

```bash
# Development (watch mode)
npm run start:dev

# Production
npm run start:prod
```

Swagger docs: `http://localhost:5001/api`

---

## 🧪 Tests

```bash
npm run test          # Unit tests
npm run test:e2e      # End-to-end tests
npm run test:cov      # Coverage report
```

---

## 📦 API Modules

| Module | Endpoints | Description |
|---|---|---|
| `auth` | `POST /auth/register`, `POST /auth/login` | JWT auth, role-based |
| `users` | `GET /users/me`, `PUT /users/me` | User profile |
| `shops` | `GET /shops`, `POST /shops`, `GET /shops/my`, `PUT /shops/my/status` | Shop management & verification |
| `products` | `GET /products`, `POST /products`, `PUT /products/:id` | Inventory management |
| `cart` | `GET /cart`, `POST /cart/add`, `DELETE /cart/item/:id` | Cart persistence |
| `orders` | `POST /orders`, `GET /orders/my`, `GET /orders/my-shop`, `PUT /orders/:id/status` | Order lifecycle |

---

## 📦 Order Status Values

Valid statuses for `PUT /orders/:id/status`:

```
Placed | Processing | Dispatched | Delivered | Cancelled
```

---

## 🏗️ Architecture

```
src/
├── common/           # AllExceptionsFilter, Guards, Interceptors
└── modules/
    ├── auth/         # JWT strategy, guards, decorators
    ├── users/        # User schema & service
    ├── shops/        # Shop schema, verification workflow
    ├── products/     # Product schema, stock management
    ├── cart/         # Cart schema, add/remove/clear
    └── orders/       # Order schema, status transitions
```

- **Validation**: `class-validator` DTOs on all endpoints
- **Security**: Helmet, CORS, JWT Role Guards
- **Docs**: Swagger at `/api`
