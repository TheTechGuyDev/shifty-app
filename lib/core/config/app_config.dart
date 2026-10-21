/// Single place for brand-level and backend settings.
/// To rename the app later, change [appName] here (plus the store listing names).
class AppConfig {
  AppConfig._();

  static const String appName = 'Shifty';
  static const String tagline = 'Every Skill. Every Service. One Platform.';

  /// Design reference size from Figma (iPhone X frame).
  static const double designWidth = 375;
  static const double designHeight = 812;

  /// On web/desktop the app is centred at phone width.
  static const double maxContentWidth = 430;

  // Supabase (publishable key is safe to ship in the app; data is protected by RLS).
  static const String supabaseUrl = 'https://trgqypwaewtpamaaixll.supabase.co';
  static const String supabaseKey = 'sb_publishable_k4ZflmSCyOLodE0xIhlUng_aVblZjB2';

  /// Where Supabase email links (confirm account, reset password) send people back to.
  static const String webUrl = 'https://thetechguydev.github.io/shifty-app/';

  /// SMS OTP needs a paid SMS provider (e.g. Termii or Twilio).
  /// While this is true, the OTP screen accepts any 4-digit code.
  static const bool otpDevMode = true;

  static const String defaultCountryCode = '+234';
}
