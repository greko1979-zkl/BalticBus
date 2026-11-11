import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:balticbus/models/route_models.dart';
import 'package:balticbus/services/docx_report_service.dart';
import 'package:balticbus/main.dart';

void main() {
  testWidgets('BalticBusApp smoke test - verifies route and vehicle information',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp());
    await tester.pumpAndSettle();

    // Verify vehicle information in title
    expect(find.textContaining('BB.01'), findsWidgets);
    expect(find.textContaining('Ford Custom'), findsWidgets);

    // Switch to Tab 1: Pojazd & Paliwo to verify driver details
    await tester.tap(find.text('Pojazd & Paliwo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Grzesiek Korowajczyk'), findsWidgets);

    // Switch back to Tab 0: Trasa
    await tester.tap(find.text('Trasa'));
    await tester.pumpAndSettle();

    // Scroll to find passenger (Angelika Borchert is in the current target hero card)
    await tester.scrollUntilVisible(
      find.text('Angelika Borchert'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Angelika Borchert'), findsOneWidget);
  });

  testWidgets('Driver break start and stop flow test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp());
    await tester.pumpAndSettle();

    // Switch to Tab 2: Raporty & Czas
    await tester.tap(find.text('Raporty & Czas'));
    await tester.pumpAndSettle();

    // Verify initial state: Rozpocznij pauzę button is visible
    expect(find.text('Rozpocznij pauzę'), findsOneWidget);

    // 1. Click "Rozpocznij pauzę" to start break
    await tester.tap(find.text('Rozpocznij pauzę'));
    await tester.pumpAndSettle();

    // Verify break is active: button says "Koniec pauzy"
    expect(find.text('Koniec pauzy'), findsOneWidget);

    // 2. Click "Koniec pauzy" to finish break
    await tester.tap(find.text('Koniec pauzy'));
    await tester.pumpAndSettle();

    // Verify break is ended: button shows "Rozpocznij pauzę" again
    expect(find.text('Rozpocznij pauzę'), findsOneWidget);
  });

  testWidgets('Plan Jazdy full weekend summary dialog test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp());
    await tester.pumpAndSettle();

    // Switch to Tab 2: Raporty & Czas
    await tester.tap(find.text('Raporty & Czas'));
    await tester.pumpAndSettle();

    // Verify "Otwórz pełny Plan Jazdy" action exists and click it
    expect(find.text('Otwórz pełny Plan Jazdy'), findsOneWidget);
    await tester.tap(find.text('Otwórz pełny Plan Jazdy'));
    await tester.pumpAndSettle();

    // Verify dialog title and elements matching physical card
    expect(find.textContaining('PLAN JAZDY • BB.01'), findsOneWidget);
    expect(find.text('STAN LICZNIKA'), findsOneWidget);
    expect(find.text('ZALICZKA:'), findsWidgets);
    expect(find.text('WYDATKI EURO:'), findsOneWidget);
    expect(find.text('WYDATKI ZŁ:'), findsOneWidget);
    expect(find.text('ODEBRANE OD GOŚCI:'), findsOneWidget);
    expect(find.text('ŚR. SPALANIE:'), findsOneWidget);
    expect(find.text('PRZERWY'), findsOneWidget);
    expect(find.text('Zapisz Word (.docx)'), findsOneWidget);
  });

  test('DocxReportService generates valid OpenXML docx archive matching template', () {
    final summary = WeekendTripSummary(
      busCode: 'BB.08',
      dateRange: '12.09 - 13.09.2026',
      driverName: 'Grzesiek Korowajczyk',
      driverPhone: '600-000-000',
      vehicleModel: 'Ford',
      registrationNumber: 'ZS_965U',
      advanceEur: 280.0,
      advancePln: 0.0,
    );
    final bytes = DocxReportService.generatePlanJazdyDocxBytes(summary);
    expect(bytes, isNotEmpty);

    final archive = ZipDecoder().decodeBytes(bytes);
    final docXmlFile = archive.findFile('word/document.xml');
    expect(docXmlFile, isNotNull);

    final docXml = utf8.decode(docXmlFile!.content as List<int>);
    expect(docXml, contains('BB.08'));
    expect(docXml, contains('PLAN JAZDY'));
    expect(docXml, contains('GRZESIEK KOROWAJCZYK'));
    expect(docXml, contains('280 €'));
  });

  testWidgets('App defaults to dark mode', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    BalticBusApp.themeNotifier.value = ThemeMode.dark;

    await tester.pumpWidget(const BalticBusApp());
    await tester.pumpAndSettle();

    expect(BalticBusApp.themeNotifier.value, ThemeMode.dark);
    // Dark mode toggle button is removed from AppBar
    expect(find.byIcon(Icons.dark_mode), findsNothing);
    expect(find.byIcon(Icons.light_mode), findsNothing);
  });

  testWidgets('Finish trip and clear database flow test (Variant A)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp());
    await tester.pumpAndSettle();

    // Switch to Tab 2: Raporty & Czas
    await tester.tap(find.text('Raporty & Czas'));
    await tester.pumpAndSettle();

    // Scroll to find "Zakończ kurs i wyczyść dane" button and ensure fully visible
    await tester.ensureVisible(find.text('Zakończ kurs i wyczyść dane'));
    await tester.pumpAndSettle();

    // 1. Click "Zakończ kurs i wyczyść dane"
    expect(find.text('Zakończ kurs i wyczyść dane'), findsOneWidget);
    await tester.tap(find.text('Zakończ kurs i wyczyść dane'));
    await tester.pumpAndSettle();

    // 2. Confirm dialog
    expect(find.text('Zakończyć kurs?'), findsOneWidget);
    expect(find.text('Wyczyść i zakończ kurs'), findsOneWidget);
    await tester.tap(find.text('Wyczyść i zakończ kurs'));
    await tester.pumpAndSettle();

    // Wait for the completion notice SnackBar to disappear
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // 3. Verify no active trip screen is displayed (production button is visible)
    expect(find.text('Brak aktywnego kursu'), findsOneWidget);
    expect(find.text('Rozpocznij przejazd'), findsOneWidget);

    // 4. Tap "Rozpocznij przejazd" button to open the import sheet and verify its actions
    await tester.tap(find.text('Rozpocznij przejazd'));
    await tester.pumpAndSettle();
    expect(find.text('Import rozkładu jazdy (Excel)'), findsOneWidget);
    expect(find.text('Wybierz plik Excel z urządzenia'), findsOneWidget);
  });

  testWidgets('Bottom navigation tabs switch between Route, Vehicle & Fuel, and Reports & Time',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp());
    await tester.pumpAndSettle();

    // Tab 0: Trasa & Pasażerowie
    expect(find.text('Trasa'), findsOneWidget);
    expect(find.text('Pojazd & Paliwo'), findsOneWidget);
    expect(find.text('Raporty & Czas'), findsOneWidget);
    expect(find.text('Angelika Borchert'), findsOneWidget);

    // Switch to Tab 1: Pojazd & Paliwo
    await tester.tap(find.text('Pojazd & Paliwo'));
    await tester.pumpAndSettle();
    expect(find.text('Paliwo i Tankowania'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(find.text('KONIEC'), findsOneWidget);

    // Switch to Tab 2: Raporty & Czas
    await tester.tap(find.text('Raporty & Czas'));
    await tester.pumpAndSettle();
    expect(find.text('Czas Pracy & Pauzy'), findsOneWidget);
    expect(find.text('Zaliczka i Finanse'), findsOneWidget);
    expect(find.text('Centrum Raportowania'), findsOneWidget);
  });
}
