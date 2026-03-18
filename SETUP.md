# NeighbourGo — Complete Setup & Deployment Guide

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | ≥ 3.22 | https://flutter.dev/docs/get-started/install |
| Dart SDK | ≥ 3.3 | bundled with Flutter |
| Xcode | ≥ 15 | Mac App Store |
| CocoaPods | latest | `sudo gem install cocoapods` |
| Node.js | ≥ 20 | https://nodejs.org |
| Firebase CLI | latest | `npm install -g firebase-tools` |
| FlutterFire CLI | latest | `dart pub global activate flutterfire_cli` |

---

## STEP 1 — Firebase Project

### 1.1 Create Project
1. Go to https://console.firebase.google.com
2. Click **Add project** → name it `neighbourgo-sg`
3. Enable Google Analytics → Create

### 1.2 Enable Services
In the Firebase console, enable:
- **Authentication** → Sign-in method → **Phone**
- **Firestore** → Create database → **Production mode** → Region: `asia-southeast1`
- **Storage** → Get started → Region: `asia-southeast1`
- **Cloud Messaging** (FCM) — enabled by default
- **Crashlytics** — enable in the console

### 1.3 Add iOS App
1. In Project settings → **Add app** → iOS
2. Bundle ID: `sg.neighbourgo.app`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` (do NOT commit to Git — add to `.gitignore`)

### 1.4 Add Android App
1. **Add app** → Android
2. Package name: `sg.neighbourgo.app`
3. Download `google-services.json`
4. Place it in `android/app/` (do NOT commit to Git)

---

## STEP 2 — FlutterFire Configuration

```bash
cd neighbourgo

# Login to Firebase
firebase login

# Configure Flutter app to use your Firebase project
flutterfire configure \
  --project=neighbourgo-sg \
  --platforms=ios,android
```

This generates `lib/firebase_options.dart`. Then in `main.dart`, uncomment:
```dart
// import 'firebase_options.dart';
// options: DefaultFirebaseOptions.currentPlatform,
```

---

## STEP 3 — Flutter Dependencies

```bash
# Install packages
flutter pub get

# Run code generation (Freezed + Riverpod)
dart run build_runner build --delete-conflicting-outputs
```

### iOS Setup
```bash
cd ios
pod install
cd ..
```

Add to `ios/Runner/Info.plist`:
```xml
<!-- Camera & Photo Library -->
<key>NSCameraUsageDescription</key>
<string>NeighbourGo uses your camera to upload profile and task photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>NeighbourGo needs photo access to add photos to your profile.</string>
<!-- Location -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>NeighbourGo uses your location to find nearby tasks.</string>
<!-- Microphone (for video intro) -->
<key>NSMicrophoneUsageDescription</key>
<string>NeighbourGo uses the microphone to record your profile video.</string>
```

---

## STEP 4 — Stripe Setup

1. Create account at https://stripe.com
2. Go to Developers → API keys
3. Copy **Secret key** (`sk_test_...` for dev, `sk_live_...` for prod)
4. Create a **Webhook endpoint** pointing to your Cloud Function URL
5. Copy the **Webhook signing secret** (`whsec_...`)

### Set Stripe config on Firebase Functions:
```bash
firebase functions:config:set \
  stripe.secret="sk_test_YOUR_KEY" \
  stripe.webhook="whsec_YOUR_WEBHOOK_SECRET"
```

---

## STEP 5 — Cloud Functions Deployment

```bash
cd functions
npm install

# Build TypeScript
npm run build

# Deploy all functions
firebase deploy --only functions
```

### Set production config before deploying live:
```bash
firebase functions:config:set stripe.secret="sk_live_YOUR_KEY"
```

---

## STEP 6 — Firestore & Storage Rules

```bash
# Deploy security rules
firebase deploy --only firestore:rules
firebase deploy --only storage:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes
```

---

## STEP 7 — Run iOS on Simulator / Device

```bash
# List available simulators
flutter devices

# Run on iPhone 15 Pro simulator
flutter run -d "iPhone 15 Pro"

# Run on connected real device
flutter run -d <DEVICE_ID>
```

---

## STEP 8 — TestFlight (iOS Beta)

```bash
# Build release IPA
flutter build ipa --release

