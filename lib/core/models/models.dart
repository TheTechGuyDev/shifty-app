import 'package:flutter/material.dart';

Color hexColor(String? hex, [Color fallback = const Color(0xFFFD6B22)]) {
  if (hex == null) return fallback;
  final h = hex.replaceAll('#', '');
  final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return v == null ? fallback : Color(v);
}

class ServiceCategory {
  ServiceCategory({
    required this.id,
    required this.parentId,
    required this.name,
    required this.slug,
    required this.icon,
    required this.color,
    this.homeSection,
    this.badge,
    this.requiresVerification = false,
    this.sort = 0,
    this.homeSort = 0,
  });

  final String id;
  final String? parentId;
  final String name;
  final String slug;
  final String icon;
  final Color color;
  final String? homeSection;
  final String? badge;
  final bool requiresVerification;
  final int sort;
  final int homeSort;

  bool get isGroup => parentId == null;

  factory ServiceCategory.fromMap(Map<String, dynamic> m) => ServiceCategory(
        id: m['id'] as String,
        parentId: m['parent_id'] as String?,
        name: m['name'] as String,
        slug: m['slug'] as String,
        icon: (m['icon'] as String?) ?? 'build',
        color: hexColor(m['color'] as String?),
        homeSection: m['home_section'] as String?,
        badge: m['badge'] as String?,
        requiresVerification: (m['requires_verification'] as bool?) ?? false,
        sort: (m['sort'] as int?) ?? 0,
        homeSort: (m['home_sort'] as int?) ?? 0,
      );
}

class Offer {
  Offer({
    required this.id,
    required this.section,
    required this.title,
    required this.colorStart,
    required this.colorEnd,
    required this.chip,
    this.tag,
    this.subtitle,
    this.code,
    this.image,
  });

  final String id;
  final String section;
  final String title;
  final String? tag;
  final String? subtitle;
  final String? code;
  final String? image;
  final Color colorStart;
  final Color colorEnd;
  final String chip;

  /// Local asset for bundled images, or a network URL.
  String? get imageAsset => image == null || image!.startsWith('http') ? null : 'assets/images/app/$image.png';
  String? get imageUrl => image != null && image!.startsWith('http') ? image : null;

  factory Offer.fromMap(Map<String, dynamic> m) => Offer(
        id: m['id'] as String,
        section: m['section'] as String,
        title: m['title'] as String,
        tag: m['tag'] as String?,
        subtitle: m['subtitle'] as String?,
        code: m['code'] as String?,
        image: m['image'] as String?,
        colorStart: hexColor(m['color_start'] as String?),
        colorEnd: hexColor(m['color_end'] as String?),
        chip: (m['chip'] as String?) ?? 'Trending',
      );
}

enum BookingStatus { pending, active, done, cancelled }

class Booking {
  Booking({
    required this.id,
    required this.reference,
    required this.serviceName,
    required this.status,
    required this.createdAt,
    this.scheduledAt,
    this.address,
    this.lat,
    this.lng,
    this.totalAmount,
  });

  final String id;
  final String reference;
  final String serviceName;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final String? address;
  final double? lat;
  final double? lng;
  final num? totalAmount;

  factory Booking.fromMap(Map<String, dynamic> m) => Booking(
        id: m['id'] as String,
        reference: (m['reference'] as String?) ?? '',
        serviceName: m['service_name'] as String,
        status: BookingStatus.values.firstWhere((s) => s.name == m['status'], orElse: () => BookingStatus.pending),
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        scheduledAt: m['scheduled_at'] == null ? null : DateTime.parse(m['scheduled_at'] as String).toLocal(),
        address: m['address'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        totalAmount: m['total_amount'] as num?,
      );
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        type: m['type'] as String,
        title: m['title'] as String,
        body: (m['body'] as String?) ?? '',
        isRead: (m['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}
