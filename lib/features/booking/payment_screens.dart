import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/services/data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import 'booking_widgets.dart';

String cardBrand(String digits) {
  if (digits.startsWith('4')) return 'visa';
  if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) return 'mastercard';
  if (RegExp(r'^(5060|5061|5078|5079|6500)').hasMatch(digits)) return 'verve';
  if (RegExp(r'^3[47]').hasMatch(digits)) return 'amex';
  return 'card';
}

bool luhnValid(String digits) {
  if (digits.length < 12 || digits.length > 19) return false;
  var sum = 0;
  var alt = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.parse(digits[i]);
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alt = !alt;
  }
  return sum % 10 == 0;
}

/// Small brand mark (drawn, so no logo files are needed).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.brand, this.size = 1});
  final String brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (brand) {
      case 'mastercard':
        return SizedBox(
          width: 46 * size,
          height: 30 * size,
          child: Stack(
            children: [
              Positioned(left: 0, child: _dot(const Color(0xFFEB001B))),
              Positioned(left: 16 * size, child: _dot(const Color(0xFFF79E1B).withAlpha(230))),
            ],
          ),
        );
      default:
        return Text(
          brand == 'card' ? 'CARD' : brand.toUpperCase(),
          style: AppTextStyles.headline6.copyWith(
            color: Colors.white,
            fontSize: 16 * size,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        );
    }
  }

  Widget _dot(Color c) => Container(width: 30 * size, height: 30 * size, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

/// Card visual from the "My Cards" design (blue to brown gradient, chip, masked number).
class CardVisual extends StatelessWidget {
  const CardVisual({super.key, required this.card, this.selected = false});
  final PaymentCard card;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 158,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF2C5C86), Color(0xFF6A3A21)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2.5),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -40,
            child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(14))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BrandMark(brand: card.brand),
                    const Spacer(),
                    Container(
                      width: 34,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(colors: [Color(0xFFE9D38D), Color(0xFFB8963A)]),
                      ),
                      child: CustomPaint(painter: _ChipLines()),
                    ),
                  ],
                ),
                const Spacer(),
                Text('XXXX - XXXX - XXXX - ${card.last4}',
                    style: AppTextStyles.headline6.copyWith(color: Colors.white, fontSize: 15, letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(card.holder,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(color: Colors.white54, fontSize: 12)),
                    ),
                    Text('Valid Thru  ${card.expiry}', style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0x55704F10)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(s.width / 3, 0), Offset(s.width / 3, s.height), p);
    canvas.drawLine(Offset(s.width * 2 / 3, 0), Offset(s.width * 2 / 3, s.height), p);
    canvas.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// "My Cards" bottom sheet. Returns the chosen card (may be unsaved), or null.
Future<PaymentCard?> showCardsSheet(BuildContext context, {required num total, Color accent = AppColors.primary}) {
  return showModalBottomSheet<PaymentCard>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => _CardsSheet(total: total, accent: accent),
  );
}

class _CardsSheet extends StatefulWidget {
  const _CardsSheet({required this.total, required this.accent});
  final num total;
  final Color accent;

  @override
  State<_CardsSheet> createState() => _CardsSheetState();
}

