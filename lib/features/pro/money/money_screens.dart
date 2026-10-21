import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/models.dart';
import '../../../core/models/pro_models.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../booking/booking_widgets.dart';
import '../jobs/jobs_screens.dart';
import '../pro_widgets.dart';

/// Earnings tab: balance, chart, payouts.
class ProEarningsTab extends StatefulWidget {
  const ProEarningsTab({super.key});

  @override
  State<ProEarningsTab> createState() => _ProEarningsTabState();
}

class _ProEarningsTabState extends State<ProEarningsTab> {
  late Future<Map<String, dynamic>> _stats = ProService.stats();

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(appRoute(page));
    if (mounted) setState(() => _stats = ProService.stats());
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<Map<String, dynamic>>(
      future: _stats,
      onRetry: () => setState(() => _stats = ProService.stats()),
      builder: (context, s) {
        final daily = ((s['daily'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            setState(() => _stats = ProService.stats());
            await _stats;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 130),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(26)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available balance', style: AppTextStyles.small.copyWith(color: Colors.white60)),
                    const SizedBox(height: 4),
                    Text(money(s['balance'] as num?), style: AppTextStyles.headline1.copyWith(color: Colors.white, fontSize: 34)),
                    const SizedBox(height: 4),
                    Text('Minimum payout ${money(s['min_payout'] as num?)}', style: AppTextStyles.small.copyWith(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 18),
                    EarningsChart(daily: daily, dark: true),
                    const SizedBox(height: 18),
                    PrimaryButton(label: 'Request payout', onPressed: () => _open(RequestPayoutScreen(balance: (s['balance'] as num?) ?? 0, min: (s['min_payout'] as num?) ?? 5000))),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: StatTile(label: 'Today', value: money(s['today'] as num?), icon: Icons.today_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: StatTile(label: 'This week', value: money(s['week'] as num?), icon: Icons.date_range_rounded, color: AppColors.blue)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: StatTile(label: 'This month', value: money(s['month'] as num?), icon: Icons.calendar_month_rounded, color: AppColors.success)),
                  const SizedBox(width: 12),
                  Expanded(child: StatTile(label: 'All time (net)', value: money(s['net'] as num?), icon: Icons.savings_rounded, color: AppColors.yellow)),
                ],
              ),
              const SizedBox(height: 18),
              MenuTile(icon: Icons.receipt_long_rounded, title: 'Transactions', subtitle: 'Earnings from each job', onTap: () => _open(const TransactionsScreen())),
              MenuTile(icon: Icons.history_rounded, title: 'Payout history', subtitle: 'Money sent to your bank', onTap: () => _open(const PayoutHistoryScreen())),
              MenuTile(icon: Icons.account_balance_rounded, title: 'Payout account', subtitle: 'Your bank details', onTap: () => _open(const PayoutAccountScreen())),
              MenuTile(
                icon: Icons.percent_rounded,
                title: 'How commission works',
                subtitle: '${s['commission_pct']}% per completed job',
                onTap: () => _open(CommissionScreen(stats: s)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Transactions',
      body: AsyncView<(List<Booking>, List<Payout>)>(
        future: (() async => (await ProService.completedJobs(), await ProService.payouts()))(),
        builder: (context, data) {
          final (jobs, payouts) = data;
          final items = <(DateTime, Widget)>[
            for (final j in jobs)
              (
                j.completedAt ?? j.createdAt,
                _tx(context, Icons.south_west_rounded, AppColors.success, j.serviceName, '#${j.reference} · ${shortDate(j.completedAt ?? j.createdAt)}',
                    '+${money(j.proEarning)}', () => Navigator.of(context).push(appRoute(CompletedJobScreen(bookingId: j.id))))
              ),
            for (final p in payouts.where((p) => p.status != 'rejected'))
              (p.createdAt, _tx(context, Icons.north_east_rounded, AppColors.dark, 'Payout', '${p.bankName ?? 'Bank'} · ${shortDate(p.createdAt)}', '-${money(p.amount)}', null)),
          ]..sort((a, b) => b.$1.compareTo(a.$1));
          if (items.isEmpty) {
            return const EmptyState(icon: Icons.receipt_long_rounded, title: 'No transactions yet', message: 'Earnings appear here when you complete jobs.');
          }
          return ListView(padding: const EdgeInsets.fromLTRB(22, 16, 22, 30), children: [for (final i in items) i.$2]);
        },
      ),
    );
  }

  Widget _tx(BuildContext context, IconData icon, Color c, String title, String sub, String amount, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: c.withAlpha(25), shape: BoxShape.circle), child: Icon(icon, color: c, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headline6.copyWith(fontSize: 14)),
                    Text(sub, style: AppTextStyles.small.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Text(amount, style: AppTextStyles.smallBold.copyWith(color: c == AppColors.success ? AppColors.success : AppColors.dark, fontSize: 14)),
            ],
          ),
        ),
      );
}

