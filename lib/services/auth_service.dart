import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signOut();
      } else {
        await GoogleSignIn().signOut();
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw Exception(
          'Unable to sign out. Please try again.');
    }
  }
}
