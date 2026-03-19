# Quran App Project Guide

This guide explains how to run the AI service, Backend API, and Mobile App.

## 1. AI Service (quranai)

Navigate to the `quranai` directory and run the AI server:

```powershell
cd quranai
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

```

## 2. Backend API (quran-api)

Navigate to the `quran-api` directory:

```powershell
cd quran-api
```

### Start Docker Containers

Ensure Docker Desktop is running, then start the containers:

```powershell
docker compose up -d
```

### Setup Database and Seed Data

Run the migrations and seed the database with necessary Quran data:

```powershell
php artisan migrate
php artisan quran:seed-reciters
php artisan quran:seed-warsh-text
php artisan app:import-translations
```

### Serve the API

1. Open a new terminal window.
2. Run `ipconfig` to find your IPv4 Address (e.g., 192.168.1.6).
3. Serve the application using your specific IP address:

```powershell
php artisan serve --host=YOUR_IPV4_ADDRESS --port=8001
```

*Replace `YOUR_IPV4_ADDRESS` with your actual IP (e.g., 192.168.1.6).*

## 3. Mobile App (quranapp)

Navigate to the `quranapp` directory:

```powershell
cd ..\quranapp
```

### Update API Configuration

Before running the app, you must update the API endpoint to match your computer's IP address.

1. Open `lib\core\network\api_endpoints.dart`.
2. Locate the `baseUrl` variable.
3. Update the IP address to match the one you used in the `php artisan serve` command.

```dart
// Example
static const String baseUrl = 'http://192.168.1.6:8001/api';
```

### Run the App

```powershell
flutter run
```