class _CardsSheetState extends State<_CardsSheet> {
  List<PaymentCard>? _cards;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    DataService.cards().then((c) {
      if (!mounted) return;
      setState(() {
        _cards = c;
        final d = c.indexWhere((e) => e.isDefault);
        _index = d < 0 ? 0 : d;
      });
    }).catchError((_) {
      if (mounted) setState(() => _cards = []);
    });
  }

  Future<void> _add() async {
    final card = await Navigator.of(context).push<PaymentCard>(appRoute(const AddCardScreen()));
    if (card == null || !mounted) return;
    if (card.id == null) {
      Navigator.pop(context, card); // used once, not saved
      return;
    }
    setState(() {
      _cards = [...?_cards, card];
      _index = _cards!.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetNotch(),
            Padding(
              padding: const EdgeInsets.fromLTRB(46, 16, 42, 16),
              child: Row(
                children: [
                  Text('My Cards', style: AppTextStyles.navTitle.copyWith(fontSize: 16)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _add,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 6),
                          Text('Add New', style: AppTextStyles.smallBold.copyWith(color: AppColors.primary, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 24),
            if (cards == null)
              const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.primary))
            else if (cards.isEmpty) ...[
              Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(color: const Color(0xFFFFF1EA), borderRadius: BorderRadius.circular(60)),
                child: const Icon(Icons.credit_card_rounded, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              Text('Add your card', style: AppTextStyles.navTitle),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Text('It seems like you haven’t added any credit or debit card. Add a card for faster access.',
                    textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(color: const Color(0xFFC4C4C4))),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: _GreyButton(label: 'Back', onTap: () => Navigator.pop(context)),
              ),
            ] else ...[
              SizedBox(
                height: 162,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.78, initialPage: _index),
                  itemCount: cards.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _index = i),
                      child: CardVisual(card: cards[i], selected: i == _index && cards.length > 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: 'Confirm (${money(widget.total)})',
                      color: widget.accent,
                      onPressed: () => Navigator.pop(context, cards[_index]),
                    ),
                    const SizedBox(height: 12),
                    _GreyButton(label: 'Cancel', onTap: () => Navigator.pop(context)),
                    if (!AppConfig.paymentsLive)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text('Test mode: your card will not be charged.',
                            style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.label)),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _GreyButton extends StatelessWidget {
  const _GreyButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.disabled,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(height: 56, child: Center(child: Text(label, style: AppTextStyles.headline6))),
      ),
    );
  }
}

/// "Add Payment Method". Only the brand, last 4 digits and expiry are saved; never the full number or CVV.
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  bool _paypal = false;
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _exp = TextEditingController();
  final _cvv = TextEditingController();
  bool _save = true;
  bool _busy = false;

  String get _digits => _number.text.replaceAll(RegExp(r'\D'), '');
  bool get _numberOk => luhnValid(_digits);

  (int, int)? get _expiry {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(_exp.text);
    if (m == null) return null;
    final mm = int.parse(m.group(1)!);
    final yy = 2000 + int.parse(m.group(2)!);
    if (mm < 1 || mm > 12) return null;
    final end = DateTime(yy, mm + 1, 1);
    if (!end.isAfter(DateTime.now())) return null;
    return (mm, yy);
  }

  bool get _valid => _name.text.trim().length >= 3 && _numberOk && _expiry != null && RegExp(r'^\d{3,4}$').hasMatch(_cvv.text);

  @override
  void dispose() {
    for (final c in [_name, _number, _exp, _cvv]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    final (mm, yy) = _expiry!;
    try {
      PaymentCard card;
      if (_save) {
        card = await DataService.addCard(
          holder: _name.text.trim(),
          brand: cardBrand(_digits),
          last4: _digits.substring(_digits.length - 4),
          expMonth: mm,
          expYear: yy,
        );
      } else {
        card = PaymentCard(id: null, holder: _name.text.trim(), brand: cardBrand(_digits), last4: _digits.substring(_digits.length - 4), expMonth: mm, expYear: yy);
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black54,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 40),
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Card Added Successfully', style: AppTextStyles.navTitle),
                    const SizedBox(height: 10),
                    Text('Go back to your payment page and select new card to pay!',
                        textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(color: const Color(0xFFC4C4C4))),
                    const SizedBox(height: 22),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('GO BACK TO PAYMENT', style: AppTextStyles.smallBold.copyWith(color: AppColors.primary, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 34),
              ),
            ],
          ),
        ),
      );
      if (mounted) Navigator.pop(context, card);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = cardBrand(_digits);
    return ServiceChrome(
      title: 'Add Payment Method',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(40, 36, 40, 30),
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                for (final (label, isPaypal) in [('PayPal', true), ('Credit Card', false)])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _paypal = isPaypal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: _paypal == isPaypal ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                        child: Text(label,
                            style: AppTextStyles.headline6.copyWith(color: _paypal == isPaypal ? AppColors.primary : AppColors.dark, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_paypal) ...[
            const Icon(Icons.account_balance_wallet_outlined, size: 54, color: AppColors.blue),
            const SizedBox(height: 14),
            Text('PayPal isn’t supported for Naira payments', textAlign: TextAlign.center, style: AppTextStyles.navTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Please add a debit or credit card (Visa, Mastercard or Verve), or choose Cash on the order page.',
                textAlign: TextAlign.center, style: AppTextStyles.small),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Use a card instead', onPressed: () => setState(() => _paypal = false)),
          ] else ...[
            AppTextField(label: 'Name', controller: _name, autofillHints: const [AutofillHints.creditCardName], onChanged: (_) => setState(() {})),
            const SizedBox(height: 22),
            TextField(
              controller: _number,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.creditCardNumber],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19), _CardNumberFormatter()],
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.input,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                labelText: 'Number Card',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: AppTextStyles.label,
                contentPadding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFBDBDC2))),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_numberOk) const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 22),
                      const SizedBox(width: 10),
                      if (_digits.length >= 2)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: brand == 'mastercard' ? Colors.transparent : AppColors.dark, borderRadius: BorderRadius.circular(4)),
                          child: BrandMark(brand: brand, size: brand == 'mastercard' ? 0.75 : 0.7),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_digits.length >= 12 && !_numberOk)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: Text('Check the card number', style: AppTextStyles.small.copyWith(color: AppColors.warning, fontSize: 12)),
              ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _exp,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), _ExpiryFormatter()],
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.input,
                    decoration: _boxDecoration('Exp. Date', 'MM/YY'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _cvv,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.input,
                    decoration: _boxDecoration('CVV', '•••'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                children: [
                  AppCheckbox(value: _save, onChanged: (v) => setState(() => _save = v)),
                  const SizedBox(width: 14),
                  Text('Save this card information', style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('We only keep the last 4 digits and expiry date. Your full card number and CVV are never stored.',
                style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.label)),
            const SizedBox(height: 22),
            PrimaryButton(label: 'Add', enabled: _valid, loading: _busy, onPressed: _add),
          ],
        ],
      ),
    );
  }

  InputDecoration _boxDecoration(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.input.copyWith(color: AppColors.label),
        contentPadding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFBDBDC2))),
      );
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(' ', '');
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll('/', '');
    final t = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}
