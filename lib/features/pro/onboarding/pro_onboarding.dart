import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/models.dart';
import '../../../core/models/pro_models.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/geo_service.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/service_icons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/register_screen.dart';
import '../../booking/booking_widgets.dart';
import '../../booking/location_screens.dart';
import '../pro_router.dart';
import '../pro_widgets.dart';

/// Step 0 of sign-up: what do you want to do?
class RoleChoiceScreen extends StatefulWidget {
  const RoleChoiceScreen({super.key, required this.phone});
  final String phone;

  @override
  State<RoleChoiceScreen> createState() => _RoleChoiceScreenState();
}

class _RoleChoiceScreenState extends State<RoleChoiceScreen> {
  bool? _pro;

  @override
  Widget build(BuildContext context) {
    Widget card(bool pro, String emoji, String title, String text) {
      final sel = _pro == pro;
      return GestureDetector(
        onTap: () => setState(() => _pro = pro),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFFFF4EE) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: pro ? const Color(0xFFE8F4FB) : const Color(0xFFFDEDE1), borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.navTitle.copyWith(fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(text, style: AppTextStyles.small.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: sel ? AppColors.primary : const Color(0xFFC4C4C4), width: 1.5),
                ),
                child: sel ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
              ),
            ],
          ),
        ),
      );
    }

    return AuthScaffold(
      children: [
        const AuthHeading(title: 'How will you use the app?', subtitle: 'You can switch any time\nfrom your profile.'),
        const SizedBox(height: 34),
        card(false, '🏡', 'I need a service', 'Book cleaners, movers, plumbers, tutors and more.'),
        const SizedBox(height: 16),
        card(true, '🧰', 'I offer a service', 'Get jobs, send quotes, manage bookings and earnings.'),
        const SizedBox(height: 34),
        PrimaryButton(
          label: 'Continue',
          enabled: _pro != null,
          onPressed: () => Navigator.of(context).pushReplacement(appRoute(RegisterScreen(phone: widget.phone, wantsPro: _pro!))),
        ),
      ],
    );
  }
}

/// Entry point once someone has chosen to work as a professional.
class ProOnboardingFlow extends StatelessWidget {
  const ProOnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) => const ProIntroScreen();
}

/// Shared layout for onboarding steps: progress bar, title, body, Next.
class OnboardingStep extends StatelessWidget {
  const OnboardingStep({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onNext,
    this.nextLabel = 'Continue',
    this.canNext = true,
    this.busy = false,
    this.editing = false,
    this.chromeTitle = 'Become a Professional',
  });

  static const total = 9;

  final int step;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback onNext;
  final String nextLabel;
  final bool canNext;
  final bool busy;
  final bool editing;
  final String chromeTitle;

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: editing ? chromeTitle : 'Step $step of $total',
      bottom: PrimaryButton(label: editing ? 'Save' : nextLabel, enabled: canNext, loading: busy, onPressed: onNext),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 30),
        children: [
          if (!editing)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: (step - 1) / total, end: step / total),
                duration: const Duration(milliseconds: 500),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF0F0F0),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(title, style: AppTextStyles.headline1.copyWith(fontSize: 30)),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 26),
          ...children,
        ],
      ),
    );
  }
}

void _next(BuildContext context, Widget page, bool editing) {
  if (editing) {
    Navigator.pop(context, true);
  } else {
    Navigator.of(context).push(appRoute(page));
  }
}

// 1 ─────────────────────────────────────────────────────────────
class ProIntroScreen extends StatelessWidget {
  const ProIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget point(IconData icon, Color c, String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: Color.lerp(Colors.white, c, 0.15), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: c),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.navTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(text, style: AppTextStyles.small.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );

