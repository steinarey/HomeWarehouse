import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/config/router.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/domain/providers/theme_provider.dart';
import 'package:mobile/domain/providers/locale_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/domain/services/notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'check_notifications') {
      await NotificationService().init();
      await NotificationService().checkAndShowNotifications();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: !kReleaseMode,
  );

  await Workmanager().registerPeriodicTask(
    "1",
    "check_notifications",
    frequency: const Duration(hours: 24),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // Check immediately on startup
  NotificationService().checkAndShowNotifications();

  final prefs = await SharedPreferences.getInstance();

  // One-shot cleanup: pre-auth versions stored the chosen user in prefs.
  // Identity now comes from the JWT, so the key is orphaned and can go.
  await prefs.remove('active_user_id');

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Home Warehouse',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('is')],
      routerConfig: router,
    );
  }
}
