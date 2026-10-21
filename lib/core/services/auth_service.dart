import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Thin wrapper over Supabase Auth so screens stay simple.
class AuthService {
  AuthService._();

  static SupabaseClient get _db => Supabase.instance.client;

  static User? get currentUser => _db.auth.currentUser;
  static bool get isSignedIn => _db.auth.currentSession != null;

  /// Returns true when the account is active immediately,
  /// false when Supabase sent a confirmation email first.
  static Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String zipCode,
    required String state,
    bool wantsPro = false,
  }) async {
    final res = await _db.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: AppConfig.webUrl,
      data: {
        'full_name': fullName.trim(),
        'phone': phone,
        'address': address.trim(),
        'zip_code': zipCode.trim(),
        'state': state,
        if (wantsPro) 'wants_pro': true,
        if (Uri.base.queryParameters['ref'] != null) 'referred_by': Uri.base.queryParameters['ref'],
      },
    );
    return res.session != null;
  }

  static Future<void> login(String email, String password) =>
      _db.auth.signInWithPassword(email: email.trim(), password: password);

  static Future<void> loginWithGoogle() =>
      _db.auth.signInWithOAuth(OAuthProvider.google, redirectTo: AppConfig.webUrl);

  static Future<void> sendPasswordReset(String email) =>
      _db.auth.resetPasswordForEmail(email.trim(), redirectTo: AppConfig.webUrl);

  static Future<void> updatePassword(String password) =>
      _db.auth.updateUser(UserAttributes(password: password));

  static Future<void> logout() => _db.auth.signOut();

  static Future<Map<String, dynamic>?> myProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return _db.from('profiles').select().eq('id', user.id).maybeSingle();
  }

  /// Human-friendly message for Supabase errors.
  static String friendlyError(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login')) return 'Incorrect email or password.';
      if (m.contains('already registered')) return 'An account with this email already exists.';
      if (m.contains('email not confirmed')) return 'Please confirm your email first. Check your inbox.';
      if (m.contains('rate limit')) return 'Too many attempts. Please wait a minute and try again.';
      if (m.contains('provider is not enabled')) return 'Google sign-in is not switched on yet.';
      return e.message;
    }
    return 'Something went wrong. Check your connection and try again.';
  }
}