    return ServiceChrome(
      title: 'Become a Professional',
      bottom: PrimaryButton(label: 'Get Started', onPressed: () => Navigator.of(context).push(appRoute(const AccountTypeScreen()))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 34, 26, 30),
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: const Color(0xFFFFF1EA), borderRadius: BorderRadius.circular(40)),
              alignment: Alignment.center,
              child: const Text('🧰', style: TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Grow your business with us', textAlign: TextAlign.center, style: AppTextStyles.headline1.copyWith(fontSize: 28)),
          const SizedBox(height: 10),
          Text('Set up takes about 5 minutes. Here is how it works:', textAlign: TextAlign.center, style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 30),
          point(Icons.badge_rounded, AppColors.blue, '1. Create your profile', 'Tell customers who you are and the services you offer, with your prices.'),
          point(Icons.verified_user_rounded, AppColors.success, '2. Get verified', 'Upload a valid ID and any certificates. Verified pros get more jobs.'),
          point(Icons.notifications_active_rounded, AppColors.primary, '3. Receive jobs', 'Accept requests near you or send a quote. Chat with customers in the app.'),
          point(Icons.account_balance_wallet_rounded, AppColors.yellow, '4. Get paid', 'Track earnings and request payouts to your bank account.'),
        ],
      ),
    );
  }
}

// 2 ─────────────────────────────────────────────────────────────
class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  String _type = 'individual';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ProService.me().then((p) {
      if (p != null && mounted) setState(() => _type = p.accountType);
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ProService.update({'account_type': _type});
      if (mounted) _next(context, const BusinessDetailsScreen(), false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget option(String key, IconData icon, String title, String text) {
      final sel = _type == key;
      return GestureDetector(
        onTap: () => setState(() => _type = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFFFF4EE) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 34, color: sel ? AppColors.primary : AppColors.dark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.navTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(text, style: AppTextStyles.small.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return OnboardingStep(
      step: 1,
      title: 'Account type',
      subtitle: 'Are you working on your own or as a registered company?',
      busy: _busy,
      onNext: _save,
      children: [
        option('individual', Icons.person_rounded, 'Individual', 'Artisan, freelancer or independent professional.'),
        option('company', Icons.business_rounded, 'Company', 'Registered business with staff or teams. You can add team members later.'),
      ],
    );
  }
}

// 3 ─────────────────────────────────────────────────────────────
class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key, this.editing = false});
  final bool editing;

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  int _years = 1;
  bool _company = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ProService.me().then((p) {
      if (p == null || !mounted) return;
      setState(() {
        _name.text = p.businessName ?? '';
        _bio.text = p.bio ?? '';
        _years = p.years == 0 ? 1 : p.years;
        _company = p.accountType == 'company';
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ProService.update({'business_name': _name.text.trim(), 'bio': _bio.text.trim(), 'years_experience': _years});
      if (mounted) _next(context, const ChooseServicesScreen(), widget.editing);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStep(
      step: 2,
      editing: widget.editing,
      chromeTitle: 'Business Details',
      title: _company ? 'Business details' : 'About you',
      subtitle: 'This is what customers see on your profile.',
      busy: _busy,
      canNext: _name.text.trim().length >= 2 && _bio.text.trim().length >= 20,
      onNext: _save,
      children: [
        AppTextField(label: _company ? 'Business name' : 'Display name', controller: _name, onChanged: (_) => setState(() {})),
        const SizedBox(height: 22),
        TextField(
          controller: _bio,
          maxLines: 5,
          maxLength: 400,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'About your work',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: AppTextStyles.label,
            hintText: 'e.g. Certified electrician with 8 years of house wiring, solar and inverter installs across Lagos.',
            hintStyle: AppTextStyles.small.copyWith(color: AppColors.label),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFBDBDC2))),
          ),
        ),
        if (_bio.text.trim().isNotEmpty && _bio.text.trim().length < 20)
          Text('Write at least 20 characters', style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.warning)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text('Years of experience', style: AppTextStyles.bodyMedium)),
            Counter(value: _years, min: 0, max: 60, onChanged: (v) => setState(() => _years = v)),
          ],
        ),
      ],
    );
  }
}

// 4 ─────────────────────────────────────────────────────────────
class ChooseServicesScreen extends StatefulWidget {
  const ChooseServicesScreen({super.key, this.editing = false});
  final bool editing;

