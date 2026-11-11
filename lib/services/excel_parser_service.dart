import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/route_models.dart';

class ExcelParserService {
  /// Wczytuje i parsuje domyślny plik z assets
  static Future<List<BusRoute>> loadFromAssets(
      [String path = 'assets/data/WEEK_01-02.08.2026.xlsx']) async {
    final bytes = await rootBundle.load(path);
    return parseExcelBytes(bytes.buffer.asUint8List());
  }

  /// Główna metoda parsująca bajty pliku Excel (.xlsx)
  static List<BusRoute> parseExcelBytes(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    // Szukamy arkusza "Rozklad jazdy" lub bierzemy pierwszy
    final sheetName = excel.tables.keys.firstWhere(
      (k) => k.toLowerCase().contains('rozklad') || k.toLowerCase().contains('jazdy'),
      orElse: () => excel.tables.keys.first,
    );

    final sheet = excel.tables[sheetName];
    if (sheet == null || sheet.maxRows == 0) return [];

    final rows = sheet.rows;
    final List<BusRoute> allRoutes = [];

    // 1. Znajdujemy wiersze nagłówków poszczególnych busów (np. BB.01, BB.02)
    final List<int> busHeaderRows = [];
    for (int r = 0; r < rows.length; r++) {
      final cellA = _getVal(rows, r, 0);
      if (cellA.startsWith('BB.')) {
        busHeaderRows.add(r);
      }
    }

    // 2. Przechodzimy przez każdy blok busa
    for (int i = 0; i < busHeaderRows.length; i++) {
      final startRow = busHeaderRows[i];
      final endRow = (i + 1 < busHeaderRows.length)
          ? busHeaderRows[i + 1]
          : rows.length;

      // Parsujemy lewą stronę (Sobota: PL ➔ DE)
      final leftRoute = _parseBusSide(
        rows: rows,
        startRow: startRow,
        endRow: endRow,
        isLeftSide: true,
      );
      if (leftRoute != null) {
        allRoutes.add(leftRoute);
      }

      // Parsujemy prawą stronę (Niedziela: DE ➔ PL)
      final rightRoute = _parseBusSide(
        rows: rows,
        startRow: startRow,
        endRow: endRow,
        isLeftSide: false,
      );
      if (rightRoute != null) {
        allRoutes.add(rightRoute);
      }
    }

    return allRoutes;
  }

