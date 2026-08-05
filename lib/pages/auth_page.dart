import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _creatingAccount = false;
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_creatingAccount) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        try {
          await credential.user?.sendEmailVerification();
        } on FirebaseAuthException {
          // The verification screen lets the user resend the email.
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageFor(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();
    var sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Reset password'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _sendResetLink(
                formKey,
                emailController,
                dialogContext,
                (value) => setDialogState(() => sending = value),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: sending
                  ? null
                  : () => _sendResetLink(
                      formKey,
                      emailController,
                      dialogContext,
                      (value) => setDialogState(() => sending = value),
                    ),
              child: sending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendResetLink(
    GlobalKey<FormState> formKey,
    TextEditingController emailController,
    BuildContext dialogContext,
    ValueChanged<bool> setSending,
  ) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setSending(true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent. Check your email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!dialogContext.mounted) return;
      setSending(false);
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text(_messageFor(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      if (error.code == 'account-exists-with-different-credential') {
        final email = error.email;
        final pendingCredential = error.credential;
        if (email != null && pendingCredential != null) {
          try {
            await _linkGoogleAccount(email, pendingCredential);
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not link your Google account. Please try again.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An account already exists with this email. '
              'Please sign in with your email and password first.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageFor(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // Google sign-in was cancelled (signIn() returns null) or the platform
      // flow failed; show a message instead of failing silently.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _linkGoogleAccount(
    String email,
    AuthCredential googleCredential,
  ) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var linking = false;
    var wrongPassword = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Verify your account'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'An account already exists with this email. '
                  'Enter its password to link your Google account.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Existing password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value?.length ?? 0) < 6) {
                      return 'Enter your account password.';
                    }
                    return null;
                  },
                ),
                if (wrongPassword) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Incorrect password. Try again.',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: linking ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: linking
                  ? null
                  : () => _linkAccount(
                      formKey,
                      email,
                      googleCredential,
                      passwordController,
                      dialogContext,
                      (value) => setDialogState(() => linking = value),
                      () => setDialogState(() => wrongPassword = true),
                    ),
              child: linking
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Link accounts'),
            ),
          ],
        ),
      ),
    );
    passwordController.dispose();
  }

  Future<void> _linkAccount(
    GlobalKey<FormState> formKey,
    String email,
    AuthCredential googleCredential,
    TextEditingController passwordController,
    BuildContext dialogContext,
    ValueChanged<bool> setLinking,
    VoidCallback showWrongPassword,
  ) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setLinking(true);
    try {
      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );
      await authResult.user?.linkWithCredential(googleCredential);
      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google account linked. You can now sign in with either method.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!dialogContext.mounted) return;
      if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential' ||
          error.code == 'invalid-login-credentials') {
        showWrongPassword();
        setLinking(false);
      } else if (error.code == 'provider-already-linked') {
        Navigator.pop(dialogContext);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google account linked. You can now sign in with either method.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setLinking(false);
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(_messageFor(error)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!dialogContext.mounted) return;
      setLinking(false);
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Could not link accounts. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Use a password with at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return error.message ?? 'Could not complete authentication. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _creatingAccount ? 'Create your account' : 'Welcome back';
    final subtitle = _creatingAccount
        ? 'Start tracking your money securely.'
        : 'Sign in to access your expense tracker.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 64,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: _decoration(
                        'Email address',
                        Icons.email_outlined,
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      autofillHints: _creatingAccount
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: _decoration('Password', Icons.lock_outline)
                          .copyWith(
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                      validator: (value) {
                        if ((value?.length ?? 0) < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    if (!_creatingAccount) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _submitting
                              ? null
                              : _showForgotPasswordDialog,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _creatingAccount ? 'Create Account' : 'Sign In',
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _creatingAccount ? 'or sign up with' : 'or continue with',
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                        label: const Text('Continue with Google'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(
                              () => _creatingAccount = !_creatingAccount,
                            ),
                      child: Text(
                        _creatingAccount
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
