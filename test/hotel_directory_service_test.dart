import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balticbus/models/route_models.dart';
import 'package:balticbus/services/hotel_directory_service.dart';
import 'package:balticbus/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HotelDirectoryService.resetCache();
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

    test('ingestHotelsFromRoutes discovers and persists new resorts automatically', () async {
      final mockStops = [
        PassengerStop(
          order: 1,
          name: 'Jan Kowalski',
          address: 'Berlin',
          passengerCount: 1,
          phone: '',
          resort: 'Nowy Kurort (Dźwirzyno)',
          hotelTime: '08:00',
        ),
        PassengerStop(
          order: 2,
          name: 'Anna Nowak',
          address: 'Hamburg',
          passengerCount: 1,
          phone: '',
          resort: 'Meduza',
          hotelTime: '08:30',
        ),
        PassengerStop(
          order: 3,
          name: 'Piotr Zieliński',
          address: 'Bremen',
          passengerCount: 1,
          phone: '',
          resort: 'San', // Already exists in defaultHotels with address
          hotelTime: '09:00',
        ),
      ];

      final mockRoute = BusRoute(
        id: 'test_route',
        code: 'BB.01',
        title: 'Trasa testowa',
        date: '2026-08-01',
        direction: 'PL-DE',
        vehicleModel: 'Ford',
        registrationNumber: 'ZS1234',
        driverName: 'Kierowca Testowy',
        driverPhone: '123456789',
        plannedDistanceKm: 1200,
        stops: mockStops,
      );

      final added = await HotelDirectoryService.ingestHotelsFromRoutes([mockRoute]);
      expect(added, 2); // Nowy Kurort and Meduza added, San was not added again

      final kurort = HotelDirectoryService.getCachedHotel('Nowy Kurort');
      expect(kurort, isNotNull);
      expect(kurort!.name, 'Nowy Kurort');
      expect(kurort.city, 'Dźwirzyno');

      final meduza = HotelDirectoryService.getCachedHotel('Meduza');
      expect(meduza, isNotNull);
      expect(meduza!.name, 'Meduza');
      expect(meduza.fromList, isTrue);

      final grouped = HotelDirectoryService.getHotelsGroupedByCitySync();
      expect(grouped.containsKey('Dodane z listy'), isTrue);
      expect(grouped['Dodane z listy']!.any((h) => h.name == 'Nowy Kurort'), isTrue);
      expect(grouped['Dodane z listy']!.any((h) => h.name == 'Meduza'), isTrue);

      // Dopóki nie ma adresu, nie powinien się pojawiać w normalnych miastach
      expect(grouped['Dźwirzyno']?.any((h) => h.name == 'Nowy Kurort') ?? false, isFalse);
    });

    test('hotels with empty address are grouped in Dodane z listy until address is set', () async {
      await HotelDirectoryService.saveHotel(
        name: 'Hotel Bez Adresu',
        address: '',
        city: 'Kołobrzeg',
      );

      var grouped = HotelDirectoryService.getHotelsGroupedByCitySync();
      expect(grouped['Dodane z listy']!.any((h) => h.name == 'Hotel Bez Adresu'), isTrue);

      // Po wpisaniu adresu znika z "Dodane z listy"
      await HotelDirectoryService.saveHotel(
        name: 'Hotel Bez Adresu',
        address: 'ul. Nadbrzeżna 10',
        city: 'Kołobrzeg',
        fromList: false,
      );

      grouped = HotelDirectoryService.getHotelsGroupedByCitySync();
      final inPending = grouped['Dodane z listy']?.any((h) => h.name == 'Hotel Bez Adresu') ?? false;
      expect(inPending, isFalse);
    });
  });
}
