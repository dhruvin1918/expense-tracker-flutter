import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:practice/themes/theme.dart';
import 'package:practice/widgets/wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Firebase init for Web
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAsUWuEHcGkbo3bc7ws3bOq0uByOpxIR2k",
        authDomain: "expense-e451a.firebaseapp.com",
        projectId: "expense-e451a",
        storageBucket: "expense-e451a.appspot.com",
        messagingSenderId: "622099091971",
        appId: "1:622099091971:web:341ac9e225686942177436",
        measurementId: "G-XSDZDL9BRF",
      ),
    );
  } else {
    // Mobile (Android/iOS) auto-uses google-services.json / plist
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: _themeMode,
      home: Wrapper(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}
