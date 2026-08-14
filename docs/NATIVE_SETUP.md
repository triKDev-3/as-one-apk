# Setup natif Flutter (Android / iOS / Desktop)

Le dossier `frontend/` contient le **code Dart** (lib/).  
Il faut générer les dossiers plateformes une fois sur ta machine.

## 1. Générer les plateformes

```bash
cd asone-app/frontend

# Si android/ ios/ web/ n'existent pas encore :
flutter create . --project-name asone_app --org services.asone

flutter pub get
```

## 2. Permissions Android

Fichier : `android/app/src/main/AndroidManifest.xml`

À l’intérieur de `<manifest>` (avant `<application>`) :

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<!-- Android ≤ 12 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
```

Pour émulateur → API en local :

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Téléphone physique (même Wi‑Fi) :

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000
```

## 3. Permissions iOS

Fichier : `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Photo de pointage pour AS ONE</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Sélection d'une photo de pointage</string>
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key>
  <true/>
</dict>
```

## 4. Builds release

```bash
# Android APK
export API_URL=https://votre-api.katabump.com
cd frontend
flutter build apk --release --dart-define=API_BASE_URL=$API_URL

# App Bundle (Play Store)
flutter build appbundle --release --dart-define=API_BASE_URL=$API_URL

# iOS (macOS + Xcode)
flutter build ios --release --dart-define=API_BASE_URL=$API_URL

# Web
flutter build web --dart-define=API_BASE_URL=$API_URL

# Desktop
flutter build windows   # ou macos / linux
```

APK généré : `frontend/build/app/outputs/flutter-apk/app-release.apk`

## 5. Backend local rapide

```bash
# Depuis asone-app/
docker compose up -d --build
# API : http://localhost:3000
# Health : http://localhost:3000/health

# Seed (dans un autre terminal, une fois l'API up)
cd backend && npm install && npm run seed
```

Ou sans Docker :

```bash
# PostgreSQL local + 
cd backend
cp .env.example .env   # éditer DATABASE_URL
npm install
npx prisma migrate dev
npm run seed
npm run start:dev
```
