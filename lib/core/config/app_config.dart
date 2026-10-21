/// Single place for brand-level settings.
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
}