  @override
  State<ChooseServicesScreen> createState() => _ChooseServicesScreenState();
}

class _ChooseServicesScreenState extends State<ChooseServicesScreen> {
  late final Future<List<ServiceCategory>> _cats = DataService.categories();
  final Set<String> _selected = {};
  List<OfferedService> _existing = [];
  String _q = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ProService.services().then((s) {
      if (!mounted) return;
      setState(() {
        _existing = s;
        _selected.addAll(s.map((e) => e.categoryId));
      });
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final list = [
        for (final id in _selected)
          _existing.firstWhere((e) => e.categoryId == id, orElse: () => OfferedService(id: null, categoryId: id, pricingType: 'fixed'))
      ];
      await ProService.saveServices(list);
      if (!mounted) return;
      if (widget.editing) {
        await Navigator.of(context).push(appRoute(const PricingScreen(editing: true)));
        if (mounted) Navigator.pop(context, true);
      } else {
        _next(context, const PricingScreen(), false);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStep(
      step: 3,
      editing: widget.editing,
      chromeTitle: 'My Services',
      title: 'Your services',
      subtitle: 'Pick up to 10 services you offer. You’ll set prices next.',
      busy: _busy,
      canNext: _selected.isNotEmpty,
      nextLabel: 'Continue (${_selected.length} selected)',
      onNext: _save,
      children: [
        TextField(
          onChanged: (v) => setState(() => _q = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search services',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: AppColors.field,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        AsyncView<List<ServiceCategory>>(
          future: _cats,
          builder: (context, all) {
            final groups = all.where((c) => c.isGroup).toList();
            return Column(
              children: [
                for (final g in groups)
                  Builder(builder: (context) {
                    final kids = all.where((c) => c.parentId == g.id && (_q.isEmpty || c.name.toLowerCase().contains(_q))).toList();
                    if (kids.isEmpty) return const SizedBox.shrink();
                    final count = kids.where((k) => _selected.contains(k.id)).length;
                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: _q.isNotEmpty || count > 0,
                        tilePadding: EdgeInsets.zero,
                        leading: Icon(iconFor(g.icon), color: g.color),
                        title: Text(g.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                        subtitle: count > 0 ? Text('$count selected', style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.primary)) : null,
                        children: [
                          for (final s in kids)
                            CheckboxListTile(
                              value: _selected.contains(s.id),
                              activeColor: AppColors.primary,
                              contentPadding: const EdgeInsets.only(left: 8),
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(s.name, style: AppTextStyles.small.copyWith(color: AppColors.dark, fontSize: 15)),
                              secondary: s.requiresVerification
                                  ? const Tooltip(message: 'Needs a checked qualification', child: Icon(Icons.verified_rounded, color: AppColors.success, size: 18))
                                  : null,
                              onChanged: (v) {
                                if (v == true && _selected.length >= 10) {
                                  showAppSnack(context, 'You can choose up to 10 services');
                                  return;
                                }
                                setState(() => v == true ? _selected.add(s.id) : _selected.remove(s.id));
                              },
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ],
    );
  }
}

// 5 ─────────────────────────────────────────────────────────────
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key, this.editing = false});
  final bool editing;

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  List<OfferedService>? _list;
  Map<String, ServiceCategory> _cats = {};
  final _ctrls = <String, TextEditingController>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ProService.services();
    final c = await DataService.categories();
    if (!mounted) return;
    setState(() {
      _list = s;
      _cats = {for (final x in c) x.id: x};
      for (final x in s) {
        _ctrls[x.categoryId] = TextEditingController(text: x.price == null ? '' : x.price!.round().toString());
      }
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => (_list ?? []).every((s) => s.pricingType == 'quote' || (num.tryParse(_ctrls[s.categoryId]!.text) ?? 0) > 0);

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      for (final s in _list!) {
        s.price = num.tryParse(_ctrls[s.categoryId]!.text);
      }
      await ProService.saveServices(_list!);
      if (mounted) _next(context, const ServiceAreaScreen(), widget.editing);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const types = {'fixed': 'Fixed', 'hourly': 'Per hour', 'starting': 'From', 'quote': 'Quote'};
    return OnboardingStep(
      step: 4,
      editing: widget.editing,
      chromeTitle: 'Prices',
      title: 'Set your prices',
      subtitle: 'Choose how you charge for each service. “Quote” means you send a price after seeing the job.',
      busy: _busy,
      canNext: _list != null && _valid,
      onNext: _save,
      children: [
        if (_list == null)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else
          for (final s in _list!)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(iconFor(_cats[s.categoryId]?.icon ?? 'build'), color: _cats[s.categoryId]?.color ?? AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_cats[s.categoryId]?.name ?? 'Service', style: AppTextStyles.headline6.copyWith(fontSize: 15))),
                      Switch(
                        value: s.isActive,
                        activeTrackColor: AppColors.primary,
                        activeColor: Colors.white,
                        onChanged: (v) => setState(() => s.isActive = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final e in types.entries)
                        ChoiceChip(
                          label: Text(e.value),
                          selected: s.pricingType == e.key,
                          selectedColor: const Color(0xFFFFE6D6),
                          labelStyle: AppTextStyles.small.copyWith(color: s.pricingType == e.key ? AppColors.primary : AppColors.dark, fontWeight: FontWeight.w600),
                          side: BorderSide(color: s.pricingType == e.key ? AppColors.primary : AppColors.border),
                          onSelected: (_) => setState(() => s.pricingType = e.key),
                        ),
                    ],
                  ),
                  if (s.pricingType != 'quote') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ctrls[s.categoryId],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixText: '₦ ',
                        suffixText: s.pricingType == 'hourly' ? '/ hour' : null,
                        hintText: 'Amount',
                        filled: true,
                        fillColor: AppColors.field,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}

// 6 ─────────────────────────────────────────────────────────────
class ServiceAreaScreen extends StatefulWidget {
  const ServiceAreaScreen({super.key, this.editing = false});
  final bool editing;

  @override
  State<ServiceAreaScreen> createState() => _ServiceAreaScreenState();
}

class _ServiceAreaScreenState extends State<ServiceAreaScreen> {
  Place? _base;
  double _radius = 15;
  bool _busy = false;
  final _map = MapController();

  @override
  void initState() {
    super.initState();
    ProService.me().then((p) {
      if (p == null || !mounted) return;
      setState(() {
        _radius = p.radiusKm.toDouble();
        if (p.baseLat != null) _base = Place(p.baseAddress ?? '', LatLng(p.baseLat!, p.baseLng!));
      });
    });
  }

  Future<void> _pick() async {
    final p = await pickPlace(context, title: 'Your base location', initial: _base);
    if (p == null) return;
    setState(() => _base = p);
    try {
      _map.move(p.point, _zoom);
    } catch (_) {}
  }

  double get _zoom => _radius <= 5 ? 12 : (_radius <= 15 ? 10.5 : (_radius <= 40 ? 9 : 7.5));

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ProService.update({
        'base_address': _base!.address,
        'base_lat': _base!.point.latitude,
        'base_lng': _base!.point.longitude,
        'radius_km': _radius.round(),
      });
      if (mounted) _next(context, const WorkingHoursScreen(), widget.editing);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _base?.point ?? GeoService.fallback;
    return OnboardingStep(
      step: 5,
      editing: widget.editing,
      chromeTitle: 'Service Area',
      title: 'Where do you work?',
      subtitle: 'Set your base and how far you travel. You’ll only get requests inside this area.',
      busy: _busy,
      canNext: _base != null,
      onNext: _save,
      children: [
        GestureDetector(
          onTap: _pick,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_base?.address ?? 'Choose your base location',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14, color: _base == null ? AppColors.label : AppColors.dark)),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AppMap(
              key: ValueKey('${center.latitude}${_radius.round()}'),
              center: center,
              zoom: _zoom,
              controller: _map,
              interactive: false,
              markers: [Marker(point: center, width: 40, height: 40, child: const MapPin(color: AppColors.primary, size: 40))],
              circles: [
                CircleMarker(
                  point: center,
                  radius: _radius * 1000,
                  useRadiusInMeter: true,
                  color: AppColors.primary.withAlpha(40),
                  borderColor: AppColors.primary,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Travel distance', style: AppTextStyles.bodyMedium),
            const Spacer(),
            Text('${_radius.round()} km', style: AppTextStyles.navTitle.copyWith(color: AppColors.primary)),
          ],
        ),
        Slider(
          value: _radius,
          min: 2,
          max: 100,
          divisions: 49,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _radius = v),
        ),
      ],
    );
  }
}

// 7 ─────────────────────────────────────────────────────────────
class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key, this.editing = false});
  final bool editing;

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  List<DayHours>? _hours;
  bool _busy = false;
  static const _names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    ProService.hours().then((h) {
      if (mounted) setState(() => _hours = h);
    });
  }

  Future<void> _time(DayHours h, bool start) async {
    final parts = (start ? h.start : h.end).split(':');
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
    if (t == null) return;
    final v = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() => start ? h.start = v : h.end = v);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ProService.saveHours(_hours!);
      if (mounted) _next(context, const IdentityScreen(), widget.editing);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmt(String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    return '${h == 0 ? 12 : (h > 12 ? h - 12 : h)}:${p[1]} ${h < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStep(
      step: 6,
      editing: widget.editing,
      chromeTitle: 'Working Hours',
      title: 'Working hours',
      subtitle: 'When can customers book you? You can block specific dates in your calendar later.',
      busy: _busy,
      canNext: _hours != null && _hours!.any((h) => h.enabled),
      onNext: _save,
      children: [
        if (_hours == null)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else
          for (final h in _hours!)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Switch(value: h.enabled, activeTrackColor: AppColors.primary, activeColor: Colors.white, onChanged: (v) => setState(() => h.enabled = v)),
                  const SizedBox(width: 6),
                  SizedBox(width: 92, child: Text(_names[h.weekday - 1], style: AppTextStyles.bodyMedium.copyWith(fontSize: 14))),
                  if (h.enabled) ...[
                    _timeChip(_fmt(h.start), () => _time(h, true)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('–')),
                    _timeChip(_fmt(h.end), () => _time(h, false)),
                  ] else
                    Text('Closed', style: AppTextStyles.small.copyWith(color: AppColors.label)),
                ],
              ),
            ),
      ],
    );
  }

