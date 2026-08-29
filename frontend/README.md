# Vytra - Frontend Client

Flutter client application for the Vytra Hyperlocal Commerce Platform.

---

## 🚀 Features

- **Hyperlocal Location & Proximity**: Live GPS coordinate integration using `geolocator` with real-time distance calculations and proximity store sorting.
- **Intelligent Search Engine**:
  - Autocomplete search suggestions with debounced real-time queries.
  - Typo tolerance and regional synonym support.
  - Persistent recent searches with Hive storage and instant clear.
- **Role-Based UX**: Distinct tailored views for **Customers**, **Shopkeepers**, and **Distributors**.
- **Cart & Order Flow**: Live cart persistence, order placement, and status tracking.
- **Adaptive Backend Switching**:
  - Automatically targets `http://localhost:5001/api/v1` during debug/development.
  - Automatically targets live hosted backend `https://localcommerceapp-1.onrender.com/api/v1` for production release builds.

---

## ⚙️ Running Locally

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App

```bash
# Run on Google Chrome
flutter run -d chrome

# Run on Android Emulator / Physical Device
flutter run
```

### 3. Force Remote Backend (Optional)
To test against the live hosted Render backend during development:
```bash
flutter run -d chrome --dart-define=USE_REMOTE_BACKEND=true
```

---

## 📁 Architecture

```
lib/
├── core/
│   ├── api/             # API constants & dynamic base URL configuration
│   ├── cache/           # Hive local storage (tokens, recent searches)
│   ├── network/         # ApiClient with automatic token refresh
│   ├── services/        # LocationService (GPS)
│   └── theme/           # Design system (colors, typography, shadows)
└── features/
    ├── auth/            # Authentication & onboarding
    ├── cart/            # Cart state management & presentation
    ├── orders/          # Order lifecycle & tracking
    └── shop/            # Catalog browsing, search, and store profiles
```
