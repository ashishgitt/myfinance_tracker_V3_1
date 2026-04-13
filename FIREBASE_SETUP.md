# 🔥 Firebase Setup Guide for MyFinance Tracker
## Project: myfinancetracker-3ada0

---

## STEP 1 — Download the COMPLETE google-services.json

Your uploaded file was **truncated** (only 190 bytes, cut off at `"client": [`).
You need to re-download it:

1. Go to **https://console.firebase.google.com**
2. Click on your project **myfinancetracker-3ada0**
3. Click the **gear icon ⚙️** → **Project settings**
4. Scroll down to **"Your apps"** section
5. Find your Android app **(com.myfinance.tracker)**
6. Click **"google-services.json"** download button
7. Replace the file at: `android/app/google-services.json`

The complete file should be ~2-3 KB and contain `api_key`, `client_id` etc.

---

## STEP 2 — Add SHA-1 Fingerprint to Firebase (fixes Google Sign-In)

You mentioned trouble generating SHA-1. Here is the EASIEST way:

### Method A — Via GitHub Actions (Automatic)
1. Push this code to GitHub
2. Go to **Actions** tab → click the latest run
3. Click **"Extract and Print Debug Keystore SHA-1"** step
4. Copy the SHA1 value (looks like: `AA:BB:CC:DD:EE:...`)
5. Go to Firebase Console → ⚙️ Project Settings → Your apps → your Android app
6. Click **"Add fingerprint"** → paste the SHA1 → Save

### Method B — Via Android Studio
1. Open Android Studio → your project
2. Click **Gradle** panel on the right
3. Navigate: **app → Tasks → android → signingReport**
4. Double-click `signingReport`
5. Copy the **SHA1** from the output panel

---

## STEP 3 — Enable Google Sign-In in Firebase Console

1. Firebase Console → **Authentication** → **Get started**
2. Click **Google** provider
3. Toggle **Enable** → ON
4. Set **Project support email** → your Gmail
5. Click **Save**

---

## STEP 4 — Create Firestore Database

1. Firebase Console → **Firestore Database** → **Create database**
2. Choose **Start in production mode** (or test mode for 30 days)
3. Location: **asia-south1** (India) or nearest to you
4. Click **Enable**

---

## STEP 5 — Set Firestore Security Rules

1. Firebase Console → Firestore Database → **Rules** tab
2. Replace all content with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
      match /{subcollection=**} {
        allow read, write: if request.auth != null 
                           && request.auth.uid == userId;
      }
    }
  }
}
```

3. Click **Publish**

---

## What's Already Done in Code

| File | Change |
|---|---|
| `pubspec.yaml` | Added: `firebase_auth ^5.3.1`, `firebase_core ^3.6.0`, `cloud_firestore ^5.4.4`, `google_sign_in ^6.2.1` |
| `android/build.gradle` | Enabled: `classpath 'com.google.gms:google-services:4.4.2'` |
| `android/app/build.gradle` | Applied: `apply plugin: 'com.google.gms.google-services'` |
| `lib/main.dart` | Added: `Firebase.initializeApp()` with try/catch |
| `lib/core/services/firebase_service.dart` | Real Firebase Auth + Firestore sync |
| `lib/providers/auth_provider.dart` | Cloud sync/restore, error handling |
| `.github/workflows/build.yml` | SHA-1 extraction step prints in build logs |

---

## How It Works After Setup

```
User taps "Sign in with Google"
    ↓
GoogleSignIn → shows account picker
    ↓
Google returns OAuth tokens
    ↓
FirebaseAuth.signInWithCredential() → creates session
    ↓
Firebase assigns UID (stable across all devices)
    ↓
"Sync Now" → uploads transactions/categories to:
    Firestore → /users/{uid}/transactions/{txn_id}
    Firestore → /users/{uid}/categories/{cat_id}
    ↓
New device install → same Google login → same UID
    ↓
"Restore from Cloud" → downloads all data back
```

---

## Troubleshooting

| Error | Fix |
|---|---|
| `PlatformException: sign_in_failed` | SHA-1 not added to Firebase Console |
| `google-services.json not found` | File missing from `android/app/` folder |
| `FirebaseException: permission-denied` | Update Firestore rules (Step 5) |
| Sign-in crashes | `Firebase.initializeApp()` failed — check json file |
| Sync works but data doesn't restore | Firestore rules not set to allow sub-collections |