# Open in Xcode
open build/ios/archive/Runner.xcarchive
```

In Xcode:
1. **Product** → **Archive**
2. **Distribute App** → **TestFlight & App Store**
3. Upload to App Store Connect
4. In App Store Connect → TestFlight → Add testers

---

## STEP 9 — Google Maps API Key

1. Go to https://console.cloud.google.com
2. Enable **Maps SDK for iOS** and **Maps SDK for Android**
3. Create API key → restrict to your app bundle IDs

Add to `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps
// In application(_:didFinishLaunchingWithOptions:):
GMSServices.provideAPIKey("YOUR_MAPS_API_KEY")
```

---

## STEP 10 — PayNow Integration

PayNow payments are handled server-side via Stripe's SGD payment methods:
1. The app calls the `createEscrowPayment` Cloud Function
2. The function creates a Stripe PaymentIntent in SGD
3. The Flutter app uses `flutter_stripe` to present the payment sheet
4. On completion, confirm via Stripe webhook → escrow is held

For PayNow QR specifically, integrate with a Singapore payment gateway such as:
- **Stripe** (supports PayNow natively as of 2023)
- **Xfers** (Singapore fintech, now Fazz)
- **OCBC / DBS PayNow API** (for bank-direct integration)

---

## Environment Variables Summary

```env
# Firebase (set in firebase.json / functions:config:set)
STRIPE_SECRET=sk_live_...
STRIPE_WEBHOOK=whsec_...

# Flutter (create lib/config/env.dart — do NOT commit)
GOOGLE_MAPS_IOS_KEY=AIza...
GOOGLE_MAPS_ANDROID_KEY=AIza...
STRIPE_PUBLISHABLE_KEY=pk_live_...
```

---

## Project Structure

```
neighbourgo/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── firebase_options.dart              # Generated by flutterfire (gitignored)
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart         # Route names, Firestore keys, limits
│   │   │   └── category_constants.dart    # 10 service categories with metadata
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Material 3 theme + design tokens
│   │   ├── router/
│   │   │   └── app_router.dart            # GoRouter with auth guard
│   │   └── widgets/
│   │       ├── app_button.dart            # Reusable buttons & chips
│   │       └── loading_overlay.dart       # Loading, skeleton, empty states
│   └── features/
│       ├── auth/                          # Phone OTP, role selection, profile setup
│       ├── profile/                       # Public profile, photo gallery, showcases
│       ├── tasks/                         # Post task (5-step), task detail
│       ├── home/                          # Main shell + bottom nav + home screen
│       └── chat/                          # (scaffold — V2)
├── functions/
│   └── src/index.ts                       # 8 Cloud Functions
├── firestore.rules                        # Firestore security rules
├── storage.rules                          # Storage security rules
└── firebase.json                          # Firebase config
```

---

## Local Development with Emulators

```bash
# Start all emulators (Auth, Firestore, Storage, Functions)
firebase emulators:start

# Point Flutter app to emulators — add to main.dart:
# FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
# FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
# FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
```

---

## Common Issues

| Issue | Fix |
|-------|-----|
| `pod install` fails | `sudo arch -x86_64 gem install ffi && pod install` |
| iOS build fails on M1 | Open Xcode → Targets → Runner → Build Settings → Excluded Architectures → add `arm64` for simulator |
| Firestore permission denied | Check `firestore.rules` and ensure user is authenticated |
| Cloud Functions cold start slow | Use `runWith({ minInstances: 1 })` for critical functions in production |
| Stripe PaymentIntent capture fails | Check that `capture_method: 'manual'` was set at creation |
| FCM tokens not received on iOS | Ensure APNs certificate is uploaded to Firebase and entitlements are set in Xcode |

---

## Recommended Next Steps After MVP

1. Add `go_router` deep links for task sharing (WhatsApp/Telegram)
2. Integrate `google_maps_flutter` for the map task view
3. Build the Bids feature (submit bid, accept bid, counter-offer)
4. Add real-time chat with Firestore subcollections
5. Integrate Stripe `flutter_stripe` payment sheet for escrow
6. Add `firebase_messaging` with APNs setup for push notifications
7. Build provider earnings dashboard with `fl_chart`
8. Add SingPass MyInfo OAuth (contact GovTech for sandbox credentials)
```
