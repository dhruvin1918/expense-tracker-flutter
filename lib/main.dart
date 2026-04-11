import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:practice/providers/theme_provider.dart';
import 'package:practice/themes/theme.dart';
import 'package:practice/widgets/wrapper.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<void> _initFuture;
  ThemeProvider? _themeProvider;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await dotenv.load(fileName: '.env');

      if (kIsWeb) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: dotenv.env['FIREBASE_API_KEY']!,
            authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
            projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
            storageBucket:
                dotenv.env['FIREBASE_STORAGE_BUCKET']!,
            messagingSenderId:
                dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
            appId: dotenv.env['FIREBASE_APP_ID']!,
            measurementId:
                dotenv.env['FIREBASE_MEASUREMENT_ID'],
          ),
        );
      } else {
        await Firebase.initializeApp();
      }

      if (!kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
        );
      }

      final themeProvider = ThemeProvider();
      await themeProvider.loadThemePreference();
      _themeProvider = themeProvider;
    } catch (e) {
      _initError = e.toString();
      debugPrint('Firebase init failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState !=
            ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: Image(
                        image: AssetImage(
                            'assets/images/logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        }

        if (_initError != null || _themeProvider == null) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Failed to initialize app. Please restart.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        return ChangeNotifierProvider.value(
          value: _themeProvider!,
          child: const MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        title: 'Expense Tracker App',
        debugShowCheckedModeBanner: false,
        theme: lightMode,
        darkTheme: darkMode,
        themeMode: themeProvider.themeMode,
        home: const Wrapper(),
      ),
    );
  }
}
