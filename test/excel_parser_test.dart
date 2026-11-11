import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:balticbus/services/excel_parser_service.dart';

void main() {
  test('ExcelParserService parses WEEK_01-02.08.2026.xlsx correctly', () {
    final file = File('assets/data/WEEK_01-02.08.2026.xlsx');
    expect(file.existsSync(), isTrue);

    final bytes = file.readAsBytesSync();
    final routes = ExcelParserService.parseExcelBytes(bytes);

    expect(routes.isNotEmpty, isTrue);

    // Sprawdzamy obecność busów BB.01 do BB.10
    final busCodes = routes.map((r) => r.code).toSet();
    expect(busCodes.contains('BB.01'), isTrue);
    expect(busCodes.contains('BB.02'), isTrue);
    expect(busCodes.contains('BB.10'), isTrue);

    // Sprawdzamy BB.01 PL-DE
    final bb01 = routes.firstWhere((r) => r.code == 'BB.01' && r.direction == 'PL-DE');
    expect(bb01.vehicleModel, contains('Ford Custom'));
    expect(bb01.plannedDistanceKm, equals(1290));
    expect(bb01.stops.length, greaterThanOrEqualTo(5));
    expect(bb01.stops.first.name, contains('Angelika Borchert'));
  });
}
