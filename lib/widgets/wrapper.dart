import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:practice/screen/welcome_screen.dart';
import 'package:practice/Toggle/navigationbar.dart';

class Wrapper extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;


  const Wrapper({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong!')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          final userName = user.displayName ?? user.email ?? "Guest";
          final userPhotoUrl = user.photoURL;

          return Navigationbar(
            userName: userName,
            userPhotoUrl: userPhotoUrl,
            isDarkMode: isDarkMode,
            onThemeChanged: onThemeChanged,
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}

Future<void> signOut() async {
  if (kIsWeb) {
    // On Web → only FirebaseAuth is needed
    await FirebaseAuth.instance.signOut();
  } else {
    // On Android/iOS → sign out from both GoogleSignIn and FirebaseAuth
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }
}