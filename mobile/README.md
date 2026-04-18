# Navratri Event App 🪔

Official mobile application for the Navratri 2024 Event Management System.

## 🚀 Running the Apps

### 1. User App (Booking & Tickets)
The main app for users to browse events, buy tickets, and manage their profile.
```powershell
# Run on web
flutter run -d chrome

# Run on mobile (with emulator/device)
flutter run
```

### 2. Scanner App (Gate Verification)
Simplified app for gatekeepers to scan QR codes and verify entries.
```powershell
# Run on web
flutter run -t lib/main_scanner.dart -d chrome

# Run on mobile
flutter run -t lib/main_scanner.dart
```

---

## 🛠️ Configuration

### API Connection
Edit `lib/services/api_service.dart` to change the backend URL:
- **Localhost (Windows/Web)**: `http://localhost:3000/api`
- **Android Emulator**: `http://10.0.2.2:3000/api`

### Setup Instructions
1. Ensure the **NestJS Backend** is running:
   ```powershell
   cd backend
   npm run start:dev
   ```
2. Install Flutter dependencies:
   ```powershell
   cd mobile
   flutter pub get
   ```
3. Use Test OTP: **`123456`**

## 📂 Project Structure
- `lib/main.dart`: User App Entry
- `lib/main_scanner.dart`: Scanner App Entry
- `lib/screens/`: App screens (shared)
- `lib/providers/`: State management (shared)
- `lib/theme/`: Custom Neon Navratri Theme