  Widget _timeChip(String t, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(10)),
          child: Text(t, style: AppTextStyles.small.copyWith(color: AppColors.dark, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      );
}

/// Picks a clear photo of a document. Returns (bytes, extension).
Future<(Uint8List, String)?> pickDocumentFile(BuildContext context) async {
  final f = await pickPhoto(context);
  if (f == null) return null;
  if (f.$1.length > 10 * 1024 * 1024) {
    if (context.mounted) showAppSnack(context, 'File must be 10 MB or smaller', error: true);
    return null;
  }
  return f;
}

class _DocList extends StatelessWidget {
  const _DocList({required this.docs, required this.onDelete, required this.labels});
  final List<VerificationDoc> docs;
  final Map<String, String> labels;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final d in docs)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(d.status == 'approved' ? Icons.verified_rounded : Icons.description_rounded,
                    color: d.status == 'approved' ? AppColors.success : (d.status == 'rejected' ? AppColors.failed : AppColors.dark)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title ?? labels[d.kind] ?? d.kind, style: AppTextStyles.headline6.copyWith(fontSize: 14)),
                      Text(
                        switch (d.status) { 'approved' => 'Approved', 'rejected' => 'Rejected${d.note == null ? '' : ': ${d.note}'}', _ => 'Under review' },
                        style: AppTextStyles.small.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (d.status == 'pending')
                  IconButton(onPressed: () => onDelete(d.id), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.failed)),
              ],
            ),
          ),
      ],
    );
  }
}

