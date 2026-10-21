import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class Place {
  const Place(this.address, this.point);
  final String address;
  final LatLng point;
}

enum LocationIssue { none, serviceOff, denied, deniedForever, timeout }

class LocationResult {
  const LocationResult(this.point, this.issue, {this.accuracy});
  final LatLng? point;
  final LocationIssue issue;
  final double? accuracy;
}

/// Device location + free address lookup with several providers so an address
/// name is almost always found. Raw coordinates are never shown to people.
class GeoService {
  GeoService._();

  static const fallback = LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
  static final _cache = <String, String>{};
  static DateTime _lastNominatim = DateTime(2000);

  /// Two stages: a quick rough fix, then a precise one.
  static Future<LocationResult> locate() async {
    try {
      if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(null, LocationIssue.serviceOff);
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return const LocationResult(null, LocationIssue.deniedForever);
      if (perm == LocationPermission.denied) return const LocationResult(null, LocationIssue.denied);

      Position? pos;
      if (!kIsWeb) {
        try {
          pos = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 15)),
        );
      } catch (_) {
        try {
          pos ??= await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
          );
        } catch (_) {}
      }
      if (pos == null) return const LocationResult(null, LocationIssue.timeout);
      return LocationResult(LatLng(pos.latitude, pos.longitude), LocationIssue.none, accuracy: pos.accuracy);
    } catch (_) {
      return const LocationResult(null, LocationIssue.denied);
    }
  }

  /// Compatibility helper: just the point (or null).
  static Future<LatLng?> currentLocation() async => (await locate()).point;

  /// Explains how to switch location on, for the issue found.
  static Future<void> explain(BuildContext context, LocationIssue issue) async {
    if (issue == LocationIssue.none) return;
    final (title, body) = switch (issue) {
      LocationIssue.serviceOff => ('Turn on location', 'Your phone’s location (GPS) is off. Turn it on in Settings, then try again.'),
      LocationIssue.deniedForever => (
          'Location is blocked',
          kIsWeb
              ? 'Your browser blocked location for this app. Tap the lock or “aA” icon in the address bar, allow Location, then reload.\n\nOn iPhone: Settings → Privacy & Security → Location Services → Safari Websites → While Using.'
              : 'Location permission is turned off for ${AppConfig.appName}. Open Settings and allow location “While using the app”.'
        ),
      LocationIssue.timeout => ('Couldn’t get a GPS fix', 'Move near a window or outdoors and try again, or search for your address instead.'),
      _ => ('Allow location', 'Allow location access when asked so we can find your address. You can also search or move the map.'),
    };
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: AppTextStyles.navTitle),
        content: Text(body, style: AppTextStyles.small.copyWith(color: AppColors.dark, fontSize: 14)),
        actions: [
          if (!kIsWeb && issue == LocationIssue.deniedForever)
            TextButton(onPressed: () => Geolocator.openAppSettings(), child: const Text('Open Settings')),
          if (!kIsWeb && issue == LocationIssue.serviceOff)
            TextButton(onPressed: () => Geolocator.openLocationSettings(), child: const Text('Open Settings')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  static String _key(LatLng p) => '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}';

  /// Readable address for a point. Tries three free services, then a nearby-area label.
  static Future<String> reverse(LatLng p) async {
    final k = _key(p);
    if (_cache.containsKey(k)) return _cache[k]!;
    final result = await _nominatimReverse(p) ?? await _bigDataCloud(p) ?? await _photonReverse(p);
    final name = result ?? 'Pinned location (move the map to adjust)';
    if (result != null) _cache[k] = name;
    return name;
  }

  static Future<String?> _nominatimReverse(LatLng p) async {
    try {
      // Respect the 1 request per second policy.
      final wait = const Duration(milliseconds: 1100) - DateTime.now().difference(_lastNominatim);
      if (!wait.isNegative) await Future<void>.delayed(wait);
      _lastNominatim = DateTime.now();
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=18&addressdetails=1&lat=${p.latitude}&lon=${p.longitude}');
      final res = await http.get(uri, headers: {'Accept-Language': 'en'}).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (j['error'] != null) return null;
      final a = (j['address'] as Map?)?.cast<String, dynamic>() ?? {};
      final street = [a['house_number'], a['road'] ?? a['pedestrian'] ?? a['street']].whereType<String>().join(' ');
      final area = (a['suburb'] ?? a['neighbourhood'] ?? a['quarter'] ?? a['village'] ?? a['town']) as String?;
      final city = (a['city'] ?? a['state_district'] ?? a['county'] ?? a['state']) as String?;
      final parts = [street, area, city].whereType<String>().where((s) => s.trim().isNotEmpty).toSet().toList();
      if (parts.isNotEmpty) return parts.join(', ');
      final d = j['display_name'] as String?;
      return d?.split(',').take(3).join(',').trim();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _bigDataCloud(LatLng p) async {
    try {
      final uri = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${p.latitude}&longitude=${p.longitude}&localityLanguage=en');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final parts = [j['locality'], j['city'], j['principalSubdivision']]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toSet()
          .toList();
      return parts.isEmpty ? null : 'Near ${parts.join(', ')}';
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _photonReverse(LatLng p) async {
    try {
      final uri = Uri.parse('https://photon.komoot.io/reverse?lat=${p.latitude}&lon=${p.longitude}&lang=en');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final f = ((jsonDecode(res.body) as Map)['features'] as List?)?.firstOrNull as Map?;
      final pr = (f?['properties'] as Map?)?.cast<String, dynamic>();
      if (pr == null) return null;
      final parts = [
        [pr['housenumber'], pr['street'] ?? pr['name']].whereType<String>().join(' '),
        pr['district'] ?? pr['locality'],
        pr['city'] ?? pr['state'],
      ].whereType<String>().where((s) => s.trim().isNotEmpty).toSet().toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  static Future<List<Place>> search(String query, {LatLng? near}) async {
    if (query.trim().length < 3) return [];
    final a = await _nominatimSearch(query);
    if (a.isNotEmpty) return a;
    return _photonSearch(query, near: near);
  }

  static Future<List<Place>> _nominatimSearch(String query) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=jsonv2&limit=6&countrycodes=ng,gh,ke,za,gb,us,ca&q=${Uri.encodeQueryComponent(query)}');
      final res = await http.get(uri, headers: {'Accept-Language': 'en'}).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => Place(
                (e['display_name'] as String).split(',').take(4).join(',').trim(),
                LatLng(double.parse(e['lat'] as String), double.parse(e['lon'] as String)),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Place>> _photonSearch(String query, {LatLng? near}) async {
    try {
      final bias = near ?? fallback;
      final uri = Uri.parse(
          'https://photon.komoot.io/api/?q=${Uri.encodeQueryComponent(query)}&limit=6&lang=en&lat=${bias.latitude}&lon=${bias.longitude}');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final feats = ((jsonDecode(res.body) as Map)['features'] as List?) ?? [];
      return feats.map((f) {
        final pr = (f['properties'] as Map).cast<String, dynamic>();
        final c = (f['geometry']['coordinates'] as List).cast<num>();
        final label = [pr['name'], pr['street'], pr['district'] ?? pr['locality'], pr['city'] ?? pr['state']]
            .whereType<String>()
            .toSet()
            .join(', ');
        return Place(label, LatLng(c[1].toDouble(), c[0].toDouble()));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static double distanceMeters(LatLng a, LatLng b) => const Distance().as(LengthUnit.Meter, a, b);
}
