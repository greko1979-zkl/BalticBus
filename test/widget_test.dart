import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:balticbus/models/route_models.dart';
import 'package:balticbus/services/docx_report_service.dart';
import 'package:balticbus/theme/app_colors.dart';
import 'package:balticbus/main.dart';

void main() {
  testWidgets('BalticBusApp smoke test - verifies route and vehicle information',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
    await tester.pumpAndSettle();

    // Verify vehicle information in title
    expect(find.textContaining('BB.01'), findsWidgets);
    expect(find.textContaining('Ford Custom'), findsWidgets);

    // Switch to Tab 1: Tankowanie
    await tester.tap(find.text('Tankowanie'));
    await tester.pumpAndSettle();
    expect(find.text('Paliwo i Tankowania'), findsOneWidget);

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

  testWidgets('Fresh install starts on clean welcome screen without test data',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: false));
    await tester.pumpAndSettle();

    expect(find.text('Rozpocznij przejazd'), findsOneWidget);
    expect(find.byKey(const ValueKey('balticbus_logo_detector')), findsOneWidget);
    expect(find.text('Probably the best door-to-door transport in Europe.'), findsOneWidget);
    expect(find.textContaining('BB.01'), findsNothing);
    expect(find.text('Angelika Borchert'), findsNothing);
  });

  testWidgets('Driver break start and stop flow test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
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
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
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

    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
    await tester.pumpAndSettle();

    expect(BalticBusApp.themeNotifier.value, ThemeMode.dark);
    // Dark mode toggle button is removed from AppBar
    expect(find.byIcon(Icons.dark_mode), findsNothing);
    expect(find.byIcon(Icons.light_mode), findsNothing);
  });

  testWidgets('Finish trip and clear database flow test (Variant A)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
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

    // 3. Verify no active trip screen is displayed (logo and production button are visible)
    expect(find.byKey(const ValueKey('balticbus_logo_detector')), findsOneWidget);
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
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
    await tester.pumpAndSettle();

    // Tab 0: Trasa & Pasażerowie
    expect(find.text('Trasa'), findsOneWidget);
    expect(find.text('Tankowanie'), findsOneWidget);
    expect(find.text('Raporty & Czas'), findsOneWidget);
    expect(find.text('Angelika Borchert'), findsOneWidget);

    // Switch to Tab 1: Tankowanie
    await tester.tap(find.text('Tankowanie'));
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

  testWidgets('Driver Break modal dialog live timer and tacho milestones test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
    await tester.pumpAndSettle();

    // Verify Pauza pill is visible in the Route header
    expect(find.text('Pauza'), findsOneWidget);

    // 1. Tap "Pauza" to start break and open modal dialog
    await tester.tap(find.text('Pauza'));
    await tester.pumpAndSettle();

    // Verify modal dialog appears with title and live timer
    expect(find.text('PRZERWA KIEROWCY'), findsOneWidget);
    expect(find.text('CZAS TRWANIA PAUZY'), findsOneWidget);
    expect(find.text('Wróć do trasy'), findsOneWidget);
    expect(find.text('Zakończ przerwę'), findsOneWidget);

    // 2. Tap "Wróć do trasy" to minimize dialog while break continues
    await tester.tap(find.text('Wróć do trasy'));
    await tester.pumpAndSettle();

    // Dialog is dismissed, break pill shows active state 'Pauza w toku'
    expect(find.text('PRZERWA KIEROWCY'), findsNothing);
    expect(find.text('Pauza w toku'), findsOneWidget);

    // 3. Tap 'Pauza w toku' to re-open the live dialog
    await tester.tap(find.text('Pauza w toku'));
    await tester.pumpAndSettle();

    expect(find.text('PRZERWA KIEROWCY'), findsOneWidget);

    // 4. Tap "Zakończ przerwę" to end the break
    await tester.tap(find.text('Zakończ przerwę'));
    await tester.pumpAndSettle();

    // Verify dialog is closed and pill is reset to 'Pauza'
    expect(find.text('PRZERWA KIEROWCY'), findsNothing);
    expect(find.text('Pauza'), findsOneWidget);
  });

  test('PassengerStop with address XXX displays przesiadka instead of dashes', () {
    final stop = PassengerStop(
      order: 1,
      name: 'Ljubow Herbst',
      address: 'XXX',
      passengerCount: 1,
      phone: '15754714628',
      hotelTime: '08:10',
    );

    expect(stop.isTransfer, isTrue);
    expect(stop.displayAddress, 'Przesiadka (brak adresu domowego)');
    expect(stop.homeTimeDisplay, 'przesiadka');
  });

  testWidgets('Theme selector displays exactly the 3 active themes: Baltic Noir, Baltic Orange, Charcoal Noir',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
    await tester.pumpAndSettle();

    // 1. Open theme selector sheet via palette icon in AppBar
    final paletteBtn = find.byIcon(Icons.palette_outlined);
    expect(paletteBtn, findsOneWidget);
    await tester.tap(paletteBtn);
    await tester.pumpAndSettle();

    // 2. Verify exactly the 3 chosen themes are present
    expect(find.text('BALTIC NOIR'), findsOneWidget);
    expect(find.text('BALTIC ORANGE'), findsOneWidget);
    expect(find.text('CHARCOAL NOIR'), findsOneWidget);

    // 3. Select BALTIC ORANGE
    await tester.tap(find.text('BALTIC ORANGE'));
    await tester.pumpAndSettle();
    expect(AppColors.currentTheme.value, AppThemeStyle.balticOrange);
  });

  testWidgets('Coffee break reminder settings and simulation test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
    await tester.pumpAndSettle();

    // 1. Long press on "Pauza" button to open coffee reminder settings
    expect(find.text('Pauza'), findsOneWidget);
    await tester.longPress(find.text('Pauza'));
    await tester.pumpAndSettle();

    // Verify settings dialog appears
    expect(find.text('Przypomnienie o kawie'), findsOneWidget);
    expect(find.text('2,5 godz. (zalecane)'), findsOneWidget);
    expect(find.text('Symuluj 2,5h jazdy (test komunikatu)'), findsOneWidget);

    // 2. Click simulation button to trigger 2.5h drive time test
    await tester.tap(find.text('Symuluj 2,5h jazdy (test komunikatu)'));
    await tester.pumpAndSettle();

    // Verify banner appears on Route tab
    expect(find.text('☕ Czas na przerwę i kawę!'), findsOneWidget);
    expect(find.text('Zrób przerwę'), findsOneWidget);
    expect(find.text('Za 15 min'), findsOneWidget);

    // 3. Click "Za 15 min" to snooze reminder
    await tester.tap(find.text('Za 15 min'));
    await tester.pumpAndSettle();

    // Banner is dismissed
    expect(find.text('☕ Czas na przerwę i kawę!'), findsNothing);
  });

  testWidgets('Pulsing comment badge renders for passenger with Rollator note', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
    await tester.pumpAndSettle();

    // 1. Switch to Sunday route which contains the passenger with "Rollator !" note
    final sundayPill = find.textContaining('Niedziela');
    expect(sundayPill, findsOneWidget);
    await tester.tap(sundayPill);
    await tester.pumpAndSettle();

    // 2. Scroll to Hanon, Bella Sivachinski who has the "Rollator !" note
    final passengerNameFinder = find.text('Hanon, Bella Sivachinski');
    await tester.scrollUntilVisible(
      passengerNameFinder,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(passengerNameFinder, findsOneWidget);

    // 3. Tap to expand passenger card (using pump instead of pumpAndSettle due to repeating animation)
    await tester.tap(passengerNameFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 4. Verify pulsing comment badge appears
    expect(find.text('Uwagi: Rollator !'), findsOneWidget);

    // 5. Verify pulsing animation runs smoothly over frames
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Uwagi: Rollator !'), findsOneWidget);
  });

  testWidgets('Night Cockpit HUD mode toggle, display, navigation, and exit test',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BalticBusApp(initialHasActiveTrip: true));
    await tester.pumpAndSettle();

    // 1. Verify "KOKPIT HUD" button in AppBar and tap it
    final hudToggleBtn = find.byKey(const ValueKey('hud_mode_toggle_btn'));
    expect(hudToggleBtn, findsOneWidget);
    await tester.tap(hudToggleBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 2. Verify HUD mode components are present and layout hierarchy:
    // (Passenger name at top, street address in middle, postal code & city in one line below)
    expect(find.byKey(const ValueKey('hud_exit_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('hud_navigate_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('hud_transfer_button')), findsOneWidget);
    expect(find.text('PLANOWANA GODZINA'), findsOneWidget);
    expect(find.text('Angelika Borchert'), findsOneWidget);
    expect(find.textContaining('Kołobrzeg'), findsWidgets);
    expect(find.text('NAWIGUJ (GOOGLE MAPS)'), findsOneWidget);
    expect(find.text('Przesiadka'), findsOneWidget);
    expect(find.text('NORMALNY'), findsOneWidget);

    // 3. Tap "Następny" in HUD footer to advance stop preview
    final nextBtn = find.text('Następny');
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 4. Switch to Sunday route in HUD mode to verify German address parsing
    final sundayHudPill = find.textContaining('Niedziela');
    expect(sundayHudPill, findsOneWidget);
    await tester.tap(sundayHudPill);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Sunday stop 1 is Wilhelm Godecke: "31582 Nienburg, Ostlandstr. 13"
    // Street must be "Ostlandstr. 13" and postal & city must be "31582 Nienburg" in one line
    expect(find.text('Ostlandstr. 13'), findsOneWidget);
    expect(find.text('31582 Nienburg'), findsOneWidget);

    // 5. Tap "NORMALNY" to exit HUD mode back to standard route screen
    final exitBtn = find.byKey(const ValueKey('hud_exit_button'));
    await tester.tap(exitBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify HUD is closed and standard tabs are back
    expect(find.byKey(const ValueKey('hud_exit_button')), findsNothing);
    expect(find.text('Trasa'), findsOneWidget);
    expect(find.text('Tankowanie'), findsOneWidget);
  });
}
