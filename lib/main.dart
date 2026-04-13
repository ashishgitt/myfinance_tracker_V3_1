import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_zone;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'core/services/notification_service.dart';
import 'firebase_options/firebase_options.dart';
import 'providers/settings_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_savings_debt_providers.dart';
import 'providers/debt_provider.dart';
import 'providers/sub_category_provider.dart';
import 'providers/credit_card_provider.dart';
import 'providers/auth_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase Init ─────────────────────────────────────────────
  // Safely initializes Firebase. If google-services.json still has
  // placeholder values, Firebase init will fail gracefully and the
  // app continues working fully offline.
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    // Only initialize if apiKey is not a placeholder
    if (!options.apiKey.startsWith('REPLACE_WITH')) {
      await Firebase.initializeApp(options: options);
      debugPrint('✅ Firebase initialized successfully');
    } else {
      debugPrint('⚠️  Firebase skipped — replace placeholder values in '
          'lib/firebase_options/firebase_options.dart');
    }
  } catch (e) {
    debugPrint('⚠️  Firebase init failed (app still works offline): $e');
  }

  // ── Orientation ───────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // ── Timezone Init ─────────────────────────────────────────────
  tz.initializeTimeZones();
  try {
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz_zone.setLocalLocation(tz_zone.getLocation(localTz));
  } catch (_) {
    tz_zone.setLocalLocation(tz_zone.getLocation('UTC'));
  }

  // ── Notifications ─────────────────────────────────────────────
  await NotificationService.init();

  // ── Run App ───────────────────────────────────────────────────
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => SubCategoryProvider()),
        ChangeNotifierProvider(create: (_) => CreditCardProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