// 8 ─────────────────────────────────────────────────────────────
class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key, this.editing = false});
  final bool editing;

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  static const _kinds = {
    'nin': 'NIN slip',
    'voters_card': 'Voter’s card',
    'drivers_license': 'Driver’s licence',
    'passport': 'International passport',
    'id_card': 'Other government ID',
    'cac': 'CAC certificate (companies)',
  };
  String _kind = 'nin';
  List<VerificationDoc> _docs = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await ProService.documents();
    if (mounted) setState(() => _docs = d.where((x) => _kinds.containsKey(x.kind)).toList());
  }

  Future<void> _upload() async {
    final f = await pickDocumentFile(context);
    if (f == null) return;
    setState(() => _busy = true);
    try {
      await ProService.uploadDocument(_kind, _kinds[_kind]!, f.$1, f.$2);
      await _load();
      if (mounted) showAppSnack(context, 'Uploaded');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStep(
      step: 7,
      editing: widget.editing,
      chromeTitle: 'Identity',
      title: 'Verify your identity',
      subtitle: 'Upload a clear photo of a valid ID. Only our verification team can see it. It is never shown on your profile.',
      canNext: _docs.isNotEmpty,
      onNext: () => _next(context, const QualificationsScreen(), widget.editing),
      children: [
        Text('ID type', style: AppTextStyles.small.copyWith(fontSize: 12, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in _kinds.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _kind == e.key,
                selectedColor: const Color(0xFFFFE6D6),
                side: BorderSide(color: _kind == e.key ? AppColors.primary : AppColors.border),
                onSelected: (_) => setState(() => _kind = e.key),
              ),
          ],
        ),
        const SizedBox(height: 20),
        OutlineButtonX(label: _busy ? 'Uploading…' : 'Upload ${_kinds[_kind]}', onPressed: _busy ? () {} : _upload),
        const SizedBox(height: 20),
        _DocList(
          docs: _docs,
          labels: _kinds,
          onDelete: (id) async {
            await ProService.deleteDocument(id);
            _load();
          },
        ),
      ],
    );
  }
}

