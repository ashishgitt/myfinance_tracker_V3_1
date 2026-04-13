import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final _firebase = FirebaseService();

  bool _loading = false;
  bool _skipLogin = false;
  String? _lastSynced;
  String? _syncError;

  bool get loading => _loading;
  bool get isLoggedIn => _firebase.isLoggedIn;
  bool get skipLogin => _skipLogin;
  /// True when we should show the login screen
  bool get showLoginScreen => !_skipLogin && !isLoggedIn;
  String? get userName => _firebase.userName;
  String? get userEmail => _firebase.userEmail;
  String? get userPhotoUrl => _firebase.userPhotoUrl;
  String? get lastSynced => _lastSynced;
  String? get syncError => _syncError;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _skipLogin  = prefs.getBool('skip_login') ?? false;
    _lastSynced = prefs.getString('last_synced');
    // Try to restore Firebase session (silent, non-blocking)
    await _firebase.init();
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    _syncError = null;
    notifyListeners();

    final ok = await _firebase.signInWithGoogle();

    _loading = false;
    notifyListeners();
    return ok;
  }

  Future<void> skipAndContinue() async {
    _skipLogin = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_login', true);
    notifyListeners();
  }

  /// Syncs provided data to Firestore.
  /// Returns true on success.
  Future<bool> syncNow(Map<String, dynamic> data) async {
    if (!isLoggedIn) return false;
    _loading = true;
    _syncError = null;
    notifyListeners();

    final ok = await _firebase.syncToCloud(data);

    if (ok) {
      final now = DateTime.now()
          .toString()
          .substring(0, 16)
          .replaceAll('T', ' ');
      _lastSynced = now;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_synced', now);
    } else {
      _syncError = 'Sync failed. Check your internet connection.';
    }

    _loading = false;
    notifyListeners();
    return ok;
  }

  /// Fetches cloud data — call this after signing in on a new device.
  Future<Map<String, dynamic>?> fetchCloudData() async {
    if (!isLoggedIn) return null;
    _loading = true;
    notifyListeners();
    final data = await _firebase.fetchFromCloud();
    _loading = false;
    notifyListeners();
    return data;
  }

  Future<void> signOut() async {
    await _firebase.signOut();
    _skipLogin  = false;
    _lastSynced = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_login', false);
    await prefs.remove('last_synced');
    notifyListeners();
  }
}
