import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HotelInfo {
  final String name;
  final String address;
  final String city;
  final String? note;

  const HotelInfo({
    required this.name,
    required this.address,
    this.city = '',
    this.note,
  });

  String get fullAddress {
    if (address.isEmpty) return city;
    if (city.isEmpty) return address;
    if (address.toLowerCase().contains(city.toLowerCase())) return address;
    return '$address, $city';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'city': city,
        if (note != null) 'note': note,
      };

  factory HotelInfo.fromJson(Map<String, dynamic> json) => HotelInfo(
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        note: json['note'] as String?,
      );
}

class HotelDirectoryService {
  static const String permanentStorageKey = 'balticbus_permanent_hotel_directory';

  /// Predefiniowany katalog popularnych hoteli i ośrodków nadmorskich z tras BalticBus
  static final Map<String, HotelInfo> defaultHotels = {
    'san': const HotelInfo(
      name: 'San',
      address: 'ul. Kasprowicza 24',
      city: 'Kołobrzeg',
      note: 'Sanatorium Uzdrowiskowe San',
    ),
    'arka': const HotelInfo(
      name: 'Arka',
      address: 'ul. Sułkowskiego 11',
      city: 'Kołobrzeg',
      note: 'Arka Medical Spa',
    ),
    'ikar plaza': const HotelInfo(
      name: 'Ikar Plaza',
      address: 'ul. Wschodnia 35',
      city: 'Kołobrzeg',
    ),
    'max': const HotelInfo(
      name: 'Max',
      address: 'ul. Morska 16',
      city: 'Ustronie Morskie',
    ),
    'interferie': const HotelInfo(
      name: 'Interferie',
      address: 'ul. Uzdrowiskowa 15',
      city: 'Świnoujście',
      note: 'Interferie Medical SPA',
    ),
    'verano': const HotelInfo(
      name: 'Verano',
      address: 'ul. Sikorskiego 8',
      city: 'Kołobrzeg',
    ),
    'wydma spa': const HotelInfo(
      name: 'Wydma Spa',
      address: 'ul. Bałtycka 8',
      city: 'Mrzeżyno',
    ),
    'trzy wyspy': const HotelInfo(
      name: 'Trzy Wyspy',
      address: 'ul. Cieszkowskiego 1',
      city: 'Świnoujście',
    ),
    'muszelka': const HotelInfo(
      name: 'Muszelka',
      address: 'ul. Słowackiego 18',
      city: 'Kołobrzeg',
    ),
    'olymp 2': const HotelInfo(
      name: 'Olymp 2',
      address: 'ul. Wolności 4',
      city: 'Kołobrzeg',
    ),
    'olymp 4': const HotelInfo(
      name: 'Olymp 4',
      address: 'ul. Koszalińska 17',
      city: 'Kołobrzeg',
    ),
    'ottaviano': const HotelInfo(
      name: 'Ottaviano',
      address: 'ul. Monte Cassino 3',
      city: 'Świnoujście',
    ),
    'chabinka mdz': const HotelInfo(
      name: 'Chabinka MDZ',
      address: 'ul. Gryfa Pomorskiego 79',
      city: 'Międzyzdroje',
    ),
    'koral live': const HotelInfo(
      name: 'Koral Live',
      address: 'ul. Kościuszki 10',
      city: 'Kołobrzeg',
    ),
  };

  /// Pamięć podręczna w RAM
  static Map<String, HotelInfo>? _cachedHotels;

  static String normalizeKey(String raw) {
    var clean = raw.trim().toLowerCase();
    // Usunięcie nawiasów np. "Verano (Kołobrzeg)" -> "verano"
    final parenIdx = clean.indexOf('(');
    if (parenIdx != -1) {
      clean = clean.substring(0, parenIdx).trim();
    }
    return clean;
  }

  /// Ładuje bazę hoteli z pamięci trwałej urządzenia (oraz uzupełnia domyślnymi)
  static Future<Map<String, HotelInfo>> loadAll() async {
    if (_cachedHotels != null) return _cachedHotels!;

    final map = Map<String, HotelInfo>.from(defaultHotels);
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(permanentStorageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          map[entry.key] = HotelInfo.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    } catch (_) {}

    _cachedHotels = map;
    return map;
  }

  /// Synchroniczne pobranie hotelu z pamięci podręcznej RAM (lub bazy domyślnej)
  static HotelInfo? getCachedHotel(String rawName) {
    if (rawName.trim().isEmpty) return null;
    final all = _cachedHotels ?? defaultHotels;
    final key = normalizeKey(rawName);

    if (all.containsKey(key)) {
      return all[key];
    }

    for (final entry in all.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Wyszukuje hotel po nazwie z arkusza (toleruje nawiasy i wielkość liter)
  static Future<HotelInfo?> findHotel(String rawName) async {
    if (rawName.trim().isEmpty) return null;
    final all = await loadAll();
    final key = normalizeKey(rawName);

    // 1. Dokładne dopasowanie po znormalizowanym kluczu
    if (all.containsKey(key)) {
      return all[key];
    }

    // 2. Szukanie częściowe
    for (final entry in all.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Zapisuje lub aktualizuje hotel w trwałej bazie
  static Future<void> saveHotel({
    required String name,
    required String address,
    String city = '',
    String? note,
  }) async {
    final all = await loadAll();
    final key = normalizeKey(name);

    final info = HotelInfo(
      name: name.trim(),
      address: address.trim(),
      city: city.trim(),
      note: note?.trim(),
    );

    all[key] = info;
    _cachedHotels = all;

    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = all.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(permanentStorageKey, jsonEncode(toSave));
    } catch (_) {}
  }

  /// Zwraca wszystkie hotele z pamięci podręcznej (lub domyślne)
  static Map<String, HotelInfo> getAllHotelsSync() {
    return _cachedHotels ?? defaultHotels;
  }

  /// Zwraca hotele pogrupowane według miast
  static Map<String, List<HotelInfo>> getHotelsGroupedByCitySync() {
    final all = getAllHotelsSync().values.toList();
    all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final Map<String, List<HotelInfo>> grouped = {};
    for (final hotel in all) {
      final city = hotel.city.trim().isNotEmpty ? hotel.city.trim() : 'Pozostałe';
      grouped.putIfAbsent(city, () => []).add(hotel);
    }

    // Sortowanie miast: popularne na początku, pozostałe alfabetycznie
    const priorityCities = ['Kołobrzeg', 'Świnoujście', 'Międzyzdroje', 'Ustronie Morskie', 'Mrzeżyno'];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aIdx = priorityCities.indexOf(a);
        final bIdx = priorityCities.indexOf(b);
        if (aIdx != -1 && bIdx != -1) return aIdx.compareTo(bIdx);
        if (aIdx != -1) return -1;
        if (bIdx != -1) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  /// Usuwa hotel z pamięci stałej
  static Future<void> deleteHotel(String name) async {
    final all = await loadAll();
    final key = normalizeKey(name);
    all.remove(key);
    _cachedHotels = all;

    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = all.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(permanentStorageKey, jsonEncode(toSave));
    } catch (_) {}
  }
}

