import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class HotelInfo {
  final String name;
  final String address;
  final String city;
  final String? note;
  final bool fromList;

  const HotelInfo({
    required this.name,
    required this.address,
    this.city = '',
    this.note,
    this.fromList = false,
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
        'fromList': fromList,
      };

  factory HotelInfo.fromJson(Map<String, dynamic> json) => HotelInfo(
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        note: json['note'] as String?,
        fromList: json['fromList'] as bool? ?? false,
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
    'delfin': const HotelInfo(
      name: 'Delfin',
      address: 'ul. Uzdrowiskowa 3',
      city: 'Świnoujście',
    ),
    'stella maris': const HotelInfo(
      name: 'Stella Maris',
      address: 'ul. Gierczak 2',
      city: 'Świnoujście',
    ),
    'bursztyn': const HotelInfo(
      name: 'Bursztyn',
      address: 'ul. Chopina 1',
      city: 'Świnoujście',
    ),
    'wodnik': const HotelInfo(
      name: 'Wodnik',
      address: 'ul. Sikorskiego 6',
      city: 'Kołobrzeg',
    ),
    'perła bałtyku': const HotelInfo(
      name: 'Perła Bałtyku',
      address: 'ul. Sikorskiego 3',
      city: 'Kołobrzeg',
    ),
    'lekarz wojskowy': const HotelInfo(
      name: 'Wojskowy Szpital Uzdrowiskowy',
      address: 'ul. Wojska Polskiego 24',
      city: 'Kołobrzeg',
    ),
    'new skanpol': const HotelInfo(
      name: 'Hotel New Skanpol',
      address: 'ul. Dworcowa 9',
      city: 'Kołobrzeg',
    ),
    'aquarius': const HotelInfo(
      name: 'Aquarius Spa',
      address: 'ul. Kasprowicza 24',
      city: 'Kołobrzeg',
    ),
    'amber baltic': const HotelInfo(
      name: 'Vienna House Amber Baltic',
      address: 'Promenada Gwiazd 1',
      city: 'Międzyzdroje',
    ),
    'wolin': const HotelInfo(
      name: 'Hotel Wolin',
      address: 'ul. Ścieżka Polna 1',
      city: 'Międzyzdroje',
    ),
    'bagicz': const HotelInfo(
      name: 'Bagicz Voda Spa',
      address: 'ul. Lotnicza 1',
      city: 'Ustronie Morskie',
    ),
    'albatros': const HotelInfo(
      name: 'Albatros Spa',
      address: 'ul. Kasprowicza 13',
      city: 'Ustronie Morskie',
    ),
    'geovita': const HotelInfo(
      name: 'Geovita',
      address: 'ul. Północna 2',
      city: 'Dźwirzyno',
    ),
    'senator': const HotelInfo(
      name: 'Hotel Senator',
      address: 'ul. Wyzwolenia 35',
      city: 'Dźwirzyno',
    ),
    'havet': const HotelInfo(
      name: 'Havet Hotel Resort & Spa',
      address: 'ul. Pionierów 2',
      city: 'Dźwirzyno',
    ),
  };

  /// Pamięć podręczna w RAM
  static Map<String, HotelInfo>? _cachedHotels;

  /// Czyści pamięć podręczną (wykorzystywane m.in. w testach)
  static void resetCache() {
    _cachedHotels = null;
  }

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
    bool fromList = false,
  }) async {
    final all = await loadAll();
    final key = normalizeKey(name);

    final info = HotelInfo(
      name: name.trim(),
      address: address.trim(),
      city: city.trim(),
      note: note?.trim(),
      fromList: fromList,
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
  /// W tym dedykowany box na samej górze: "Dodane z listy"
  /// Do "Dodane z listy" trafiają wszystkie hotele, które nie mają jeszcze wpisanego dokładnego adresu
  /// (czyli dodane z automatu lub z karty pojazdu bez adresu).
  static Map<String, List<HotelInfo>> getHotelsGroupedByCitySync() {
    final all = getAllHotelsSync().values.toList();
    all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final Map<String, List<HotelInfo>> grouped = {};

    // 1. Wszystkie hotele bez adresu (lub z flagą fromList) trafiają do "Dodane z listy"
    final pendingHotels = all.where((h) => h.address.trim().isEmpty || h.fromList).toList();
    if (pendingHotels.isNotEmpty) {
      grouped['Dodane z listy'] = pendingHotels;
    }

    // 2. Do poszczególnych miast trafiają WYŁĄCZNIE hotele w pełni zweryfikowane (mające wpisany adres i niebędące 'fromList')
    for (final hotel in all) {
      final isPending = hotel.address.trim().isEmpty || hotel.fromList;
      if (isPending) continue; // Nie wyświetlaj w miastach, dopóki adres nie zostanie uzupełniony!

      String rawCity = hotel.city.trim();
      String city = rawCity.isNotEmpty
          ? (rawCity.length > 1
              ? '${rawCity[0].toUpperCase()}${rawCity.substring(1)}'
              : rawCity.toUpperCase())
          : 'Pozostałe';
      grouped.putIfAbsent(city, () => []).add(hotel);
    }

    // Sortowanie miast: "Dodane z listy" zawsze na pierwszym miejscu!
    const priorityCities = [
      'Dodane z listy',
      'Kołobrzeg',
      'Świnoujście',
      'Międzyzdroje',
      'Ustronie Morskie',
      'Mrzeżyno',
      'Dźwirzyno',
      'Pobierowo',
      'Rewal',
      'Niechorze',
    ];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Dodane z listy') return -1;
        if (b == 'Dodane z listy') return 1;
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

  /// Wykrywa i automatycznie rejestruje nowe hotele z importowanych tras
  /// Zwraca liczbę nowo dodanych obiektów.
  static Future<int> ingestHotelsFromRoutes(Iterable<dynamic> routes) async {
    final all = await loadAll();
    int addedCount = 0;

    for (final route in routes) {
      // Dynamiczna weryfikacja pola stops w obiekcie BusRoute
      final stops = (route as dynamic).stops;
      if (stops is! Iterable) continue;

      for (final stop in stops) {
        final rawResort = (stop as dynamic).resort?.toString().trim() ?? '';
        if (rawResort.isEmpty) continue;

        final key = normalizeKey(rawResort);
        if (key.isEmpty) continue;

        // Jeśli hotel już istnieje w katalogu (dokładnie lub wariantowo) i ma adres, nie nadpisujemy
        final existing = getCachedHotel(rawResort);
        if (existing != null && existing.address.isNotEmpty) {
          continue;
        }

        // Wydobywamy miejscowość z nawiasu np. "Verano (Kołobrzeg)" lub "San (Ustronie Morskie)"
        String parsedCity = '';
        String cleanName = rawResort;
        final parenMatch = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(rawResort);
        if (parenMatch != null) {
          cleanName = parenMatch.group(1)?.trim() ?? rawResort;
          parsedCity = parenMatch.group(2)?.trim() ?? '';
        }

        // Jeśli miejscowość nie jest w nawiasie, sprawdzamy czy w nazwie jest znane miasto nadmorskie
        if (parsedCity.isEmpty) {
          const knownCities = [
            'Pobierowo',
            'Świnoujście',
            'Międzyzdroje',
            'Ustronie Morskie',
            'Mrzeżyno',
            'Dźwirzyno',
            'Grzybowo',
            'Międzywodzie',
            'Dziwnów',
            'Rewal',
            'Pogorzelica',
            'Niechorze',
            'Sianożęty',
            'Kołobrzeg',
          ];
          for (final c in knownCities) {
            // Dopasowujemy jako osobne słowo lub część nazwy (np. "Bagińscy Pobierowo" -> "Pobierowo")
            final reg = RegExp(r'\b' + RegExp.escape(c) + r'\b', caseSensitive: false);
            if (reg.hasMatch(rawResort) || rawResort.toLowerCase().contains(c.toLowerCase())) {
              parsedCity = c;
              // Usuwamy miasto z samej nazwy hotelu, jeśli występuje na końcu lub początku
              cleanName = cleanName.replaceAll(RegExp(r'\b' + RegExp.escape(c) + r'\b', caseSensitive: false), '').trim();
              break;
            }
          }
        }

        // Jeśli nadal puste, oznaczamy jako 'Do ustalenia'
        if (parsedCity.isEmpty) {
          parsedCity = 'Do ustalenia';
        }

        // Jeśli obiekt istnieje, ale nie miał miasta, aktualizujemy go
        if (all.containsKey(key)) {
          final current = all[key]!;
          if (current.city.isEmpty) {
            all[key] = HotelInfo(
              name: current.name,
              address: current.address,
              city: parsedCity,
              note: current.note,
            );
            addedCount++;
          }
          continue;
        }

        // Nowy hotel – dodajemy go do stałej bazy z flagą fromList = true
        all[key] = HotelInfo(
          name: cleanName,
          address: '', // Adres do ręcznego uzupełnienia przez kierowcę
          city: parsedCity,
          note: 'Dodano z listy przejazdu',
          fromList: true,
        );
        addedCount++;
      }
    }

    if (addedCount > 0) {
      _cachedHotels = all;
      try {
        final prefs = await SharedPreferences.getInstance();
        final toSave = all.map((k, v) => MapEntry(k, v.toJson()));
        await prefs.setString(permanentStorageKey, jsonEncode(toSave));
      } catch (_) {}
    }

    return addedCount;
  }

  /// Wyszukuje online adres obiektu (OpenStreetMap / Nominatim)
  /// Zwraca obiekt z dopasowanym adresem, ulicą i numerem
  static Future<String?> lookupOnlineAddress({
    required String hotelName,
    required String city,
  }) async {
    final cleanName = hotelName.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    if (cleanName.isEmpty) return null;

    final queries = [
      '$cleanName $city',
      'Hotel $cleanName $city',
      'Sanatorium $cleanName $city',
      '$cleanName $city Polska',
      cleanName,
    ];

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);

    for (final q in queries) {
      try {
        final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&addressdetails=1&limit=3');
        final req = await client.getUrl(uri);
        req.headers.set('User-Agent', 'BalticBusDriverApp/1.0 (biuro@balticbus.pl)');
        req.headers.set('Accept', 'application/json');

        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final list = jsonDecode(body) as List<dynamic>;
          if (list.isNotEmpty) {
            for (final item in list) {
              final map = item as Map<String, dynamic>;
              final addr = map['address'] as Map<String, dynamic>?;
              if (addr != null) {
                final road = addr['road'] as String? ?? addr['pedestrian'] as String? ?? addr['street'] as String?;
                final houseNumber = addr['house_number'] as String?;
                if (road != null && road.isNotEmpty) {
                  return houseNumber != null ? 'ul. $road $houseNumber' : 'ul. $road';
                }
              }
              final displayName = map['display_name'] as String?;
              if (displayName != null && displayName.isNotEmpty) {
                final parts = displayName.split(',');
                if (parts.length >= 2) {
                  return parts.take(2).join(',').trim();
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    // 2. Jeśli Nominatim nie zwrócił ulicy, sprawdzamy zbiór znanych hoteli
    final local = getCachedHotel(cleanName);
    if (local != null && local.address.isNotEmpty) {
      return local.address;
    }

    return null;
  }
}

