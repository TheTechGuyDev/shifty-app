import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';

enum BookingKind { house, office, commercial, cleaning, painting, vehicle, generic }

BookingKind kindForSlug(String slug) => switch (slug) {
      'house-shifting' || 'moving-and-relocation' => BookingKind.house,
      'office-shifting' => BookingKind.office,
      'commercial-shifting' => BookingKind.commercial,
      'home-cleaning' || 'office-cleaning' || 'deep-cleaning' => BookingKind.cleaning,
      'painting' => BookingKind.painting,
      'vehicle' || 'driver-hire' || 'towing-and-roadside-assistance' => BookingKind.vehicle,
      _ => BookingKind.generic,
    };

/// Everything collected while booking; passed from screen to screen.
class BookingDraft {
  BookingDraft(this.service) : kind = kindForSlug(service.slug);

  final ServiceCategory service;
  final BookingKind kind;

  /// Sent to the server as-is; the server prices it.
  final Map<String, dynamic> details = {};

  DateTime? date;
  String? timeSlot;

  String? address;
  LatLng? point;
  String? dropoffAddress;
  LatLng? dropoffPoint;

  String? promo;

  Color get accent => switch (kind) {
        BookingKind.cleaning => AppColors.success,
        BookingKind.painting => AppColors.yellow,
        _ => AppColors.primary,
      };

  /// Moving-type jobs have a pickup and a destination.
  bool get twoPoints => kind == BookingKind.house || kind == BookingKind.office || kind == BookingKind.commercial || kind == BookingKind.vehicle;

  int count(String key) => (details[key] as int?) ?? 0;

  Map<String, int> get furniture => ((details['furniture'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, v as int));

  int get furnitureTotal => furniture.values.fold(0, (a, b) => a + b);

  DateTime? get scheduledAt {
    if (date == null || timeSlot == null) return null;
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)').firstMatch(timeSlot!);
    if (m == null) return DateTime(date!.year, date!.month, date!.day, 9);
    var h = int.parse(m.group(1)!) % 12;
    if (m.group(3) == 'PM') h += 12;
    return DateTime(date!.year, date!.month, date!.day, h, int.parse(m.group(2)!));
  }

  String get sizeLabel => (details['size_label'] as String?) ?? service.name;
}

/// Time slots offered on schedule screens, grouped by part of day.
const timeSlotsByPeriod = <String, List<String>>{
  'Morning': ['07:00 AM', '08:00 AM', '09:00 AM'],
  'Late Morning': ['10:00 AM', '11:00 AM', '12:00 PM'],
  'Afternoon': ['01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM'],
  'Evening': ['05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM'],
};

List<String> get allTimeSlots => timeSlotsByPeriod.values.expand((e) => e).toList();
