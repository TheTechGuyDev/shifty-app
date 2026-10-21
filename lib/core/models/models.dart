import 'package:flutter/material.dart';

Color hexColor(String? hex, [Color fallback = const Color(0xFFFD6B22)]) {
  if (hex == null) return fallback;
  final h = hex.replaceAll('#', '');
  final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return v == null ? fallback : Color(v);
}

double? _d(dynamic v) => (v as num?)?.toDouble();

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
    this.serviceSlug,
    this.discountPct = 0,
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
  final String? serviceSlug;
  final int discountPct;

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
        serviceSlug: m['service_slug'] as String?,
        discountPct: (m['discount_pct'] as int?) ?? 0,
      );
}

enum BookingStatus { pending, active, done, cancelled }

class QuoteLine {
  QuoteLine({required this.label, required this.amount, this.note, this.icon});
  final String label;
  final String? note;
  final num amount;
  final String? icon;

  factory QuoteLine.fromMap(Map<String, dynamic> m) => QuoteLine(
        label: m['label'] as String,
        note: m['note'] as String?,
        amount: (m['amount'] as num?) ?? 0,
        icon: m['icon'] as String?,
      );
}

class Quote {
  Quote({
    required this.lines,
    required this.subtotal,
    required this.serviceCharge,
    required this.promoPct,
    required this.discount,
    required this.total,
  });

  final List<QuoteLine> lines;
  final num subtotal;
  final num serviceCharge;
  final int promoPct;
  final num discount;
  final num total;

  factory Quote.fromMap(Map<String, dynamic> m) => Quote(
        lines: ((m['lines'] as List?) ?? []).map((e) => QuoteLine.fromMap((e as Map).cast<String, dynamic>())).toList(),
        subtotal: (m['subtotal'] as num?) ?? 0,
        serviceCharge: (m['service_charge'] as num?) ?? 0,
        promoPct: (m['promo_pct'] as num?)?.toInt() ?? 0,
        discount: (m['discount'] as num?) ?? 0,
        total: (m['total'] as num?) ?? 0,
      );
}

class Booking {
  Booking({
    required this.id,
    required this.reference,
    required this.serviceName,
    required this.status,
    required this.createdAt,
    this.serviceSlug,
    this.kind = 'generic',
    this.scheduledAt,
    this.timeSlot,
    this.address,
    this.lat,
    this.lng,
    this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.totalAmount,
    this.subtotal,
    this.serviceCharge,
    this.discount = 0,
    this.promoCode,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'unpaid',
    this.lines = const [],
    this.details = const {},
    this.customerId,
    this.professionalId,
    this.progress,
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.commission,
    this.proEarning,
    this.completedAt,
    this.reschedule,
  });

  final String? customerId;
  final String? professionalId;
  final String? progress;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final num? commission;
  final num? proEarning;
  final DateTime? completedAt;
  final Map<String, dynamic>? reschedule;

  DateTime? get rescheduleAt => reschedule?['at'] == null ? null : DateTime.parse(reschedule!['at'] as String).toLocal();
  String? get rescheduleNote => reschedule?['note'] as String?;

  final String id;
  final String reference;
  final String serviceName;
  final BookingStatus status;
  final DateTime createdAt;
  final String? serviceSlug;
  final String kind;
  final DateTime? scheduledAt;
  final String? timeSlot;
  final String? address;
  final double? lat;
  final double? lng;
  final String? dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final num? totalAmount;
  final num? subtotal;
  final num? serviceCharge;
  final num discount;
  final String? promoCode;
  final String paymentMethod;
  final String paymentStatus;
  final List<QuoteLine> lines;
  final Map<String, dynamic> details;

  factory Booking.fromMap(Map<String, dynamic> m) => Booking(
        id: m['id'] as String,
        reference: (m['reference'] as String?) ?? '',
        serviceName: m['service_name'] as String,
        status: BookingStatus.values.firstWhere((s) => s.name == m['status'], orElse: () => BookingStatus.pending),
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        serviceSlug: m['service_slug'] as String?,
        kind: (m['kind'] as String?) ?? 'generic',
        scheduledAt: m['scheduled_at'] == null ? null : DateTime.parse(m['scheduled_at'] as String).toLocal(),
        timeSlot: m['time_slot'] as String?,
        address: m['address'] as String?,
        lat: _d(m['lat']),
        lng: _d(m['lng']),
        dropoffAddress: m['dropoff_address'] as String?,
        dropoffLat: _d(m['dropoff_lat']),
        dropoffLng: _d(m['dropoff_lng']),
        totalAmount: m['total_amount'] as num?,
        subtotal: m['subtotal'] as num?,
        serviceCharge: m['service_charge'] as num?,
        discount: (m['discount'] as num?) ?? 0,
        promoCode: m['promo_code'] as String?,
        paymentMethod: (m['payment_method'] as String?) ?? 'cash',
        paymentStatus: (m['payment_status'] as String?) ?? 'unpaid',
        lines: ((m['breakdown'] as List?) ?? []).map((e) => QuoteLine.fromMap((e as Map).cast<String, dynamic>())).toList(),
        details: ((m['details'] as Map?) ?? {}).cast<String, dynamic>(),
        customerId: m['customer_id'] as String?,
        professionalId: m['professional_id'] as String?,
        progress: m['progress'] as String?,
        beforePhotos: ((m['before_photos'] as List?) ?? []).cast<String>(),
        afterPhotos: ((m['after_photos'] as List?) ?? []).cast<String>(),
        commission: m['commission'] as num?,
        proEarning: m['pro_earning'] as num?,
        completedAt: m['completed_at'] == null ? null : DateTime.parse(m['completed_at'] as String).toLocal(),
        reschedule: (m['reschedule_request'] as Map?)?.cast<String, dynamic>(),
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

class SavedAddress {
  SavedAddress({required this.id, required this.label, required this.address, this.lat, this.lng});
  final String id;
  final String label;
  final String address;
  final double? lat;
  final double? lng;

  factory SavedAddress.fromMap(Map<String, dynamic> m) => SavedAddress(
        id: m['id'] as String,
        label: m['label'] as String,
        address: m['address'] as String,
        lat: _d(m['lat']),
        lng: _d(m['lng']),
      );
}

class PaymentCard {
  PaymentCard({
    required this.id,
    required this.holder,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.isDefault = false,
  });

  final String? id;
  final String holder;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  String get expiry => '${expMonth.toString().padLeft(2, '0')}/${(expYear % 100).toString().padLeft(2, '0')}';

  factory PaymentCard.fromMap(Map<String, dynamic> m) => PaymentCard(
        id: m['id'] as String,
        holder: m['holder'] as String,
        brand: m['brand'] as String,
        last4: m['last4'] as String,
        expMonth: m['exp_month'] as int,
        expYear: m['exp_year'] as int,
        isDefault: (m['is_default'] as bool?) ?? false,
      );
}

class Faq {
  Faq({required this.category, required this.question, required this.answer});
  final String category;
  final String question;
  final String answer;

  factory Faq.fromMap(Map<String, dynamic> m) =>
      Faq(category: m['category'] as String, question: m['question'] as String, answer: m['answer'] as String);
}

class SupportMessage {
  SupportMessage({required this.id, required this.fromUser, required this.body, required this.createdAt, this.agentName});
  final String id;
  final bool fromUser;
  final String body;
  final DateTime createdAt;
  final String? agentName;

  factory SupportMessage.fromMap(Map<String, dynamic> m) => SupportMessage(
        id: m['id'] as String,
        fromUser: m['sender'] == 'user',
        body: m['body'] as String,
        agentName: m['agent_name'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}
