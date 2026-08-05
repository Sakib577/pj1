import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Signs out of Firebase AND Google so the next "Continue with Google" tap
/// always shows the account chooser instead of silently restoring the last
/// signed-in Google account.
Future<void> signOut() async {
  try {
    await GoogleSignIn().signOut();
  } catch (_) {
    // Best-effort; Firebase sign-out still completes.
  }
  await FirebaseAuth.instance.signOut();
}
