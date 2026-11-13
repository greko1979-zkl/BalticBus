import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balticbus/services/hotel_directory_service.dart';
import 'package:balticbus/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HotelDirectoryService Tests', () {
    test('normalizeKey handles case and parentheses', () {
      expect(HotelDirectoryService.normalizeKey('San'), 'san');
      expect(HotelDirectoryService.normalizeKey('Verano (Kołobrzeg)'), 'verano');
      expect(HotelDirectoryService.normalizeKey('  Arka Medical SPA  '), 'arka medical spa');
    });

    test('getCachedHotel finds default resorts', () {
      final hotel = HotelDirectoryService.getCachedHotel('San');
      expect(hotel, isNotNull);
      expect(hotel!.name, 'San');
      expect(hotel.address, 'ul. Kasprowicza 24');
      expect(hotel.city, 'Kołobrzeg');
      expect(hotel.fullAddress, 'ul. Kasprowicza 24, Kołobrzeg');
    });

    test('getCachedHotel resolves resort with city suffix in parentheses', () {
      final hotel = HotelDirectoryService.getCachedHotel('Verano (Kołobrzeg)');
      expect(hotel, isNotNull);
      expect(hotel!.name, 'Verano');
      expect(hotel.address, 'ul. Sikorskiego 8');
      expect(hotel.city, 'Kołobrzeg');
    });

    test('saveHotel stores and retrieves custom hotel persistently', () async {
      await HotelDirectoryService.saveHotel(
        name: 'Bursztynek',
        address: 'ul. Plażowa 5',
        city: 'Dźwirzyno',
        note: 'Brama od strony lasu',
      );

      final found = HotelDirectoryService.getCachedHotel('Bursztynek');
      expect(found, isNotNull);
      expect(found!.address, 'ul. Plażowa 5');
      expect(found.city, 'Dźwirzyno');
      expect(found.fullAddress, 'ul. Plażowa 5, Dźwirzyno');
      expect(found.note, 'Brama od strony lasu');
    });

    test('clearAllTripData preserves permanent hotel directory', () async {
      // 1. Zapisujemy dane wyjazdu
      await StorageService.saveTripOdometers('BB.01', 1000, 2000);
      // 2. Zapisujemy hotel
      await HotelDirectoryService.saveHotel(
        name: 'Grand Hotel',
        address: 'ul. Nadmorska 1',
        city: 'Kołobrzeg',
      );

      // 3. Czyścimy dane wyjazdu
      await StorageService.clearAllTripData();

      // 4. Dane wyjazdu zniknęły
      final odo = await StorageService.loadTripOdometers('BB.01');
      expect(odo.start, isNull);
      expect(odo.end, isNull);

      // 5. Hotel wciąż istnieje w bazie stałej
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(HotelDirectoryService.permanentStorageKey), isTrue);

      final hotel = HotelDirectoryService.getCachedHotel('Grand Hotel');
      expect(hotel, isNotNull);
      expect(hotel!.address, 'ul. Nadmorska 1');
    });

    test('getHotelsGroupedByCitySync groups correctly by city', () {
      final grouped = HotelDirectoryService.getHotelsGroupedByCitySync();
      expect(grouped.containsKey('Kołobrzeg'), isTrue);
      expect(grouped.containsKey('Świnoujście'), isTrue);
      expect(grouped.containsKey('Międzyzdroje'), isTrue);

      final kolobrzegHotels = grouped['Kołobrzeg']!;
      expect(kolobrzegHotels.any((h) => h.name == 'San'), isTrue);
      expect(kolobrzegHotels.any((h) => h.name == 'Arka'), isTrue);
    });

    test('deleteHotel removes custom hotel from storage', () async {
      await HotelDirectoryService.saveHotel(
        name: 'Hotel DoUsuniecia',
        address: 'ul. Testowa 1',
        city: 'Kołobrzeg',
      );
      expect(HotelDirectoryService.getCachedHotel('Hotel DoUsuniecia'), isNotNull);

      await HotelDirectoryService.deleteHotel('Hotel DoUsuniecia');
      expect(HotelDirectoryService.getCachedHotel('Hotel DoUsuniecia'), isNull);
    });
  });
}