/// Bank account for payouts.
class PayoutAccountScreen extends StatefulWidget {
  const PayoutAccountScreen({super.key});

  @override
  State<PayoutAccountScreen> createState() => _PayoutAccountScreenState();
}

class _PayoutAccountScreenState extends State<PayoutAccountScreen> {
  static const banks = [
    'Access Bank', 'Ecobank', 'Fidelity Bank', 'First Bank', 'FCMB', 'GTBank', 'Kuda', 'Moniepoint', 'OPay', 'PalmPay',
    'Polaris Bank', 'Stanbic IBTC', 'Sterling Bank', 'UBA', 'Union Bank', 'Wema Bank', 'Zenith Bank',
  ];
  String? _bank;
  final _number = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ProService.me().then((p) {
      if (p == null || !mounted) return;
      setState(() {
        _bank = p.bankName;
        _number.text = p.accountNumber ?? '';
        _name.text = p.accountName ?? '';
      });
    });
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _bank != null && RegExp(r'^\d{10}$').hasMatch(_number.text) && _name.text.trim().length >= 3;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ProService.update({'bank_name': _bank, 'account_number': _number.text, 'account_name': _name.text.trim()});
      if (!mounted) return;
      showAppSnack(context, 'Payout account saved');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Payout Account',
      bottom: PrimaryButton(label: 'Save', enabled: _valid, loading: _busy, onPressed: _save),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 30),
        children: [
          Text('Payouts are sent to this account. The name must match your ${'profile or business'} name.', style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: banks.contains(_bank) ? _bank : null,
            items: [for (final b in banks) DropdownMenuItem(value: b, child: Text(b))],
            onChanged: (v) => setState(() => _bank = v),
            decoration: InputDecoration(
              labelText: 'Bank',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _number,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Account number (10 digits)',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 22),
          AppTextField(label: 'Account name', controller: _name, onChanged: (_) => setState(() {})),
        ],
      ),
    );
  }
}

class RequestPayoutScreen extends StatefulWidget {
  const RequestPayoutScreen({super.key, required this.balance, required this.min});
  final num balance;
  final num min;

  @override
  State<RequestPayoutScreen> createState() => _RequestPayoutScreenState();
}

