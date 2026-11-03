# ProNow Mobile

Flutter app focused on Android and Chrome, with a FastAPI backend in `..\backend`.

## Run locally

Start the backend from `backend`:

```powershell
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Run the app from `mobile`:

```powershell
flutter run -d chrome
flutter run -d android
```

Chrome uses `http://127.0.0.1:8000/api/v1`; the Android emulator uses
`http://10.0.2.2:8000/api/v1`. For a physical Android device, set the backend
computer's LAN address:

```powershell
flutter run -d android --dart-define=PRONOW_API_BASE_URL=http://192.168.1.10:8000/api/v1
```

Replace `192.168.1.10` with the backend computer's LAN IP.
Use HTTPS for non-development deployments.
