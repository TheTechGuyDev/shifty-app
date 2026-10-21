import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/data_service.dart';
import '../../core/services/pro_service.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../home/home_screen.dart';
import 'onboarding/pro_onboarding.dart';
import 'pro_shell.dart';

/// Where a signed-in person should land: customer home, pro onboarding or pro home.
Future<Widget> landingFor() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    var profile = await DataService.profile();
    final wantsPro = user?.userMetadata?['wants_pro'] == true;
    if (profile != null && wantsPro && profile['is_professional'] != true) {
      await ProService.becomeProfessional();
      profile = await DataService.profile();
    }
    if (profile != null && profile['is_professional'] == true && profile['active_mode'] == 'professional') {
      final pro = await ProService.me();
      if (pro == null || pro.status == 'draft') return const ProOnboardingFlow();
      return const ProHomeScreen();
    }
  } catch (_) {}
  return const HomeScreen();
}

/// Replace the whole stack with the right home for this account.
Future<void> goToLanding(BuildContext context) async {
  final page = await landingFor();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(appRoute(page), (_) => false);
}

/// Switch between customer and professional mode.
Future<void> switchMode(BuildContext context, String mode) async {
  try {
    if (mode == 'professional') {
      final p = await DataService.profile();
      if (p?['is_professional'] != true) await ProService.becomeProfessional();
    }
    await ProService.setMode(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_mode', mode);
    } catch (_) {}
    if (context.mounted) await goToLanding(context);
  } catch (e) {
    if (context.mounted) showAppSnack(context, 'Could not switch mode. Check your connection.', error: true);
  }
}
