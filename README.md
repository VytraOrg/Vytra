# ?? Local Commerce App

A modern, full-stack commerce solution connecting local shopkeepers, distributors, and customers. Built with **Flutter** (Frontend), **NestJS** (Backend), and **MongoDB Atlas** (Database).

---

## ?? Features

- **Multi-Role Support**: Custom interfaces and logic for Customers, Shopkeepers, and Distributors.
- **Smart Global Search**: Customers can search across all nearby shops, or use intelligent category chips (Staples, Dairy, Veggies, Snacks) to instantly find products.
- **Premium UI**: Modern Glassmorphism, Neumorphic design elements, haptic feedback, and dynamic profile headers.
- **Secure Auth**: JWT-based authentication with role guards, offline session persistence via Hive, and robust logout workflows.
- **High-Performance Architecture**: Backend powered by NestJS (TypeScript) with Mongoose, supporting parallel request processing and clean module boundaries.
- **Real-time Discovery**: Geolocation-ready shop indexing and dynamic product discovery (Swiggy/Zomato style).

---

## ??? Tech Stack

- **Frontend**: Flutter (Dart) with Provider & Hive
- **Backend**: NestJS (TypeScript, Node.js)
- **Database**: MongoDB Atlas (Cloud)
- **Authentication**: JWT (JSON Web Tokens) & bcrypt
- **Caching & State**: Hive (Local NoSQL) for lightning-fast user sessions

---

## ?? Setup Instructions

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

#### **?? Connecting to the Local Backend**
The app communicates with the backend via `frontend/lib/api_config.dart`.
1. If using an emulator, it defaults to `10.0.2.2`.
2. If using a physical device, update `ApiConfig.baseUrl` to your computer's local Wi-Fi IP address (e.g., `192.168.x.x`).
3. Run the app:
   ```bash
   flutter run
   ```

---

## ?? Project Structure

```text
LocalCommerceApp/
+-- server/             # NestJS API & MongoDB Logic
¦   +-- src/            # Auth, Users, Shops, Products, Orders Modules
¦   +-- scratch/        # Database seeding scripts
¦   +-- .env            # Private Credentials
+-- frontend/           # Flutter Mobile Application
¦   +-- lib/
¦   ¦   +-- core/       # Network, Theme, Design System, Cache
¦   ¦   +-- features/   # Auth, Account, Shop, Cart logic and screens
¦   ¦   +-- widgets/    # Reusable UI components
¦   ¦   +-- main.dart   # App Entrypoint
¦   +-- pubspec.yaml    # Dependencies
+-- README.md
```

---

## ?? Contributing
Feel free to fork this project and submit pull requests for any features or bug fixes.

---

## ?? License
This project is licensed under the MIT License.