// 9 ─────────────────────────────────────────────────────────────
class QualificationsScreen extends StatefulWidget {
  const QualificationsScreen({super.key, this.editing = false});
  final bool editing;

  @override
  State<QualificationsScreen> createState() => _QualificationsScreenState();
}

class _QualificationsScreenState extends State<QualificationsScreen> {
  final _title = TextEditingController();
  List<VerificationDoc> _docs = [];
  List<String> _needs = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await ProService.documents();
    final s = await ProService.services();
    final cats = await DataService.categories();
    final need = [for (final x in s) ...cats.where((c) => c.id == x.categoryId && c.requiresVerification).map((c) => c.name)];
    if (mounted) {
      setState(() {
        _docs = d.where((x) => x.kind == 'certificate' || x.kind == 'license').toList();
        _needs = need;
      });
    }
  }

  Future<void> _upload() async {
    if (_title.text.trim().length < 3) {
      showAppSnack(context, 'Name the certificate first, e.g. “COREN licence”', error: true);
      return;
    }
    final f = await pickDocumentFile(context);
    if (f == null) return;
    setState(() => _busy = true);
    try {
      await ProService.uploadDocument('certificate', _title.text.trim(), f.$1, f.$2);
      _title.clear();
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStep(
      step: 8,
      editing: widget.editing,
      chromeTitle: 'Qualifications',
      title: 'Certificates & licences',
      subtitle: 'Optional for most services. Pros with checked qualifications get a badge and more jobs.',
      canNext: _needs.isEmpty || _docs.isNotEmpty,
      nextLabel: _docs.isEmpty && _needs.isEmpty ? 'Skip for now' : 'Continue',
      onNext: () => _next(context, const ApplicationStatusScreen(), widget.editing),
      children: [
        if (_needs.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(14)),
            child: Text('Required for: ${_needs.join(', ')}. You can’t take these jobs until a certificate is approved.',
                style: AppTextStyles.small.copyWith(color: const Color(0xFF8A5A00))),
          ),
        AppTextField(label: 'Certificate name', controller: _title),
        const SizedBox(height: 14),
        OutlineButtonX(label: _busy ? 'Uploading…' : 'Upload certificate', onPressed: _busy ? () {} : _upload),
        const SizedBox(height: 20),
        _DocList(
          docs: _docs,
          labels: const {'certificate': 'Certificate', 'license': 'Licence'},
          onDelete: (id) async {
            await ProService.deleteDocument(id);
            _load();
          },
        ),
      ],
    );
  }
}

