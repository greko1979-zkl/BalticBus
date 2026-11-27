import 'dart:convert';
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

  /// Predefiniowany katalog popularnych hoteli i ośrodków nadmorskich oraz uzdrowiskowych z tras BalticBus
  static final Map<String, HotelInfo> defaultHotels = {
    // === KOŁOBRZEG ===
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
    'verano': const HotelInfo(
      name: 'Verano',
      address: 'ul. Sikorskiego 8',
      city: 'Kołobrzeg',
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
    'olymp 3': const HotelInfo(
      name: 'Olymp 3',
      address: 'ul. Spacerowa 4',
      city: 'Kołobrzeg',
    ),
    'olymp 4': const HotelInfo(
      name: 'Olymp 4',
      address: 'ul. Koszalińska 17',
      city: 'Kołobrzeg',
    ),
    'koral live': const HotelInfo(
      name: 'Koral Live',
      address: 'ul. Kościuszki 10',
      city: 'Kołobrzeg',
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
    'perła bałtyku kg': const HotelInfo(
      name: 'Perła Bałtyku KG',
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
    'nad parsętą': const HotelInfo(
      name: 'Nad Parsętą',
      address: 'ul. Szpitalna 1',
      city: 'Kołobrzeg',
      note: 'Sanatorium Nad Parsętą',
    ),
    'park hotel': const HotelInfo(
      name: 'Park Hotel',
      address: 'ul. Koszalińska 1',
      city: 'Kołobrzeg',
    ),
    'monalisa': const HotelInfo(
      name: 'MonaLisa',
      address: 'ul. Lazurowa 1',
      city: 'Kołobrzeg',
      note: 'MonaLisa Medical SPA Podczele',
    ),
    'radisson kg': const HotelInfo(
      name: 'Radisson KG',
      address: 'ul. Morawskiego 1',
      city: 'Kołobrzeg',
      note: 'Radisson Resort Kołobrzeg',
    ),
    'radisson': const HotelInfo(
      name: 'Radisson Resort',
      address: 'ul. Morawskiego 1',
      city: 'Kołobrzeg',
    ),
    'wistom': const HotelInfo(
      name: 'Wistom',
      address: 'ul. Chrobrego 14',
      city: 'Kołobrzeg',
    ),
    'lech': const HotelInfo(
      name: 'Lech',
      address: 'ul. Korzeniowskiego 1',
      city: 'Kołobrzeg',
      note: 'Sanatorium Lech',
    ),
    'kielczanka': const HotelInfo(
      name: 'Kielczanka',
      address: 'ul. Rodziewiczówny 15',
      city: 'Kołobrzeg',
      note: 'Sanatorium Kielczanka',
    ),
    'diva': const HotelInfo(
      name: 'Diva',
      address: 'ul. Kościuszki 16',
      city: 'Kołobrzeg',
      note: 'Hotel Diva SPA',
    ),
    'podczele': const HotelInfo(
      name: 'Podczele',
      address: 'ul. Kresowa 6',
      city: 'Kołobrzeg',
    ),
    'unii lub. 22': const HotelInfo(
      name: 'Unii Lub. 22',
      address: 'ul. Unii Lubelskiej 22',
      city: 'Kołobrzeg',
    ),

    // === ŚWINOUJŚCIE ===
    'cesarskie o.': const HotelInfo(
      name: 'Cesarskie O.',
      address: 'ul. Stanisława Wyspiańskiego 34A',
      city: 'Świnoujście',
      note: 'Cesarskie Ogrody',
    ),
    'cesarskie ogrody': const HotelInfo(
      name: 'Cesarskie Ogrody',
      address: 'ul. Stanisława Wyspiańskiego 34A',
      city: 'Świnoujście',
    ),
    'platino mare': const HotelInfo(
      name: 'Platino Mare',
      address: 'ul. Stefana Żeromskiego 78',
      city: 'Świnoujście',
    ),
    'sobótka': const HotelInfo(
      name: 'Sobótka',
      address: 'ul. Henryka Sienkiewicza 13',
      city: 'Świnoujście',
    ),
    'avangard resort': const HotelInfo(
      name: 'Avangard Resort',
      address: 'ul. Uzdrowiskowa 5',
      city: 'Świnoujście',
    ),
    'rybniczanka': const HotelInfo(
      name: 'Rybniczanka',
      address: 'ul. Jana Kasprowicza 14',
      city: 'Świnoujście',
    ),
    'alga': const HotelInfo(
      name: 'Alga',
      address: 'ul. Juliusza Słowackiego 5',
      city: 'Świnoujście',
    ),
    'marisol': const HotelInfo(
      name: 'MariSol',
      address: 'ul. Bolesława Chrobrego 42',
      city: 'Świnoujście',
    ),
    'rezydent resort': const HotelInfo(
      name: 'Rezydent Resort',
      address: 'ul. Uzdrowiskowa 1A',
      city: 'Świnoujście',
    ),
    'villa rezydent': const HotelInfo(
      name: 'Villa Rezydent',
      address: 'ul. Uzdrowiskowa 1',
      city: 'Świnoujście',
    ),
    'polaris': const HotelInfo(
      name: 'Polaris',
      address: 'ul. Juliusza Słowackiego 33',
      city: 'Świnoujście',
    ),
    'polaris 2': const HotelInfo(
      name: 'Polaris 2',
      address: 'ul. Juliusza Słowackiego 33',
      city: 'Świnoujście',
    ),
    'polaris 3': const HotelInfo(
      name: 'Polaris 3',
      address: 'ul. Stefana Żeromskiego 26',
      city: 'Świnoujście',
    ),
    'el-pak': const HotelInfo(
      name: 'El-Pak',
      address: 'ul. Henryka Sienkiewicza 7',
      city: 'Świnoujście',
    ),
    'el pak': const HotelInfo(
      name: 'El-Pak',
      address: 'ul. Henryka Sienkiewicza 7',
      city: 'Świnoujście',
    ),
    'hamilton': const HotelInfo(
      name: 'Hamilton',
      address: 'ul. Uzdrowiskowa 25',
      city: 'Świnoujście',
      note: 'Hotel Hamilton',
    ),
    'interferie': const HotelInfo(
      name: 'Interferie',
      address: 'ul. Uzdrowiskowa 15',
      city: 'Świnoujście',
      note: 'Interferie Medical SPA',
    ),
    'trzy wyspy': const HotelInfo(
      name: 'Trzy Wyspy',
      address: 'ul. Cieszkowskiego 1',
      city: 'Świnoujście',
    ),
    'ottaviano': const HotelInfo(
      name: 'Ottaviano',
      address: 'ul. Monte Cassino 3',
      city: 'Świnoujście',
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
    'west baltic': const HotelInfo(
      name: 'West Baltic',
      address: 'ul. Stefana Żeromskiego 22',
      city: 'Świnoujście',
      note: 'West Baltic Resort',
    ),
    'baltic spa': const HotelInfo(
      name: 'Baltic Spa',
      address: 'ul. Trentowskiego 4',
      city: 'Świnoujście',
    ),
    'gold': const HotelInfo(
      name: 'Gold',
      address: 'ul. Uzdrowiskowa 3',
      city: 'Świnoujście',
    ),
    'afrodyta': const HotelInfo(
      name: 'Afrodyta',
      address: 'ul. Grunwaldzka 10',
      city: 'Świnoujście',
    ),
    'afrodyta spa': const HotelInfo(
      name: 'Afrodyta Spa',
      address: 'ul. Grunwaldzka 10',
      city: 'Świnoujście',
    ),
    'cis': const HotelInfo(
      name: 'Cis',
      address: 'ul. Kościuszki 4',
      city: 'Świnoujście',
    ),
    'phoenix': const HotelInfo(
      name: 'Phoenix',
      address: 'ul. Konopnickiej 5',
      city: 'Świnoujście',
    ),
    'atol': const HotelInfo(
      name: 'Atol',
      address: 'ul. Rybaki 1',
      city: 'Świnoujście',
    ),
    'topaz': const HotelInfo(
      name: 'Topaz',
      address: 'ul. Chrobrego 26',
      city: 'Świnoujście',
    ),
    'irys': const HotelInfo(
      name: 'Irys',
      address: 'ul. Kasprowicza 10',
      city: 'Świnoujście',
    ),
    'ewerdin': const HotelInfo(
      name: 'Ewerdin',
      address: 'ul. Cieszkowskiego 4',
      city: 'Świnoujście',
    ),
    'promenada': const HotelInfo(
      name: 'Promenada',
      address: 'ul. Żeromskiego 20',
      city: 'Świnoujście',
    ),
    'promenada i': const HotelInfo(
      name: 'Promenada I',
      address: 'ul. Żeromskiego 20',
      city: 'Świnoujście',
    ),

    // === MIĘDZYZDROJE ===
    'chabinka mdz': const HotelInfo(
      name: 'Chabinka MDZ',
      address: 'ul. Gryfa Pomorskiego 74',
      city: 'Międzyzdroje',
    ),
    'chabinka': const HotelInfo(
      name: 'Chabinka',
      address: 'ul. Gryfa Pomorskiego 74',
      city: 'Międzyzdroje',
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
    'vestina': const HotelInfo(
      name: 'Vestina',
      address: 'Promenada Gwiazd 30',
      city: 'Międzyzdroje',
    ),
    'trofana': const HotelInfo(
      name: 'Trofana',
      address: 'ul. Gryfa Pomorskiego 70',
      city: 'Międzyzdroje',
    ),
    'bielik': const HotelInfo(
      name: 'Bielik',
      address: 'ul. Rybicka 2',
      city: 'Międzyzdroje',
    ),

    // === USTRONIE MORSKIE ===
    'max': const HotelInfo(
      name: 'Max',
      address: 'ul. Morska 16',
      city: 'Ustronie Morskie',
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
    'erania': const HotelInfo(
      name: 'Erania',
      address: 'Malechowo 26A',
      city: 'Ustronie Morskie',
    ),

    // === DŹWIRZYNO ===
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
    'akces': const HotelInfo(
      name: 'Akces',
      address: 'ul. Piastowska 5',
      city: 'Dźwirzyno',
      note: 'Akces Medical Spa',
    ),

    // === ŚWIERADÓW-ZDRÓJ / JELENIA GÓRA ===
    'st. lukas': const HotelInfo(
      name: 'St. Lukas',
      address: 'ul. Sienkiewicza 21',
      city: 'Świeradów Zdrój',
    ),
    'magnolia 3': const HotelInfo(
      name: 'Magnolia 3',
      address: 'ul. Wczasowa 1',
      city: 'Świeradów Zdrój',
    ),
    'dom zdrojowy': const HotelInfo(
      name: 'Dom Zdrojowy',
      address: 'ul. 3 Maja 1',
      city: 'Świeradów Zdrój',
    ),
    'dom zdrojowy śwr': const HotelInfo(
      name: 'Dom Zdrojowy ŚWR',
      address: 'ul. 3 Maja 1',
      city: 'Świeradów Zdrój',
    ),
    'buczyński spa': const HotelInfo(
      name: 'Buczyński Spa',
      address: 'ul. Prusa 2',
      city: 'Świeradów Zdrój',
      note: 'Buczyński Medical & Spa',
    ),
    'berliner': const HotelInfo(
      name: 'Berliner',
      address: 'ul. Piłsudskiego 8',
      city: 'Świeradów Zdrój',
    ),
    'kaja': const HotelInfo(
      name: 'Kaja',
      address: 'ul. Sienkiewicza 15',
      city: 'Świeradów Zdrój',
    ),
    'dom sandi': const HotelInfo(
      name: 'Dom Sandi',
      address: 'ul. Wczasowa 4',
      city: 'Świeradów Zdrój',
    ),
    'długi dom': const HotelInfo(
      name: 'Długi Dom',
      address: 'ul. Ściegiennego 10',
      city: 'Jelenia Góra',
      note: 'Cieplice',
    ),
    'długi dom jg': const HotelInfo(
      name: 'Długi Dom JG',
      address: 'ul. Ściegiennego 10',
      city: 'Jelenia Góra',
      note: 'Cieplice',
    ),

    // === INNE MIEJSCOWOŚCI (Mrzeżyno, Pobierowo, Niechorze, Mielno, Międzywodzie, Dziwnówek) ===
    'wydma spa': const HotelInfo(
      name: 'Wydma Spa',
      address: 'ul. Marynarska 2',
      city: 'Mrzeżyno',
    ),
    'bagińscy pob': const HotelInfo(
      name: 'Bagińscy POB',
      address: 'ul. Grunwaldzka 89',
      city: 'Pobierowo',
      note: 'Bagińscy Spa Pobierowo',
    ),
    'bagińscy spa': const HotelInfo(
      name: 'Bagińscy Spa',
      address: 'ul. Grunwaldzka 89',
      city: 'Pobierowo',
    ),
    'paula spa': const HotelInfo(
      name: 'Paula SPA',
      address: 'ul. Wojska Polskiego 17',
      city: 'Pobierowo',
    ),
    'chimera': const HotelInfo(
      name: 'Chimera',
      address: 'ul. Spacerowa 5',
      city: 'Niechorze',
      note: 'Chimera SPA',
    ),
    'millennium': const HotelInfo(
      name: 'Millennium',
      address: 'ul. Bałtycka 13',
      city: 'Międzywodzie',
      note: 'Ośrodek Millennium',
    ),
    'dziwnówek': const HotelInfo(
      name: 'Dziwnówek',
      address: 'ul. Wolności 4',
      city: 'Dziwnówek',
    ),
    'unitral': const HotelInfo(
      name: 'Unitral',
      address: 'ul. Piastów 6',
      city: 'Mielno',
      note: 'Hotel Unitral',
    ),
    'stargard': const HotelInfo(
      name: 'Stargard',
      address: 'ul. Szczecińska 101',
      city: 'Stargard',
      note: 'Punkt Przesiadkowy',
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
    // 1. Usunięcie nawiasów np. "Verano (Kołobrzeg)" -> "verano"
    final parenIdx = clean.indexOf('(');
    if (parenIdx != -1) {
      clean = clean.substring(0, parenIdx).trim();
    }
    // 2. Usunięcie cudzysłowów na końcach
    clean = clean.replaceAll(RegExp(r'''['"„”]+$'''), '').trim();
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
          final loaded = HotelInfo.fromJson(entry.value as Map<String, dynamic>);
          // ZABEZPIECZENIE: jeśli w pamięci urządzenia jest wpis bez adresu,
          // a w katalogu domyślnym mamy już zweryfikowany adres, ZACHOWAJ adres z katalogu domyślnego!
          if (loaded.address.trim().isEmpty && map.containsKey(entry.key) && map[entry.key]!.address.trim().isNotEmpty) {
            continue;
          }
          map[entry.key] = loaded;
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

    // 1. Dokładne dopasowanie po znormalizowanym kluczu (jeśli ma adres)
    if (all.containsKey(key) && all[key]!.address.isNotEmpty) {
      return all[key];
    }

    // 2. Bezpośrednie dopasowanie po surowym kluczu w małych literach (jeśli ma adres)
    final rawLower = rawName.trim().toLowerCase();
    if (all.containsKey(rawLower) && all[rawLower]!.address.isNotEmpty) {
      return all[rawLower];
    }

    // 3. Sprawdzenie bez sufiksów miast (np. "kg", "śwr", "swr", "mdz", "pob", "jg")
    final stripped = key.replaceAll(RegExp(r'\s+(kg|śwr|swr|mdz|pob|jg|pl)$'), '').trim();
    if (stripped != key && all.containsKey(stripped) && all[stripped]!.address.isNotEmpty) {
      return all[stripped];
    }

    // 4. Szukanie wariantów ze zmapowanym adresem (ignorując wpisy bez adresu)
    for (final entry in all.entries) {
      if (entry.value.address.isEmpty) continue;
      if (entry.key == key || entry.key == stripped) return entry.value;
      if (key.length >= 4 && entry.key.length >= 4) {
        if (key.contains(entry.key) || entry.key.contains(key)) {
          return entry.value;
        }
      }
    }

    // 5. Szukanie po usunięciu znaków specjalnych, spacji i myślników
    final keyClean = key.replaceAll(RegExp(r'[\s\-_\.]'), '');
    for (final entry in all.entries) {
      if (entry.value.address.isEmpty) continue;
      final entryClean = entry.key.replaceAll(RegExp(r'[\s\-_\.]'), '');
      if (keyClean == entryClean ||
          (keyClean.length >= 4 && entryClean.length >= 4 &&
           (keyClean.contains(entryClean) || entryClean.contains(keyClean)))) {
        return entry.value;
      }
    }

    // 6. Bezpośrednie sprawdzenie w defaultHotels (gdyby SharedPreferences na urządzeniu miało stary pusty wpis)
    if (defaultHotels.containsKey(key) && defaultHotels[key]!.address.isNotEmpty) {
      return defaultHotels[key];
    }
    if (defaultHotels.containsKey(stripped) && defaultHotels[stripped]!.address.isNotEmpty) {
      return defaultHotels[stripped];
    }
    for (final entry in defaultHotels.entries) {
      if (entry.value.address.isEmpty) continue;
      if (key.length >= 4 && entry.key.length >= 4) {
        if (key.contains(entry.key) || entry.key.contains(key)) {
          return entry.value;
        }
      }
    }

    // 7. Ostateczny fallback: wpis bez adresu jeśli istnieje
    if (all.containsKey(key)) return all[key];
    if (all.containsKey(stripped)) return all[stripped];

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
      'Świeradów Zdrój',
      'Jelenia Góra',
      'Mielno',
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

        // Jeśli po odcięciu nawiasu nadal mamy dopasowanie do hotelu z adresem, pomijamy
        final cleanExisting = getCachedHotel(cleanName);
        if (cleanExisting != null && cleanExisting.address.isNotEmpty) {
          continue;
        }

        // Ignorujemy wpisy zbyt krótkie lub będące samą nazwą miasta
        final lowerClean = cleanName.toLowerCase();
        if (cleanName.length < 3 ||
            const ['kołobrzeg', 'świnoujście', 'międzyzdroje', 'ustronie morskie', 'mrzeżyno', 'dźwirzyno', 'pobierowo', 'rewal', 'niechorze', 'świeradów zdrój', 'świeradów-zdrój', 'jelenia góra', 'cieplice', 'mielno'].contains(lowerClean)) {
          continue;
        }

        // Jeśli miejscowość nie jest w nawiasie, sprawdzamy czy w nazwie jest znane miasto
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
            'Dziwnówek',
            'Dziwnów',
            'Rewal',
            'Pogorzelica',
            'Niechorze',
            'Sianożęty',
            'Kołobrzeg',
            'Świeradów-Zdrój',
            'Świeradów Zdrój',
            'Jelenia Góra',
            'Cieplice',
            'Mielno',
            'Stargard',
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
}


