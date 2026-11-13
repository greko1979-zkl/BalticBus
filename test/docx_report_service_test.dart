import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balticbus/models/route_models.dart';
import 'package:balticbus/services/docx_report_service.dart';

void main() {
  test('DocxReportService generates valid OpenXML docx with tblGrid and valid tc/sectPr structure', () {
    final summary = WeekendTripSummary(
      busCode: 'BB.01',
      dateRange: '01.08 - 02.08.2026',
      driverName: 'Jan Kowalski',
      driverPhone: '123 456 789',
      vehicleModel: 'Mercedes-Benz Vito',
      registrationNumber: 'GA 12345',
      advanceEur: 200,
      advancePln: 500,
      saturdayRoute: BusRoute(
        id: '1',
        code: 'BB.01',
        title: 'Sobota 01.08.2026',
        vehicleModel: 'Mercedes-Benz Vito',
        registrationNumber: 'GA 12345',
        driverName: 'Jan Kowalski',
        driverPhone: '123 456 789',
        date: '01.08.2026',
        direction: 'PL-DE',
        plannedDistanceKm: 1200,
        stops: [],
        breaks: [
          DriverBreak(
            id: 'b1',
            startTime: DateTime(2026, 8, 1, 12, 0),
            endTime: DateTime(2026, 8, 1, 12, 45),
          ),
        ],
        refuelings: [
          RefuelingEntry(
            id: 'e1',
            odometerKm: 100500,
            liters: 50,
            fuelType: 'Diesel (ON)',
            amount: 350.0,
            currency: 'PLN',
            stationName: 'Orlen',
            timestamp: DateTime(2026, 8, 1, 10, 0),
          ),
          RefuelingEntry(
            id: 'e2',
            odometerKm: 101000,
            liters: 45,
            fuelType: 'Diesel (ON)',
            amount: 80.0,
            currency: 'EUR',
            stationName: 'Shell',
            timestamp: DateTime(2026, 8, 1, 15, 0),
          ),
        ],
        startOdometerKm: 100000,
        endOdometerKm: 101200,
      ),
      sundayRoute: BusRoute(
        id: '2',
        code: 'BB.01',
        title: 'Niedziela 02.08.2026',
        vehicleModel: 'Mercedes-Benz Vito',
        registrationNumber: 'GA 12345',
        driverName: 'Jan Kowalski',
        driverPhone: '123 456 789',
        date: '02.08.2026',
        direction: 'DE-PL',
        plannedDistanceKm: 1200,
        stops: [],
        breaks: [
          DriverBreak(
            id: 'b2',
            startTime: DateTime(2026, 8, 2, 11, 30),
            endTime: DateTime(2026, 8, 2, 12, 15),
          ),
        ],
        refuelings: [],
        startOdometerKm: 101200,
        endOdometerKm: 102450,
      ),
    );

    final bytes = DocxReportService.generatePlanJazdyDocxBytes(summary);
    expect(bytes.isNotEmpty, isTrue);

    // Weryfikacja archiwum Zip
    final archive = ZipDecoder().decodeBytes(bytes);
    final fileNames = archive.files.map((f) => f.name).toSet();

    expect(fileNames.contains('[Content_Types].xml'), isTrue);
    expect(fileNames.contains('_rels/.rels'), isTrue);
    expect(fileNames.contains('word/_rels/document.xml.rels'), isTrue);
    expect(fileNames.contains('word/document.xml'), isTrue);
    expect(fileNames.contains('word/styles.xml'), isTrue);
    expect(fileNames.contains('word/settings.xml'), isTrue);
    expect(fileNames.contains('word/webSettings.xml'), isTrue);
    expect(fileNames.contains('word/fontTable.xml'), isTrue);

    // Weryfikacja struktury XML
    final docFile = archive.findFile('word/document.xml')!;
    final docXml = utf8.decode(docFile.content as List<int>);

    // Sprawdzenie obecności tblGrid
    final tblMatches = RegExp(r'<w:tbl[ >]').allMatches(docXml).length;
    final tblGridMatches = RegExp(r'<w:tblGrid>').allMatches(docXml).length;
    expect(tblMatches, equals(10), reason: 'Dokument powinien zawierać 10 tabel');
    expect(tblGridMatches, equals(tblMatches), reason: 'Każda tabela musi zawierać w:tblGrid');

    // Sprawdzenie czy żadna komórka tc nie kończy się bezpośrednio tabelą </w:tbl></w:tc>
    expect(docXml.contains('</w:tbl></w:tc>'), isFalse,
        reason: 'Żadna komórka w:tc nie może kończyć się w:tbl bez końcowego w:p');

    // Sprawdzenie czy przed w:sectPr jest w:p
    expect(docXml.contains(RegExp(r'</w:tbl>\s*<w:p>[\s\S]*?</w:p>\s*<w:sectPr>')), isTrue,
        reason: 'Przed w:sectPr musi znajdować się paragraf w:p');

    // Nadpisujemy plik na Desktopie użytkownika, aby użytkownik miał natychmiast naprawiony plik
    final desktopFile = File('/Users/greko/Desktop/Plan_Jazdy_BB.01_01.08_-_02.08.2026.docx');
    desktopFile.writeAsBytesSync(bytes);
    expect(desktopFile.existsSync(), isTrue);
  });
}
