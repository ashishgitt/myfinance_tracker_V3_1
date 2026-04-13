// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  firebase_options.dart                                                      ║
// ║                                                                             ║
// ║  INSTRUCTIONS — Replace the placeholder values below with real values       ║
// ║  from your Firebase Console. Once you have the complete google-services.json║
// ║  you can regenerate this file automatically using FlutterFire CLI:          ║
// ║                                                                             ║
// ║  1. Install FlutterFire CLI:                                                ║
// ║     dart pub global activate flutterfire_cli                               ║
// ║                                                                             ║
// ║  2. Run in your project folder:                                             ║
// ║     flutterfire configure --project=myfinancetracker-3ada0                 ║
// ║                                                                             ║
// ║  This will auto-fill all values and regenerate this file.                  ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  // ── Android Config ────────────────────────────────────────────
  // Replace the placeholder values below with real ones from Firebase Console:
  //   Firebase Console → Project Settings → Your apps → Android app
  static const FirebaseOptions android = FirebaseOptions(
    // Firebase Console → Project Settings → General → Project ID
    projectId: 'myfinancetracker-3ada0',

    // Firebase Console → Project Settings → General → Web API key
    // (also called "Browser key" in the API credentials section)
    apiKey: 'AIzaSyChXen9wdpc86BY59TPIpvFIygcMRoBxsg',

    // Firebase Console → Project Settings → Your apps → App ID
    // Format: 1:410360755841:android:xxxxxxxxxxxxxxxx
    appId: '1:410360755841:android:7f0178c590a1ca898b3f80',

    // Firebase Console → Project Settings → General → Project number
    messagingSenderId: '410360755841',

    // Firebase Console → Project Settings → General → Storage bucket
    storageBucket: 'myfinancetracker-3ada0.firebasestorage.app',

    // Firebase Console → Authentication → Settings → Authorized domains
    // → Web SDK configuration → Web client ID
    // Format: xxxxxxxx.apps.googleusercontent.com
    measurementId: null,
  );

  // ── Web Config (not needed for Android-only app) ──────────────
  static const FirebaseOptions web = FirebaseOptions(
    projectId: 'myfinancetracker-3ada0',
    apiKey: 'AIzaSyChXen9wdpc86BY59TPIpvFIygcMRoBxsg',
    appId: '1:410360755841:android:7f0178c590a1ca898b3f80',
    messagingSenderId: '410360755841',
    storageBucket: 'myfinancetracker-3ada0.firebasestorage.app',
    authDomain: 'myfinancetracker-3ada0.firebaseapp.com',
  );
}
