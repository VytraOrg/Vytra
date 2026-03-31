# LocalCommerceApp Frontend

Flutter client for LocalCommerceApp.

## Prerequisites

- Flutter SDK installed
- Python 3.10+ for backend API
- MongoDB connection string in `backend/.env` as `MONGO_URI`

## 1. Start Backend API (Flask)

From project root:

```bash
cd backend
pip install -r requirements.txt
python app.py
```

The API runs on `http://0.0.0.0:5000` (reachable as `http://localhost:5000` from the same machine).

Quick health check:

```bash
curl http://127.0.0.1:5000/api/health
```

Expected response:

```json
{"status":"ok"}
```

## 2. Start Frontend (Flutter)

From project root:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

`-d chrome` is recommended for a more reliable web debug workflow than `-d web-server`.

## API Base URL Configuration

Frontend API URL is resolved in `lib/api_config.dart`:

- Uses `--dart-define=API_BASE_URL=...` when provided
- Web default: same host as app, port `5000`
- Mobile emulator default: `http://10.0.2.2:5000`

Example override:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

## Troubleshooting

- If you see `Unable to connect to server`, verify backend is running and health endpoint works.
- If using a remote/dev-container setup, pass `API_BASE_URL` explicitly with `--dart-define`.
- If hot reload/hot restart times out on web-server, use `-d chrome`.

### Codespaces/Port Forwarding Note

If the frontend runs in browser on your local machine, `http://localhost:5000` may not point to the container backend.

Use forwarded backend URL:

```bash
flutter run -d web-server --dart-define=API_BASE_URL=https://<codespace-name>-5000.app.github.dev
```

If the browser shows tunnel auth/401 for that URL, open the backend URL once in browser and authenticate, then retry inside the app.
