import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:jeokissan_5t_quality_management_system/firebase_options.dart';
import 'package:jeokissan_5t_quality_management_system/login.dart';
import 'package:jeokissan_5t_quality_management_system/register.dart';
import 'package:jeokissan_5t_quality_management_system/home.dart';
import 'package:jeokissan_5t_quality_management_system/splash.dart';
import 'package:jeokissan_5t_quality_management_system/locale_provider.dart';
import 'package:jeokissan_5t_quality_management_system/app_localizations.dart';
import 'package:jeokissan_5t_quality_management_system/quality_manual_search.dart'
    as quality_search;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  const aiKeyNames = [
    'OPENROUTER_API_KEY',
    'GEMINI_API_KEY',
    'GROQ_API_KEY',
  ];
  final missingAiKeys = aiKeyNames
      .where((name) => dotenv.env[name]?.trim().isNotEmpty != true)
      .toList();
  if (missingAiKeys.isNotEmpty) {
    debugPrint(
      'AI keys missing from the project-root .env asset: '
      '${missingAiKeys.join(', ')}. Check the file location and restart Flutter.',
    );
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  runApp(
    ChangeNotifierProvider.value(value: localeProvider, child: const MainApp()),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isUrdu = localeProvider.isUrdu;

    return MaterialApp(
      title: 'JeoKissan QMS',
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: isUrdu ? 'JameelNooriNastaleeq' : 'Roboto',
        textTheme: isUrdu
            ? TextTheme(
                displayLarge: const TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                ),
                displayMedium: const TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                ),
                displaySmall: const TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                ),
                headlineLarge: const TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                ),
                headlineMedium: const TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                ),
                headlineSmall: const TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                ),
                titleLarge: const TextStyle(fontFamily: 'JameelNooriNastaleeq'),
                titleMedium: const TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                ),
                titleSmall: const TextStyle(fontFamily: 'JameelNooriNastaleeq'),
                bodyLarge: const TextStyle(fontFamily: 'JameelNooriNastaleeq'),
                bodyMedium: const TextStyle(fontFamily: 'JameelNooriNastaleeq'),
                bodySmall: const TextStyle(fontFamily: 'JameelNooriNastaleeq'),
                labelLarge: const TextStyle(fontFamily: 'JameelNooriNastaleeq'),
                labelMedium: const TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                ),
                labelSmall: const TextStyle(fontFamily: 'JameelNooriNastaleeq'),
              )
            : null,
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/quality-manual': (context) =>
            const quality_search.QualityManualSearch(),
      },
    );
  }
}
