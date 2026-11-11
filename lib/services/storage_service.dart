import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_models.dart';

class StorageService {
  static const String _odometerPrefix = 'odometer_';
  static const String _refuelingPrefix = 'refuelings_';
  static const String _breakPrefix = 'breaks_';
  static const String _statusPrefix = 'status_';

  static Future<void> saveOdometers(String routeId, int? start, int? end) async {
    final prefs = await SharedPreferences.getInstance();
    if (start != null) {
      await prefs.setInt('$_odometerPrefix${routeId}_start', start);
    }
    if (end != null) {
      await prefs.setInt('$_odometerPrefix${routeId}_end', end);
    }
  }

  static Future<({int? start, int? end})> loadOdometers(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getInt('$_odometerPrefix${routeId}_start');
    final end = prefs.getInt('$_odometerPrefix${routeId}_end');
    return (start: start, end: end);
  }

  static const String _tripOdometerPrefix = 'balticbus_trip_odo_';

  static Future<void> saveTripOdometers(String busCode, int? start, int? end) async {
    final prefs = await SharedPreferences.getInstance();
    if (start != null) {
      await prefs.setInt('$_tripOdometerPrefix${busCode}_start', start);
    }
    if (end != null) {
      await prefs.setInt('$_tripOdometerPrefix${busCode}_end', end);
    }
  }

  static Future<({int? start, int? end})> loadTripOdometers(String busCode) async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getInt('$_tripOdometerPrefix${busCode}_start');
    final end = prefs.getInt('$_tripOdometerPrefix${busCode}_end');
    return (start: start, end: end);
  }

  static Future<void> saveRefuelings(String routeId, List<RefuelingEntry> refuelings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = refuelings.map((r) => r.toJson()).toList();
    await prefs.setString('$_refuelingPrefix$routeId', jsonEncode(jsonList));
  }

  static Future<List<RefuelingEntry>> loadRefuelings(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_refuelingPrefix$routeId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => RefuelingEntry.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveBreaks(String routeId, List<DriverBreak> breaks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = breaks.map((b) => b.toJson()).toList();
    await prefs.setString('$_breakPrefix$routeId', jsonEncode(jsonList));
  }

  static Future<List<DriverBreak>> loadBreaks(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_breakPrefix$routeId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => DriverBreak.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePassengerState(
    String routeId,
    int order,
    PickupStatus status,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'status': status.name,
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
    await prefs.setString('$_statusPrefix${routeId}_$order', jsonEncode(data));
  }

  static Future<void> restoreRouteState(BusRoute route) async {
    // 1. Liczniki pojedynczej trasy
    final odometers = await loadOdometers(route.id);
    if (odometers.start != null) route.startOdometerKm = odometers.start;
    if (odometers.end != null) route.endOdometerKm = odometers.end;

    // Liczniki całej trasy weekendowej (start sobota, koniec niedziela)
    final tripOdo = await loadTripOdometers(route.code);
    final isSaturday = route.direction == 'PL-DE' || route.date.endsWith('-01');
    final isSunday = route.direction == 'DE-PL' || route.date.endsWith('-02');

    if (tripOdo.start != null && isSaturday) {
      route.startOdometerKm = tripOdo.start;
    }
    if (tripOdo.end != null && isSunday) {
      route.endOdometerKm = tripOdo.end;
    }

    // 2. Tankowania
    final refuelings = await loadRefuelings(route.id);
    if (refuelings.isNotEmpty) {
      route.refuelings.clear();
      route.refuelings.addAll(refuelings);
    }

    // 3. Przerwy kierowcy
    final breaks = await loadBreaks(route.id);
    if (breaks.isNotEmpty) {
      route.breaks.clear();
      route.breaks.addAll(breaks);
    }

    // 4. Statusy pasażerów
    final prefs = await SharedPreferences.getInstance();
    for (final stop in route.stops) {
      final raw = prefs.getString('$_statusPrefix${route.id}_${stop.order}');
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final statusStr = map['status'] as String?;
          if (statusStr != null) {
            stop.status = PickupStatus.values.firstWhere(
              (s) => s.name == statusStr,
              orElse: () => PickupStatus.pending,
            );
          }
          if (map['pickedUpAt'] != null) {
            stop.pickedUpAt = DateTime.tryParse(map['pickedUpAt']);
          }
          if (map['deliveredAt'] != null) {
            stop.deliveredAt = DateTime.tryParse(map['deliveredAt']);
          }
          if (stop.status == PickupStatus.pickedUp || stop.status == PickupStatus.delivered) {
            stop.isCollapsed = true;
          }
        } catch (_) {}
      }
    }
  }

  static Future<void> saveTripFinancials({
    required String busCode,
    required double advanceEur,
    required double advancePln,
    required double cashCollectedPln,
    required double cashCollectedEur,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fin_${busCode}_advanceEur', advanceEur);
    await prefs.setDouble('fin_${busCode}_advancePln', advancePln);
    await prefs.setDouble('fin_${busCode}_cashPln', cashCollectedPln);
    await prefs.setDouble('fin_${busCode}_cashEur', cashCollectedEur);
  }

  static Future<({double advanceEur, double advancePln, double cashPln, double cashEur})> loadTripFinancials(String busCode) async {
    final prefs = await SharedPreferences.getInstance();
    return (
      advanceEur: prefs.getDouble('fin_${busCode}_advanceEur') ?? 0.0,
      advancePln: prefs.getDouble('fin_${busCode}_advancePln') ?? 0.0,
      cashPln: prefs.getDouble('fin_${busCode}_cashPln') ?? 0.0,
      cashEur: prefs.getDouble('fin_${busCode}_cashEur') ?? 0.0,
    );
  }

  static const String _themeModeKey = 'app_theme_is_dark';
  static const String _paletteThemeKey = 'app_palette_theme_id';

  static Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, isDark);
  }

  static Future<bool> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeModeKey) ?? true;
  }

  static Future<void> savePaletteTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteThemeKey, themeId);
  }

  static Future<String> loadPaletteTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_paletteThemeKey) ?? 'charcoalNoir';
  }

  static const String _hasActiveTripKey = 'balticbus_has_active_trip';

  static Future<void> setHasActiveTrip(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasActiveTripKey, value);
  }

  static Future<bool> hasActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasActiveTripKey) ?? true;
  }

  /// Czyści wszystkie dane bieżącego kursu (liczniki, tankowania, przerwy, statusy pasażerów, finanse)
  /// z zachowaniem preferencji wyglądu (motyw kolorystyczny, tryb ciemny/jasny).
  static Future<void> clearAllTripData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys().toList();
    for (final key in allKeys) {
      if (key == _themeModeKey || key == _paletteThemeKey) {
        continue;
      }
      await prefs.remove(key);
    }
    await prefs.setBool(_hasActiveTripKey, false);
  }
}
