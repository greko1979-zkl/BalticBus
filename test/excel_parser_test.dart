import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balticbus/services/excel_parser_service.dart';

void main() {
  test('ExcelParserService parses in-memory Excel schedule correctly', () {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet()!;
    excel.rename(sheetName, 'Rozklad jazdy');
    final sheet = excel['Rozklad jazdy'];

    void setCell(int row, int col, String value) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(value);
    }

    // === BB.01 ===
    // Lewa strona (PL-DE)
    setCell(0, 0, 'BB.01');
    setCell(0, 2, 'Rozklad_2026-08-01_PL-DE');
    setCell(1, 1, 'Długość trasy: 1290 km');
    setCell(1, 3, 'Ford Custom / ZS_615RU');
    setCell(1, 7, 'Grzesiek Korowajczyk / tel. 603-864-281');

    // Prawa strona (DE-PL)
    setCell(0, 13, 'BB.01');
    setCell(0, 15, 'Rozklad_2026-08-02_DE-PL');
    setCell(1, 14, 'Długość trasy: 1280 km');
    setCell(1, 16, 'Ford Custom / ZS_615RU');
    setCell(1, 20, 'Grzesiek Korowajczyk / tel. 603-864-281');

    // Nagłówki kolumn
    setCell(2, 1, 'Imie i nazwisko');
    setCell(2, 7, 'Osrodek');
    setCell(2, 8, 'Hotel');
    setCell(2, 9, 'Dom');

    // Pasażerowie PL-DE
    setCell(3, 0, '1');
    setCell(3, 1, 'Angelika Borchert');
    setCell(3, 2, '12345 Berlin, Musterstr. 1');
    setCell(3, 3, '2');
    setCell(3, 4, '+49 170 1234567');
    setCell(3, 7, 'Arka');
    setCell(3, 8, '07:15');
    setCell(3, 9, '13:45');

    setCell(4, 0, '2');
    setCell(4, 1, 'Jan Kowalski');
    setCell(4, 2, '20095 Hamburg, Hauptstr. 10');
    setCell(4, 3, '1');
    setCell(4, 7, 'San');
    setCell(4, 8, '07:45');
    setCell(4, 9, '15:00');

    // Pasażer DE-PL
    setCell(3, 13, '1');
    setCell(3, 14, 'Maria Nowak');
    setCell(3, 15, '10115 Berlin, Torstr. 5');
    setCell(3, 16, '1');
    setCell(3, 20, 'Verano');

    // === BB.02 ===
    setCell(6, 0, 'BB.02');
    setCell(6, 2, 'Rozklad_2026-08-01_PL-DE');
    setCell(7, 1, 'Długość trasy: 1150 km');
    setCell(7, 3, 'Mercedes Vito / ZS_999AA');
    setCell(7, 7, 'Janusz Kierowca / tel. 600-100-200');
    setCell(8, 0, '1');
    setCell(8, 1, 'Anna Nowak');
    setCell(8, 2, '18055 Rostock, Oststr. 3');
    setCell(8, 3, '1');

    final encoded = excel.encode()!;
    final routes = ExcelParserService.parseExcelBytes(Uint8List.fromList(encoded));

    expect(routes.isNotEmpty, isTrue);

    final busCodes = routes.map((r) => r.code).toSet();
    expect(busCodes.contains('BB.01'), isTrue);
    expect(busCodes.contains('BB.02'), isTrue);

    final bb01 = routes.firstWhere((r) => r.code == 'BB.01' && r.direction == 'PL-DE');
    expect(bb01.vehicleModel, contains('Ford Custom'));
    expect(bb01.plannedDistanceKm, equals(1290));
    expect(bb01.stops.length, equals(2));
    expect(bb01.stops.first.name, contains('Angelika Borchert'));
    expect(bb01.stops.first.passengerCount, equals(2));
    expect(bb01.stops.first.resort, equals('Arka'));
  });
}
