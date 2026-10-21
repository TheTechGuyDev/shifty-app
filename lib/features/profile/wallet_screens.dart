import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../booking/booking_widgets.dart';
import '../booking/location_screens.dart';
import '../booking/payment_screens.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late Future<List<PaymentCard>> _future = DataService.cards();

  void _reload() => setState(() => _future = DataService.cards());

  Future<void> _add() async {
    await Navigator.of(context).push(appRoute(const AddCardScreen()));
    _reload();
  }

  Future<void> _menu(PaymentCard c) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetNotch(),
            if (!c.isDefault)
              ListTile(leading: const Icon(Icons.star_rounded), title: const Text('Make default'), onTap: () => Navigator.pop(context, 'default')),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.failed),
              title: const Text('Remove card', style: TextStyle(color: AppColors.failed)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    try {
      if (action == 'default') await DataService.setDefaultCard(c.id!);
      if (action == 'delete') await DataService.deleteCard(c.id!);
      if (action != null) _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Payment Methods',
      bottom: PrimaryButton(label: 'Add New Card', onPressed: _add),
      body: AsyncView<List<PaymentCard>>(
        future: _future,
        onRetry: _reload,
        builder: (context, cards) {
          if (cards.isEmpty) {
            return const EmptyState(
              icon: Icons.credit_card_rounded,
              title: 'Add your card',
              message: 'It seems like you haven’t added any credit or debit card. Add a card for faster checkout.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(30, 34, 30, 30),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _menu(cards[i]),
              child: Stack(
                children: [
                  CardVisual(card: cards[i]),
                  if (cards[i].isDefault)
                    Positioned(
                      right: 16,
                      bottom: 44,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                        child: Text('Default', style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 11)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  late Future<List<SavedAddress>> _future = DataService.addresses();

  void _reload() => setState(() => _future = DataService.addresses());

  Future<void> _add() async {
    final label = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetNotch(),
            const SizedBox(height: 8),
            ListTile(leading: const Icon(Icons.home_rounded), title: const Text('Home'), onTap: () => Navigator.pop(context, 'home')),
            ListTile(leading: const Icon(Icons.work_rounded), title: const Text('Work'), onTap: () => Navigator.pop(context, 'work')),
            ListTile(leading: const Icon(Icons.place_rounded), title: const Text('Other'), onTap: () => Navigator.pop(context, 'other')),
          ],
        ),
      ),
    );
    if (label == null || !mounted) return;
    final place = await pickPlace(context, title: 'Add ${label[0].toUpperCase()}${label.substring(1)}');
    if (place == null) return;
    try {
      await DataService.addAddress(label, place.address, place.point.latitude, place.point.longitude);
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData icon(String l) => switch (l) { 'home' => Icons.home_rounded, 'work' => Icons.work_rounded, _ => Icons.place_rounded };
    return ServiceChrome(
      title: 'Locations',
      bottom: PrimaryButton(label: 'Add Location', onPressed: _add),
      body: AsyncView<List<SavedAddress>>(
        future: _future,
        onRetry: _reload,
        builder: (context, list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.location_on_rounded,
              title: 'No saved locations',
              message: 'Save your home and work addresses for faster booking.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.border),
            itemBuilder: (context, i) {
              final a = list[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                  child: Icon(icon(a.label), color: AppColors.primary),
                ),
                title: Text('${a.label[0].toUpperCase()}${a.label.substring(1)}', style: AppTextStyles.bodyMedium),
                subtitle: Text(a.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.failed),
                  onPressed: () async {
                    await DataService.deleteAddress(a.id);
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
