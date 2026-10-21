import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auth_scaffold.dart';

TextStyle _white(double size, {FontWeight w = FontWeight.w700, double? height, double spacing = -0.3}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: Colors.white, height: height, letterSpacing: spacing);

LinearGradient offerGradient(Offer o) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [o.colorStart, o.colorEnd],
    );

Widget _offerImage(Offer o, {required double width}) {
  final img = o.imageAsset != null
      ? Image.asset(o.imageAsset!, fit: BoxFit.cover, alignment: Alignment.topCenter)
      : o.imageUrl != null
          ? Image.network(o.imageUrl!, fit: BoxFit.cover)
          : null;
  if (img == null) return const SizedBox.shrink();
  return SizedBox(width: width, child: img);
}

void copyCode(BuildContext context, Offer o) {
  if (o.code == null) return;
  Clipboard.setData(ClipboardData(text: o.code!));
  showAppSnack(context, 'Code ${o.code} copied');
}

class _SmallLogo extends StatelessWidget {
  const _SmallLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/app/logo_mark_white.png', width: 20, height: 16),
        const SizedBox(width: 3),
        Text(AppConfig.appName, style: _white(12, w: FontWeight.w700).copyWith(fontStyle: FontStyle.italic)),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 9, color: Colors.white),
          const SizedBox(width: 3),
          Text(text, style: _white(8, w: FontWeight.w500, spacing: 0)),
        ],
      ),
    );
  }
}

/// 272 x 137 banner on the dashboard ("40% OFF On First Cleaning Service").
class OfferBanner extends StatelessWidget {
  const OfferBanner({super.key, required this.offer, this.width = 272, this.height = 137});

  final Offer offer;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => copyCode(context, offer),
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(gradient: offerGradient(offer), borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              child: Transform.rotate(
                angle: 0.6,
                child: Container(width: 160, height: 200, color: const Color(0x14FFFFFF)),
              ),
            ),
            Positioned(right: 0, top: 0, bottom: 0, child: _offerImage(offer, width: height * 0.84)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SmallLogo(),
                  const Spacer(),
                  if (offer.tag != null) ...[_TagPill(offer.tag!), const SizedBox(height: 6)],
                  Text(offer.title, style: _white(22, height: 1.1, spacing: -0.8)),
                  if (offer.subtitle != null)
                    Text(offer.subtitle!, style: _white(10, w: FontWeight.w500, spacing: 0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Latest Offers" card on the Offers tab (with code).
class OfferCodeCard extends StatelessWidget {
  const OfferCodeCard({super.key, required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => copyCode(context, offer),
      child: Container(
        width: 220,
        height: 92,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(gradient: offerGradient(offer), borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            Positioned(right: 0, top: 0, bottom: 0, child: _offerImage(offer, width: 80)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.title, style: _white(22, height: 1, spacing: -0.8)),
                  const SizedBox(height: 2),
                  if (offer.subtitle != null) Text(offer.subtitle!, style: _white(10, w: FontWeight.w500, spacing: 0)),
                  const Spacer(),
                  if (offer.code != null)
                    Text('Code : ${offer.code}', style: _white(11, w: FontWeight.w500, spacing: 0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big "Limited Offer" card.
class LimitedOfferCard extends StatelessWidget {
  const LimitedOfferCard({super.key, required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => copyCode(context, offer),
      child: Container(
        height: 178,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(gradient: offerGradient(offer), borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -30,
              child: Transform.rotate(angle: 0.6, child: Container(width: 200, height: 260, color: const Color(0x14FFFFFF))),
            ),
            Positioned(right: 0, top: 18, bottom: 6, child: _offerImage(offer, width: 196)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (offer.tag != null) _TagPill(offer.tag!),
                  const SizedBox(height: 10),
                  Text(offer.title, style: _white(26, height: 1, spacing: -1)),
                  if (offer.subtitle != null) Text(offer.subtitle!, style: _white(13, w: FontWeight.w500, spacing: 0)),
                  const Spacer(),
                  if (offer.code != null) ...[
                    Text('Code :', style: _white(13, w: FontWeight.w500, spacing: 0)),
                    Text(offer.code!, style: _white(26, height: 1.1, spacing: -0.5)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Just for you" 123 x 150 card with ORDER NOW.
class JustForYouCard extends StatelessWidget {
  const JustForYouCard({super.key, required this.offer, required this.icon, required this.onOrder});
  final Offer offer;
  final IconData icon;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 123,
      height: 150,
      decoration: BoxDecoration(gradient: offerGradient(offer), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          if (offer.subtitle != null)
            Text(offer.subtitle!, style: _white(10, w: FontWeight.w500, spacing: 0).copyWith(color: const Color(0xCCFFFFFF))),
          Text(offer.title, style: _white(17, spacing: -0.5)),
          const Spacer(),
          GestureDetector(
            onTap: onOrder,
            child: Container(
              height: 28,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(8)),
              child: Text('ORDER NOW', style: _white(10, w: FontWeight.w500, spacing: 0)),
            ),
          ),
        ],
      ),
    );
  }
}