  static BusRoute? _parseBusSide({
    required List<List<Data?>> rows,
    required int startRow,
    required int endRow,
    required bool isLeftSide,
  }) {
    // Indeksy kolumn zależne od strony:
    // Lewa strona (PL-DE): A=0, B=1, C=2, D=3, E=4, F=5, G=6, H=7, I=8, J=9, K=10, L=11
    // Prawa strona (DE-PL): N=13, O=14, P=15, Q=16, R=17, S=18, T=19, U=20, V=21, W=22, X=23, Y=24
    final offset = isLeftSide ? 0 : 13;

    final busCode = _getVal(rows, startRow, offset); // np. BB.01
    final rawTitle = _getVal(rows, startRow, offset + 2); // np. Rozklad_2026-08-01_PL-DE

    if (busCode.isEmpty || rawTitle.isEmpty) return null;

    // Odczyt daty i kierunku z tytułu (np. Rozklad_2026-08-01_PL-DE)
    final dateMatch = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(rawTitle);
    final date = dateMatch?.group(0) ?? (isLeftSide ? '2026-08-01' : '2026-08-02');
    final isPLtoDE = rawTitle.toUpperCase().contains('PL-DE') || isLeftSide;
    final direction = isPLtoDE ? 'PL-DE' : 'DE-PL';

    // Wiersz pod nagłówkiem (startRow + 1) zawiera dystans, auto i kierowcę
    final distRaw = _getVal(rows, startRow + 1, isLeftSide ? 1 : 14); // np. Długość trasy: 1290 km
    final vehicleRaw = _getVal(rows, startRow + 1, isLeftSide ? 3 : 16); // np. Ford Custom / ZS_615RU
    final driverRaw = _getVal(rows, startRow + 1, isLeftSide ? 7 : 20); // np. Grzesiek Korowajczyk / tel. 603-864-281

    final plannedKm = _parseDistanceKm(distRaw);
    final vehicle = _parseVehicle(vehicleRaw);
    final driver = _parseDriver(driverRaw);

    // Link do trasy Google Maps (zazwyczaj w kolumnie AA = 26 lub sąsiednich)
    String? googleMapsUrl;
    for (int col = 25; col <= 28; col++) {
      final val = _getVal(rows, startRow + (isLeftSide ? 0 : 1), col);
      if (val.startsWith('http')) {
        googleMapsUrl = val;
        break;
      }
    }

    final List<PassengerStop> stops = [];
    final List<String> specialNotes = [];
    final List<TransferPoint> transferPoints = [];

    // Przeszukujemy wiersze wewnątrz bloku
    for (int r = startRow + 2; r < endRow; r++) {
      final colOrderOrNote = _getVal(rows, r, offset);
      final colName = _getVal(rows, r, offset + 1);

      // Czy to wiersz pasażera (liczba porządkowa w pierwszej kolumnie i nazwisko w drugiej)
      final orderNum = int.tryParse(colOrderOrNote);
      if (orderNum != null && colName.isNotEmpty && !colName.toLowerCase().contains('imie')) {
        final address = _getVal(rows, r, offset + 2);
        final countRaw = _getVal(rows, r, offset + 3);
        final phone = _getVal(rows, r, offset + 4);
        final comment = _getVal(rows, r, offset + 5);
        final office = _getVal(rows, r, offset + 6);
        final resort = _getVal(rows, r, offset + 7);
        final driveTime = _getVal(rows, r, offset + 10);
        final distance = _getVal(rows, r, offset + 11);

        stops.add(
          PassengerStop(
            order: orderNum,
            name: colName,
            address: address,
            passengerCount: int.tryParse(countRaw) ?? 1,
            phone: _cleanPhone(phone),
            comment: comment,
            office: office,
            resort: resort,
            driveTime: driveTime.isNotEmpty ? driveTime : null,
            distance: distance.isNotEmpty ? distance : null,
          ),
        );
      } else if (colOrderOrNote.isNotEmpty && !colOrderOrNote.startsWith('BB.')) {
        // To jest notatka lub punkt przesiadkowy (np. 09:30 / MOYA_RYMARSKA)
        final timeMatch = RegExp(r'\b\d{1,2}:\d{2}\b').firstMatch(colOrderOrNote);
        if (timeMatch != null) {
          final time = timeMatch.group(0)!;
          transferPoints.add(
            TransferPoint(
              time: time,
              location: colOrderOrNote,
              instruction: colName.isNotEmpty ? colName : 'Punkt zbiórki / przesiadki',
            ),
          );
        } else if (!colOrderOrNote.toLowerCase().contains('imie') &&
                   !colOrderOrNote.toLowerCase().contains('adres')) {
          specialNotes.add(colOrderOrNote);
        }
      }
    }

    final formattedTitle = isPLtoDE
        ? 'Wywóz: $date (PL ➔ DE)'
        : 'Przywóz: $date (DE ➔ PL)';

    return BusRoute(
      id: '${busCode.toLowerCase()}_${date.replaceAll('-', '_')}_${direction.toLowerCase()}',
      code: busCode,
      title: formattedTitle,
      date: date,
      direction: direction,
      vehicleModel: vehicle.model,
      registrationNumber: vehicle.plate,
      driverName: driver.name,
      driverPhone: driver.phone,
      plannedDistanceKm: plannedKm,
      specialNotes: specialNotes,
      stops: stops,
      transferPoints: transferPoints,
      googleMapsUrl: googleMapsUrl,
    );
  }

  static String _getVal(List<List<Data?>> rows, int r, int c) {
    if (r < 0 || r >= rows.length) return '';
    final row = rows[r];
    if (c < 0 || c >= row.length) return '';
    final cell = row[c];
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }

  static int _parseDistanceKm(String raw) {
    final match = RegExp(r'(\d+)\s*km', caseSensitive: false).firstMatch(raw);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }

  static ({String model, String plate}) _parseVehicle(String raw) {
    if (raw.isEmpty) return (model: 'Bus', plate: '');
    final parts = raw.split('/');
    if (parts.length > 1) {
      return (model: parts[0].trim(), plate: parts[1].trim());
    }
    return (model: raw.trim(), plate: '');
  }

  static ({String name, String phone}) _parseDriver(String raw) {
    if (raw.isEmpty) return (name: 'Kierowca', phone: '');
    final parts = raw.split('/');
    final name = parts[0].trim();
    String phone = '';
    for (final p in parts) {
      if (p.toLowerCase().contains('tel') || RegExp(r'\d{3}').hasMatch(p)) {
        phone = p.replaceAll(RegExp(r'tel\.?|phone:?', caseSensitive: false), '').trim();
        break;
      }
    }
    return (name: name, phone: phone);
  }

  static String _cleanPhone(String raw) {
    if (raw.isEmpty) return '';
    // Jeśli numer zaczyna się od niemieckiej komórki bez prefiksu (np. 1775761991), dodajemy +49
    if (raw.startsWith('15') || raw.startsWith('16') || raw.startsWith('17')) {
      return '+49 $raw';
    }
    return raw;
  }
}
