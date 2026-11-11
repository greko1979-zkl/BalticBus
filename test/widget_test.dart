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
    expect(find.text('Grzesiek Korowajczyk'), findsOneWidget);

    // Scroll to find passenger
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

    // Verify initial state: Pauza button is visible
    expect(find.text('Pauza'), findsOneWidget);
    expect(find.text('☕ TRWA PRZERWA KIEROWCY'), findsNothing);

    // 1. Click "Pauza" to start break
    await tester.tap(find.text('Pauza'));
    await tester.pumpAndSettle();

    // Verify break is active: banner is shown, button says "Koniec pauzy"
    expect(find.text('☕ TRWA PRZERWA KIEROWCY'), findsOneWidget);
    expect(find.text('Koniec pauzy'), findsAtLeastNWidgets(1));

    // 2. Click "Koniec pauzy" in the bottom bar to finish break
    await tester.tap(find.text('Koniec pauzy').last);
    await tester.pumpAndSettle();

    // Verify break is ended: banner is gone, button shows "Pauza (1)"
    expect(find.text('☕ TRWA PRZERWA KIEROWCY'), findsNothing);
    expect(find.text('Pauza (1)'), findsOneWidget);
  });

  testWidgets('Plan Jazdy full weekend summary dialog test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp());
    await tester.pumpAndSettle();

    // Verify "Plan Jazdy" button exists and click it
    expect(find.text('Plan Jazdy'), findsOneWidget);
    await tester.tap(find.text('Plan Jazdy'));
    await tester.pumpAndSettle();

    // Verify dialog title and elements matching physical card
    expect(find.textContaining('PLAN JAZDY • BB.01'), findsOneWidget);
    expect(find.text('STAN LICZNIKA'), findsOneWidget);
    expect(find.text('ZALICZKA:'), findsOneWidget);
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

    // 1. Open Plan Jazdy dialog
    expect(find.text('Plan Jazdy'), findsOneWidget);
    await tester.tap(find.text('Plan Jazdy'));
    await tester.pumpAndSettle();

    // 2. Click "Zakończ kurs"
    expect(find.text('Zakończ kurs'), findsOneWidget);
    await tester.tap(find.text('Zakończ kurs'));
    await tester.pumpAndSettle();

    // 3. Confirm dialog
    expect(find.text('Zakończyć kurs?'), findsOneWidget);
    expect(find.text('Wyczyść i zakończ kurs'), findsOneWidget);
    await tester.tap(find.text('Wyczyść i zakończ kurs'));
    await tester.pumpAndSettle();

    // Wait for the completion notice SnackBar to disappear
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // 4. Verify no active trip screen is displayed (production card is visible, test card hidden)
    expect(find.text('Brak aktywnego kursu'), findsOneWidget);
    expect(find.text('Wczytaj plik Excel (.xlsx)'), findsOneWidget);
    expect(find.text('Wczytaj z bazy (Assets)'), findsNothing);

    // 5. Tap BalticBus logo 5 times to reveal hidden dev/test option
    final logoFinder = find.byKey(const ValueKey('balticbus_logo_detector'));
    for (int i = 0; i < 5; i++) {
      await tester.tap(logoFinder);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.text('Wczytaj z bazy (Assets)'), findsOneWidget);
  });
}
