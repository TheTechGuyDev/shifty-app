import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';

class Place {
  const Place(this.address, this.point);
  final String address;
  final LatLng point;
}

/// Free geocoding with OpenStreetMap Nominatim, and device location.
class GeoService {
  GeoService._();

  static const _base = 'https://nominatim.openstreetmap.org';
  static const fallback = LatLng(AppConfig.defaultLat, AppConfig.defaultLng);

  static Future<LatLng?> currentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<String> reverse(LatLng p) async {
    try {
      final uri = Uri.parse('$_base/reverse?format=jsonv2&zoom=18&addressdetails=1&lat=${p.latitude}&lon=${p.longitude}');
      final res = await http.get(uri, headers: {'Accept-Language': 'en'}).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return _coords(p);
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final a = (j['address'] as Map?)?.cast<String, dynamic>() ?? {};
      final parts = <String>[
        [a['house_number'], a['road']].whereType<String>().join(' '),
        (a['suburb'] ?? a['neighbourhood'] ?? a['village'] ?? '') as String,
        (a['city'] ?? a['town'] ?? a['state'] ?? '') as String,
      ].where((s) => s.trim().isNotEmpty).toList();
      if (parts.isEmpty) return (j['display_name'] as String?) ?? _coords(p);
      return parts.join(', ');
    } catch (_) {
      return _coords(p);
    }
  }

  static Future<List<Place>> search(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final uri = Uri.parse('$_base/search?format=jsonv2&limit=6&countrycodes=ng,gh,ke,za,gb,us,ca&q=${Uri.encodeQueryComponent(query)}');
      final res = await http.get(uri, headers: {'Accept-Language': 'en'}).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => Place(
                e['display_name'] as String,
                LatLng(double.parse(e['lat'] as String), double.parse(e['lon'] as String)),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static double distanceMeters(LatLng a, LatLng b) => const Distance().as(LengthUnit.Meter, a, b);

  static String _coords(LatLng p) => '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
}
