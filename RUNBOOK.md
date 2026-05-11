# SkillMatch Platform Runbook

This workspace contains the SkillMatch Platform capstone app:

- Backend: `skillmatch-backend-main`
- Flutter app: `skillmatch-frontend-main/skillmatch-web`

## 1. Backend Setup

## Quick Start

From the workspace root:

```powershell
.\run-skillmatch.ps1
```

Or from Command Prompt / double-click style:

```bat
run-skillmatch.bat
```

To refresh the dummy capstone demo data while starting:

```powershell
.\run-skillmatch.ps1 -SeedDemo
```

For a faster restart after the web app has already been built:

```powershell
.\run-skillmatch.ps1 -SkipBuild
```

The launcher starts:

- Backend API: `http://localhost:5000`
- Web app: `http://localhost:5050`

If the launcher says MongoDB is not connected, open MongoDB Atlas:

1. Go to **Network Access**.
2. Add your current IP address, or temporarily allow `0.0.0.0/0` for local demo testing.
3. Run `.\run-skillmatch.ps1 -SkipBuild -SkipInstall` again.

Copy the backend environment template:

```powershell
Copy-Item skillmatch-backend-main\.env.example skillmatch-backend-main\.env
```

Edit `skillmatch-backend-main\.env` and set:

- `MONGO_URI` to your new MongoDB Atlas connection string, including the `skillmatch` database name.
- `JWT_SECRET` to a long random secret.
- `EMAIL_USER` and `EMAIL_PASS` if email verification/password reset should work.
- `OPENAI_API_KEY` if smart matching and smart job extraction should call OpenAI.
- `GOOGLE_APPLICATION_CREDENTIALS`, `GCS_KEY_FILE`, and `GCS_BUCKET` if Firebase Admin or Google Cloud Storage/OCR features are needed.

Install dependencies:

```powershell
cd skillmatch-backend-main
& "C:\Program Files\nodejs\npm.cmd" install
```

Run the backend:

```powershell
& "C:\Program Files\nodejs\npm.cmd" start
```

Populate or refresh demo data:

```powershell
& "C:\Program Files\nodejs\npm.cmd" run seed:demo
```

Expected startup:

```text
SkillMatch Platform API running at http://localhost:5000
MongoDB connected.
```

If `MONGO_URI` is still a placeholder, the backend still starts but logs:

```text
MongoDB disabled: set MONGO_URI in .env to your Atlas skillmatch database.
```

## 2. Frontend Setup

Copy the frontend environment template:

```powershell
Copy-Item skillmatch-frontend-main\skillmatch-web\api.env.example skillmatch-frontend-main\skillmatch-web\api.env
```

For Edge/web local testing, use:

```text
BASE_URL=http://localhost:5000/api
BASE_URL2=http://localhost:5000
```

For Android emulator testing, use:

```text
BASE_URL=http://10.0.2.2:5000/api
BASE_URL2=http://10.0.2.2:5000
```

Install Flutter dependencies:

```powershell
cd skillmatch-frontend-main\skillmatch-web
& "C:\dev\flutter\bin\flutter.bat" pub get
```

Run on Edge:

```powershell
& "C:\dev\flutter\bin\flutter.bat" run -d edge --web-port 5050
```

If the Edge debug websocket fails, use the more stable demo server:

```powershell
& "C:\dev\flutter\bin\flutter.bat" build web --no-wasm-dry-run
& "C:\Program Files\nodejs\node.exe" scripts\serve_web.js
```

Then open:

```text
http://localhost:5050
```

Run on Android emulator:

```powershell
& "C:\dev\flutter\bin\flutter.bat" devices
& "C:\dev\flutter\bin\flutter.bat" run -d emulator-5554
```

## 3. Firebase Setup

The checked-in Firebase values are placeholders. To enable Firebase:

1. Create a Firebase project in your own account.
2. Run FlutterFire configuration or manually update `lib/firebase_options.dart`.
3. Download Android `google-services.json` and place it at `android/app/google-services.json` if you re-enable the Google Services Gradle plugin.
4. Download a Firebase Admin service account JSON and store it outside the repository.
5. Set `GOOGLE_APPLICATION_CREDENTIALS` in backend `.env` to the absolute path of that service account JSON.

Web startup skips push notifications and camera/microphone prompts so the browser demo can render safely.

## 4. Demo Checklist

- Backend starts on `http://localhost:5000`.
- MongoDB logs `MongoDB connected.`
- Web app opens at `http://localhost:5050`.
- Landing page shows SkillMatch Platform branding.
- Sign in/sign up navigation opens.
- Database-backed flows work after Atlas credentials are configured.

## 5. Demo Accounts

All demo accounts use the same password:

```text
123456
```

- `admin@admin.com` - admin dashboard
- `jobseeker@demo.com` - job seeker flow
- `developer@demo.com` - second job seeker with backend skills
- `freelancer@demo.com` - freelancer flow
- `designer@demo.com` - second freelancer/UX profile
- `organization@demo.com` - technology organization flow
- `healthorg@demo.com` - healthcare organization flow