class _RequestPayoutScreenState extends State<RequestPayoutScreen> {
  late final _amount = TextEditingController(text: widget.balance >= widget.min ? widget.balance.round().toString() : '');
  ProProfile? _p;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ProService.me().then((p) {
      if (mounted) setState(() => _p = p);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  num get _v => num.tryParse(_amount.text) ?? 0;

  Future<void> _request() async {
    setState(() => _busy = true);
    try {
      await ProService.requestPayout(_v);
      if (!mounted) return;
      showAppSnack(context, 'Payout requested. It usually arrives within 24 hours.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBank = _p?.accountNumber != null;
    final ok = hasBank && _v >= widget.min && _v <= widget.balance;
    return ServiceChrome(
      title: 'Request Payout',
      bottom: hasBank || _p == null
          ? PrimaryButton(label: 'Request ${money(_v)}', enabled: ok, loading: _busy, onPressed: _request)
          : PrimaryButton(
              label: 'Add payout account',
              onPressed: () async {
                await Navigator.of(context).push(appRoute(const PayoutAccountScreen()));
                final p = await ProService.me();
                if (mounted) setState(() => _p = p);
              },
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 30),
        children: [
          Text('Available: ${money(widget.balance)}', style: AppTextStyles.paragraph.copyWith(fontSize: 15)),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.headline1.copyWith(fontSize: 36),
            decoration: InputDecoration(prefixText: '₦ ', prefixStyle: AppTextStyles.headline1.copyWith(fontSize: 36, color: AppColors.label), hintText: '0', border: InputBorder.none),
          ),
          const Divider(),
          if (_v > 0 && _v < widget.min) Text('Minimum payout is ${money(widget.min)}', style: AppTextStyles.small.copyWith(color: AppColors.warning)),
          if (_v > widget.balance) Text('More than your balance', style: AppTextStyles.small.copyWith(color: AppColors.warning)),
          const SizedBox(height: 18),
          if (_p != null)
            MenuTile(
              icon: Icons.account_balance_rounded,
              title: hasBank ? '${_p!.bankName}' : 'No payout account yet',
              subtitle: hasBank ? '•••• ${_p!.accountNumber!.substring(_p!.accountNumber!.length - 4)} · ${_p!.accountName ?? ''}' : 'Add your bank details first',
              onTap: () async {
                await Navigator.of(context).push(appRoute(const PayoutAccountScreen()));
                final p = await ProService.me();
                if (mounted) setState(() => _p = p);
              },
            ),
        ],
      ),
    );
  }
}

class PayoutHistoryScreen extends StatelessWidget {
  const PayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceChrome(
      title: 'Payout History',
      body: AsyncView<List<Payout>>(
        future: ProService.payouts(),
        builder: (context, list) => list.isEmpty
            ? const EmptyState(icon: Icons.account_balance_wallet_rounded, title: 'No payouts yet', message: 'Payouts you request show here with their status.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
                children: [
                  for (final p in list)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(money(p.amount), style: AppTextStyles.navTitle.copyWith(fontSize: 17)),
                                Text('${p.bankName ?? ''} · ${shortDate(p.createdAt)}', style: AppTextStyles.small.copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                          Builder(builder: (context) {
                            final (l, c) = switch (p.status) {
                              'paid' => ('Paid', AppColors.success),
                              'rejected' => ('Rejected', AppColors.failed),
                              _ => ('Processing', AppColors.yellow),
                            };
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: c.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                              child: Text(l, style: AppTextStyles.smallBold.copyWith(color: c, fontSize: 12)),
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class CommissionScreen extends StatelessWidget {
  const CommissionScreen({super.key, required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final pct = stats['commission_pct'];
    final example = 20000;
    final fee = (example * ((pct as num?) ?? 10) / 100).round();
    Widget q(String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headline6.copyWith(fontSize: 15)),
              const SizedBox(height: 4),
              Text(text, style: AppTextStyles.paragraph.copyWith(fontSize: 14)),
            ],
          ),
        );
    return ServiceChrome(
      title: 'Commission',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 30),
        children: [
          Center(child: Text('$pct%', style: AppTextStyles.headline1.copyWith(fontSize: 64, color: AppColors.primary))),
          Center(child: Text('per completed job', style: AppTextStyles.paragraph)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                Text('Example', style: AppTextStyles.smallBold),
                const SizedBox(height: 10),
                Row(children: [Text('Job total', style: AppTextStyles.small), const Spacer(), Text(money(example), style: AppTextStyles.smallBold)]),
                Row(children: [Text('Commission', style: AppTextStyles.small), const Spacer(), Text('- ${money(fee)}', style: AppTextStyles.smallBold)]),
                const Divider(),
                Row(children: [Text('You keep', style: AppTextStyles.headline6), const Spacer(), Text(money(example - fee), style: AppTextStyles.navTitle.copyWith(color: AppColors.success))]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          q('When is it charged?', 'Only when a job is marked completed. Declined, cancelled or unfinished jobs cost you nothing.'),
          q('Cash jobs', 'When a customer pays you cash, the commission is taken from your balance from card jobs or your next payout.'),
          q('Total paid so far', '${money(stats['commission'] as num?)} on ${money(stats['gross'] as num?)} of completed work.'),
          q('No sign-up or monthly fees', 'Creating a profile, receiving requests and sending quotes is free.'),
        ],
      ),
    );
  }
}
