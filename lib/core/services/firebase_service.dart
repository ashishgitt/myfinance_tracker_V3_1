// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  Firebase Service — Google Sign-In + Firestore Sync                        ║
// ║  Project: myfinancetracker-3ada0  (410360755841)                           ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
//
// SETUP CHECKLIST:
// [✅] firebase_core, firebase_auth, cloud_firestore, google_sign_in in pubspec.yaml
// [✅] google-services plugin applied in android/build.gradle & android/app/build.gradle
// [⬜] Replace google-services.json placeholders with real values from Firebase Console
// [⬜] Add SHA-1 fingerprint to Firebase Console (see GitHub Actions step in build.yml)
// [⬜] Enable Google Sign-In in Firebase Console → Authentication → Sign-in method
// [⬜] Create Firestore Database in Firebase Console → Firestore Database
// [⬜] Set Firestore security rules (see comments at bottom of this file)

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseService _i = FirebaseService._();
  factory FirebaseService() => _i;
  FirebaseService._();

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  bool _initialized = false;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userPhotoUrl;

  // ─── Getters ─────────────────────────────────────────────────
  bool get isInitialized => _initialized;
  bool get isLoggedIn => _userId != null;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhotoUrl => _userPhotoUrl;

  // ─── Initialize ───────────────────────────────────────────────
  /// Called from main.dart after Firebase.initializeApp().
  /// Restores any existing session silently.
  Future<void> init() async {
    try {
      // Restore existing Firebase Auth session
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId       = user.uid;
        _userName     = user.displayName;
        _userEmail    = user.email;
        _userPhotoUrl = user.photoURL;
        debugPrint('FirebaseService: restored session for ${user.email}');
      }
      _initialized = true;
    } catch (e) {
      // Graceful fallback — app works fully offline without Firebase
      debugPrint('FirebaseService.init error (non-fatal): $e');
      _initialized = true;
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────
  /// Signs in with Google → creates Firebase Auth session.
  /// Returns true on success, false on cancel or error.
  Future<bool> signInWithGoogle() async {
    try {
      // Show Google account picker
      final account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('FirebaseService: user cancelled sign-in');
        return false;
      }

      // Get Google auth tokens
      final googleAuth = await account.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('FirebaseService: missing auth tokens');
        return false;
      }

      // Exchange tokens for Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return false;

      _userId       = user.uid;
      _userName     = user.displayName;
      _userEmail    = user.email;
      _userPhotoUrl = user.photoURL;

      debugPrint('FirebaseService: signed in as ${user.email} (uid: ${user.uid})');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return false;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      _userId       = null;
      _userName     = null;
      _userEmail    = null;
      _userPhotoUrl = null;
      debugPrint('FirebaseService: signed out');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // ─── Sync to Cloud ────────────────────────────────────────────
  /// Uploads all local data to Firestore under users/{uid}/
  Future<bool> syncToCloud(Map<String, dynamic> data) async {
    if (!isLoggedIn) {
      debugPrint('FirebaseService: syncToCloud skipped — not logged in');
      return false;
    }
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(_userId);

      // Split into sub-collections for large datasets
      // Write summary doc first
      await userDoc.set({
        'last_sync': FieldValue.serverTimestamp(),
        'email': _userEmail,
        'display_name': _userName,
        'transaction_count': (data['transactions'] as List?)?.length ?? 0,
      }, SetOptions(merge: true));

      // Write transactions in batches of 400 (Firestore limit is 500/batch)
      final txns = data['transactions'] as List? ?? [];
      if (txns.isNotEmpty) {
        final batches = <WriteBatch>[];
        WriteBatch batch = firestore.batch();
        int count = 0;

        for (final txn in txns) {
          final m = Map<String, dynamic>.from(txn as Map);
          final id = m['id'] as String? ?? 'unknown';
          batch.set(userDoc.collection('transactions').doc(id), m,
              SetOptions(merge: true));
          count++;
          if (count % 400 == 0) {
            batches.add(batch);
            batch = firestore.batch();
          }
        }
        batches.add(batch);
        for (final b in batches) { await b.commit(); }
      }

      // Write categories
      final cats = data['categories'] as List? ?? [];
      if (cats.isNotEmpty) {
        final batch = firestore.batch();
        for (final cat in cats) {
          final m = Map<String, dynamic>.from(cat as Map);
          final id = m['id'] as String? ?? 'unknown';
          batch.set(userDoc.collection('categories').doc(id), m,
              SetOptions(merge: true));
        }
        await batch.commit();
      }

      debugPrint('FirebaseService: sync complete (${txns.length} transactions)');
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Firestore sync error: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Cloud sync error: $e');
      return false;
    }
  }

  // ─── Fetch from Cloud ─────────────────────────────────────────
  /// Downloads data from Firestore and returns it as a map.
  Future<Map<String, dynamic>?> fetchFromCloud() async {
    if (!isLoggedIn) return null;
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(_userId);

      // Fetch transactions sub-collection
      final txnSnap = await userDoc.collection('transactions').get();
      final transactions =
          txnSnap.docs.map((d) => d.data()).toList();

      // Fetch categories sub-collection
      final catSnap = await userDoc.collection('categories').get();
      final categories =
          catSnap.docs.map((d) => d.data()).toList();

      debugPrint(
          'FirebaseService: fetched ${transactions.length} transactions from cloud');

      return {
        'transactions': transactions,
        'categories': categories,
      };
    } on FirebaseException catch (e) {
      debugPrint('Firestore fetch error: ${e.code} — ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Cloud fetch error: $e');
      return null;
    }
  }
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║  FIRESTORE SECURITY RULES                                                  ║
// ║  Set these in Firebase Console → Firestore Database → Rules tab            ║
// ╠══════════════════════════════════════════════════════════════════════════════╣
// ║  rules_version = '2';                                                      ║
// ║  service cloud.firestore {                                                 ║
// ║    match /databases/{database}/documents {                                 ║
// ║      match /users/{userId} {                                               ║
// ║        allow read, write: if request.auth != null                          ║
// ║                           && request.auth.uid == userId;                  ║
// ║        match /{subcollection=**} {                                         ║
// ║          allow read, write: if request.auth != null                        ║
// ║                             && request.auth.uid == userId;                ║
// ║        }                                                                   ║
// ║      }                                                                     ║
// ║    }                                                                       ║
// ║  }                                                                         ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