// 10 ────────────────────────────────────────────────────────────
class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  ProProfile? _p;
  List<VerificationDoc> _docs = [];
  bool _testApprove = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load(submit: true);
  }

  Future<void> _load({bool submit = false}) async {
    try {
      if (submit) await ProService.submitApplication();
      final p = await ProService.me();
      final d = await ProService.documents();
      final t = await ProService.selfApprovalAllowed();
      if (mounted) {
        setState(() {
          _p = p;
          _docs = d;
          _testApprove = t;
        });
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ProService.selfApprove();
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final approved = p?.approved ?? false;
    final hasId = _docs.any((d) => !['certificate', 'license'].contains(d.kind));
    final hasCert = _docs.any((d) => ['certificate', 'license'].contains(d.kind));

    Widget level(bool done, String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: done ? AppColors.success : AppColors.label),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headline6.copyWith(fontSize: 14)),
                    Text(text, style: AppTextStyles.small.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );

    return ServiceChrome(
      title: 'Application Status',
      bottom: approved
          ? PrimaryButton(label: 'Go to my dashboard', onPressed: () => goToLanding(context))
          : OutlineButtonX(label: 'Check again', onPressed: () => _load()),
      body: p == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(26, 34, 26, 30),
              children: [
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(color: approved ? const Color(0xFFE2F5E6) : const Color(0xFFFFF4E5), shape: BoxShape.circle),
                    child: Icon(approved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                        size: 54, color: approved ? AppColors.success : AppColors.yellow),
                  ),
                ),
                const SizedBox(height: 20),
                Text(approved ? 'You’re approved!' : (p.status == 'rejected' ? 'Changes needed' : 'Application under review'),
                    textAlign: TextAlign.center, style: AppTextStyles.headline1.copyWith(fontSize: 28)),
                const SizedBox(height: 10),
                Text(
                  approved
                      ? 'Go online from your dashboard to start receiving job requests.'
                      : p.status == 'rejected'
                          ? (p.statusNote ?? 'Please update your documents and resubmit.')
                          : 'Our team checks applications within 24 hours. We’ll notify you as soon as you’re approved.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.paragraph.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 30),
                level(true, 'Phone verified', 'Your phone number is confirmed.'),
                level(hasId && (approved || p.level >= 2), 'Identity checked', hasId ? 'ID uploaded' : 'Upload an ID to continue'),
                level(hasCert && approved, 'Qualifications checked', hasCert ? 'Certificate uploaded' : 'Optional for most services'),
                if (!approved && _testApprove) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Text('TEST MODE', style: AppTextStyles.smallBold.copyWith(fontSize: 11, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Text('Approve yourself to test the professional app. This button is removed when the admin dashboard goes live.',
                            textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(fontSize: 12)),
                        const SizedBox(height: 12),
                        PrimaryButton(label: 'Approve me (test)', color: AppColors.dark, loading: _busy, onPressed: _approve),
                      ],
                    ),
                  ),
                ],
                if (!approved) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => switchMode(context, 'customer'),
                    child: Text('Use the app as a customer meanwhile', style: AppTextStyles.smallBold.copyWith(color: AppColors.primary)),
                  ),
                ],
              ],
            ),
    );
  }
}
