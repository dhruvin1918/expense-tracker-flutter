import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:practice/Toggle/navigationbar.dart';
import 'package:practice/screen/welcome_screen.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  int _retryToken = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      key: ValueKey(_retryToken),
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .error,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to connect. Please try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _retryToken++;
                        });
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Retrying connection...'),
                          ),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
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
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          final userName =
              user.displayName ?? user.email ?? "User";
          final userPhotoUrl = user.photoURL;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) =>
                FadeTransition(
                    opacity: animation, child: child),
            child: Navigationbar(
              key: const ValueKey('nav'),
              userName: userName,
              userPhotoUrl: userPhotoUrl,
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) =>
              FadeTransition(
                  opacity: animation, child: child),
          child:
              const WelcomeScreen(key: ValueKey('welcome')),
        );
      },
    );
  }
}
