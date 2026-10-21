import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format.dart';

/// Section title with an optional action on the right.
class ProSectionTitle extends StatelessWidget {
  const ProSectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.navTitle.copyWith(fontSize: 17))),
            if (action != null)
              GestureDetector(
                onTap: onAction,
                child: Text(action!, style: AppTextStyles.smallBold.copyWith(color: AppColors.primary)),
              ),
          ],
        ),
      );
}

/// Small number card.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.color = AppColors.primary, this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: AppTextStyles.navTitle.copyWith(fontSize: 20))),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(fontSize: 12)),
            ],
          ),
        ),
      );
}

/// Initials or photo avatar.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.name, this.url, this.size = 44});
  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFE6D6),
        image: url == null || url!.isEmpty ? null : DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: url == null || url!.isEmpty
          ? Text(initials, style: AppTextStyles.smallBold.copyWith(color: AppColors.primary, fontSize: size * 0.34))
          : null,
    );
  }
}

/// Menu row used on profile / settings screens.
class MenuTile extends StatelessWidget {
  const MenuTile({super.key, required this.icon, required this.title, this.subtitle, this.onTap, this.color = AppColors.dark, this.trailing});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyMedium.copyWith(fontSize: 15, color: color, fontWeight: FontWeight.w600)),
                    if (subtitle != null) Text(subtitle!, style: AppTextStyles.small.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.label),
            ],
          ),
        ),
      );
}

String progressLabel(String? p) => switch (p) {
      'assigned' => 'Assigned',
      'on_the_way' => 'On the way',
      'arrived' => 'Arrived',
      'started' => 'In progress',
      'completed' => 'Completed',
      _ => 'Waiting',
    };

/// A job summary card for lists.
class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.booking, this.onTap, this.badge, this.badgeColor = AppColors.primary, this.amount});
  final Booking booking;
  final VoidCallback? onTap;
  final String? badge;
  final Color badgeColor;
  final num? amount;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(b.serviceName, style: AppTextStyles.headline6.copyWith(fontSize: 16))),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: badgeColor.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                    child: Text(badge!, style: AppTextStyles.smallBold.copyWith(color: badgeColor, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (b.scheduledAt != null)
              _line(Icons.event_rounded, '${friendlyDay(b.scheduledAt!)}${b.timeSlot != null ? ', ${b.timeSlot}' : ''}'),
            if (b.address != null) _line(Icons.location_on_outlined, b.address!),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('#${b.reference}', style: AppTextStyles.small.copyWith(fontSize: 12)),
                const Spacer(),
                Text(amount != null ? money(amount) : (b.totalAmount == null || b.totalAmount == 0 ? 'Quote needed' : money(b.totalAmount)),
                    style: AppTextStyles.navTitle.copyWith(fontSize: 16, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData i, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(i, size: 16, color: AppColors.label),
            const SizedBox(width: 8),
            Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.dark))),
          ],
        ),
      );
}

/// Simple bar chart of the last 7 days of earnings.
class EarningsChart extends StatelessWidget {
  const EarningsChart({super.key, required this.daily, this.dark = false});
  final List<Map<String, dynamic>> daily;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final values = daily.map((d) => (d['amount'] as num?)?.toDouble() ?? 0).toList();
    final max = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < daily.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: max == 0 ? 0.04 : (values[i] / max).clamp(0.04, 1.0)),
                    duration: Duration(milliseconds: 500 + i * 60),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Container(
                      height: 110 * v,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: i == daily.length - 1 ? AppColors.primary : (dark ? Colors.white24 : const Color(0xFFFFD3BC)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[(DateTime.tryParse(daily[i]['day'] as String? ?? '')?.weekday ?? (i + 1)) - 1],
                    style: AppTextStyles.small.copyWith(fontSize: 12, color: dark ? Colors.white70 : AppColors.label),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String message, {String yes = 'Yes', Color color = AppColors.primary}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: AppTextStyles.navTitle),
      content: Text(message, style: AppTextStyles.small.copyWith(fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Not now', style: AppTextStyles.smallBold)),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(yes, style: AppTextStyles.smallBold.copyWith(color: color))),
      ],
    ),
  );
  return ok == true;
}

/// Lets the person take a photo or pick one from the gallery. Returns (bytes, ext).
Future<(Uint8List, String)?> pickPhoto(BuildContext context) async {
  ImageSource? source = ImageSource.gallery;
  if (!kIsWeb) {
    source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MenuTile(icon: Icons.photo_camera_rounded, title: 'Take a photo', onTap: () => Navigator.pop(context, ImageSource.camera)),
              MenuTile(icon: Icons.photo_library_rounded, title: 'Choose from gallery', onTap: () => Navigator.pop(context, ImageSource.gallery)),
            ],
          ),
        ),
      ),
    );
  }
  if (source == null) return null;
  final f = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 82);
  if (f == null) return null;
  final bytes = await f.readAsBytes();
  var ext = f.name.contains('.') ? f.name.split('.').last.toLowerCase() : 'jpg';
  if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) ext = 'jpg';
  if (ext == 'jpeg') ext = 'jpg';
  return (bytes, ext);
}
