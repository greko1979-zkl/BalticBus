import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/route_models.dart';
import '../theme/app_colors.dart';

class ReportService {
  static String generateSummaryText(BusRoute route) {
    final diff = route.actualDistanceKm;
    final dieselLiters = route.totalDieselLiters;
    final adBlueLiters = route.totalAdBlueLiters;
    final consumption = route.averageConsumptionLPer100Km;
    final pln = route.totalRefueledAmountPLN;
    final eur = route.totalRefueledAmountEUR;

    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🚌 BALTICBUS • KARTA DROGOWA I ROZLICZENIE TRASY');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Trasa:        ${route.code} (${route.direction})');
    buffer.writeln('Termin:       ${route.date}');
    buffer.writeln('Pojazd:       ${route.vehicleModel} (${route.registrationNumber})');
    buffer.writeln('Kierowca:     ${route.driverName} (tel. ${route.driverPhone})');
    buffer.writeln('Data raportu: ${_formatCurrentDateTime()}');
    buffer.writeln('─────────────────────────────────────────────────────');

    if (route.startOdometerKm != null || route.endOdometerKm != null) {
      final start = route.startOdometerKm != null ? '${route.startOdometerKm} km' : 'brak';
      final end = route.endOdometerKm != null ? '${route.endOdometerKm} km' : 'brak';
      buffer.writeln('📍 PRZEBIEG:');
      buffer.writeln(' • Licznik START:     $start');
      buffer.writeln(' • Licznik KONIEC:    $end');
      if (diff != null) {
        buffer.writeln(' • Przejechano razem: $diff km (plan: ${route.plannedDistanceKm} km)');
      }
    } else {
      buffer.writeln('📍 Planowany dystans: ${route.plannedDistanceKm} km');
    }

    buffer.writeln('─────────────────────────────────────────────────────');
    buffer.writeln('👥 PASAŻEROWIE (${route.pickedUpPassengers} / ${route.totalPassengers} obsłużonych):');
    for (final stop in route.stops) {
      String statusInfo;
      switch (stop.status) {
        case PickupStatus.pickedUp:
          final time = stop.pickedUpAt != null ? _formatTime(stop.pickedUpAt!) : '';
          statusInfo = 'Odebrano $time';
          break;
        case PickupStatus.delivered:
          final time = stop.deliveredAt != null ? _formatTime(stop.deliveredAt!) : '';
          statusInfo = 'Dostarczono $time';
          break;
        case PickupStatus.noShow:
          statusInfo = 'NIEBECNY';
          break;
        case PickupStatus.cancelled:
          statusInfo = 'ODWOŁANY';
          break;
        case PickupStatus.pending:
          statusInfo = 'Oczekuje';
          break;
      }

      final resortInfo = stop.resort.isNotEmpty ? ' [🏨 ${stop.resort}]' : '';
      final noteInfo = stop.comment.isNotEmpty ? ' (⚠️ ${stop.comment})' : '';
      buffer.writeln(' [${stop.order}] ${stop.name} (${stop.passengerCount} os.) - $statusInfo$resortInfo$noteInfo');
      buffer.writeln('     Adres: ${stop.address}');
      if (stop.phone.isNotEmpty) {
        buffer.writeln('     Tel: ${stop.phone}');
      }
    }

    if (route.breaks.isNotEmpty) {
      buffer.writeln('─────────────────────────────────────────────────────');
      buffer.writeln('☕ PRZERWY I PAUZY KIEROWCY (${route.breaks.length}):');
      for (int i = 0; i < route.breaks.length; i++) {
        final b = route.breaks[i];
        final startStr = _formatTime(b.startTime);
        final endStr = b.endTime != null ? _formatTime(b.endTime!) : 'w toku';
        final dur = '${b.durationMinutes} min';
        buffer.writeln(' • Przerwa #${i + 1}: $startStr ➔ $endStr ($dur)');
      }
      buffer.writeln(' • Łączny czas przerw: ${route.totalBreakMinutes} min');
    }

    buffer.writeln('─────────────────────────────────────────────────────');
    if (route.refuelings.isNotEmpty) {
      buffer.writeln('⛽ TANKOWANIA (${route.refuelings.length}):');
      for (final ref in route.refuelings) {
        final icon = ref.fuelType == 'AdBlue' ? '💧' : '⛽';
        buffer.writeln(' $icon ${ref.stationName}: ${ref.liters.toStringAsFixed(1)} L ${ref.fuelType} | ${ref.amount.toStringAsFixed(2)} ${ref.currency} (${ref.paymentMethod}) @ ${ref.odometerKm} km');
      }
      buffer.writeln('─────────────────────────────────────────────────────');
      buffer.writeln(' • Diesel (ON):      ${dieselLiters.toStringAsFixed(1)} L');
      if (consumption != null) {
        buffer.writeln(' • Średnie spalanie: ${consumption.toStringAsFixed(2)} l/100km');
      }
      if (adBlueLiters > 0) {
        buffer.writeln(' • AdBlue:           ${adBlueLiters.toStringAsFixed(1)} L');
      }
      if (pln > 0 || eur > 0) {
        final costs = [
          if (pln > 0) '${pln.toStringAsFixed(2)} PLN',
          if (eur > 0) '${eur.toStringAsFixed(2)} EUR',
        ].join(' + ');
        buffer.writeln(' • Koszt paliwa:     $costs');
      }
    } else {
      buffer.writeln('⛽ Brak zarejestrowanych tankowań na trasie.');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buffer.toString();
  }

  /// Zapisuje raport do fizycznego pliku na Biurku Maca podczas testów w symulatorze
  static Future<String?> saveReportToDesktop(BuildContext context, BusRoute route) async {
    final text = generateSummaryText(route);
    final cleanCode = route.code.replaceAll(RegExp(r'[^\w.-]'), '_');
    final cleanDirection = route.direction.replaceAll(RegExp(r'[^\w.-]'), '_');
    final fileName = 'Rozliczenie_${cleanCode}_${route.date}_$cleanDirection.txt';

    return _writeFileToDesktop(context, fileName, text);
  }

  /// Generuje pełny dokument "PLAN JAZDY" zliczony wspólnie z dwóch dni (Sobota + Niedziela)
  static String generatePlanJazdyText(WeekendTripSummary summary) {
    final start = summary.startOdometer;
    final end = summary.endOdometer;
    final diff = summary.totalDistanceKm;
    final consumption = summary.averageConsumptionLPer100Km;

    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('                     PLAN JAZDY');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('BUS:          ${summary.busCode}');
    buffer.writeln('DATA:         ${summary.dateRange}');
    buffer.writeln('KIEROWCA:     ${summary.driverName}');
    buffer.writeln('BUS / NR REJ: ${summary.vehicleModel} / ${summary.registrationNumber}');
    buffer.writeln('─────────────────────────────────────────────────────');
    buffer.writeln('STAN LICZNIKA:');
    buffer.writeln('  • start:    ${start != null ? '$start km' : 'brak'}');
    buffer.writeln('  • koniec:   ${end != null ? '$end km' : 'brak'}');
    buffer.writeln('  • suma:     ${diff != null ? '$diff km' : 'brak'} (plan: ${summary.plannedTotalDistanceKm} km)');
    buffer.writeln('─────────────────────────────────────────────────────');
    final eurStr = summary.advanceEur > 0 ? '${summary.advanceEur.toStringAsFixed(2)} €' : '0,00 €';
    final plnStr = summary.advancePln > 0 ? '${summary.advancePln.toStringAsFixed(2)} zł' : '0,00 zł';
    buffer.writeln('ZALICZKA:');
    buffer.writeln('  $eurStr    $plnStr');
    buffer.writeln('─────────────────────────────────────────────────────');
    buffer.writeln('WYDATKI ZŁ:');
    if (summary.expensesPln.isEmpty) {
      buffer.writeln('  0,00 zł');
    } else {
      for (final exp in summary.expensesPln) {
        buffer.writeln('  • ${exp.amount.toStringAsFixed(2)} zł (${exp.fuelType} - ${exp.stationName})');
      }
      buffer.writeln('  Razem ZŁ: ${summary.totalExpensesPln.toStringAsFixed(2)} zł');
    }
    buffer.writeln('─────────────────────────────────────────────────────');
    buffer.writeln('WYDATKI EURO:');
    if (summary.expensesEur.isEmpty) {
      buffer.writeln('  0,00 EUR');
    } else {
      for (final exp in summary.expensesEur) {
        buffer.writeln('  • ${exp.amount.toStringAsFixed(2)} EUR (TANK - ${exp.stationName})');
      }
      buffer.writeln('  Razem EUR: ${summary.totalExpensesEur.toStringAsFixed(2)} EUR');
    }
    buffer.writeln('─────────────────────────────────────────────────────');
    final guestPln = summary.cashCollectedPln > 0 ? '${summary.cashCollectedPln.toStringAsFixed(2)} zł' : '';
    final guestEur = summary.cashCollectedEur > 0 ? '${summary.cashCollectedEur.toStringAsFixed(2)} €' : '';
    final guestText = [guestEur, guestPln].where((s) => s.isNotEmpty).join(' / ');
    buffer.writeln('ODEBRANE OD GOŚCI:');
    buffer.writeln('  ${guestText.isNotEmpty ? guestText : '0,00 zł / 0,00 €'}');
    buffer.writeln('─────────────────────────────────────────────────────');
    final consStr = consumption != null ? '${consumption.toStringAsFixed(1).replaceAll('.', ',')} l/100km' : 'brak danych';
    buffer.writeln('ŚR. SPALANIE: $consStr');
    if (summary.totalDieselLiters > 0 || summary.totalAdBlueLiters > 0) {
      buffer.writeln('  • Diesel (ON): ${summary.totalDieselLiters.toStringAsFixed(1)} L');
      if (summary.totalAdBlueLiters > 0) {
        buffer.writeln('  • AdBlue:      ${summary.totalAdBlueLiters.toStringAsFixed(1)} L');
      }
    }
    buffer.writeln('─────────────────────────────────────────────────────');
    buffer.writeln('PRZERWY:');
    final satBreaks = summary.saturdayBreaks;
    final sunBreaks = summary.sundayBreaks;
    final maxBreaks = satBreaks.length > sunBreaks.length ? satBreaks.length : sunBreaks.length;
    if (maxBreaks == 0) {
      buffer.writeln('  Brak zarejestrowanych przerw.');
    } else {
      buffer.writeln('       SOBOTA (Wywóz)                 NIEDZIELA (Przywóz)');
      for (int i = 0; i < maxBreaks; i++) {
        String satStr = '';
        if (i < satBreaks.length) {
          final b = satBreaks[i];
          final end = b.endTime != null ? _formatTime(b.endTime!) : 'w toku';
          satStr = '${i + 1}. ${_formatTime(b.startTime)} - $end';
        }
        String sunStr = '';
        if (i < sunBreaks.length) {
          final b = sunBreaks[i];
          final end = b.endTime != null ? _formatTime(b.endTime!) : 'w toku';
          sunStr = '${i + 1}. ${_formatTime(b.startTime)} - $end';
        }
        buffer.writeln('  ${satStr.padRight(28)} $sunStr');
      }
    }
    buffer.writeln('─────────────────────────────────────────────────────');
    buffer.writeln('PASAŻEROWIE:');
    if (summary.saturdayRoute != null) {
      buffer.writeln('  • Wywóz (PL ➔ DE):   ${summary.saturdayRoute!.pickedUpPassengers} / ${summary.saturdayRoute!.totalPassengers} os.');
    }
    if (summary.sundayRoute != null) {
      buffer.writeln('  • Przywóz (DE ➔ PL): ${summary.sundayRoute!.pickedUpPassengers} / ${summary.sundayRoute!.totalPassengers} os.');
    }
    buffer.writeln('  • Łącznie w weekend: ${summary.pickedUpPassengers} / ${summary.totalPassengers} os.');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buffer.toString();
  }

  /// Zapisuje całościowy PLAN JAZDY z obu dni na Biurku Maca
  static Future<String?> savePlanJazdyToDesktop(BuildContext context, WeekendTripSummary summary) async {
    final text = generatePlanJazdyText(summary);
    final cleanCode = summary.busCode.replaceAll(RegExp(r'[^\w.-]'), '_');
    final cleanDates = summary.dateRange.replaceAll(RegExp(r'[^\w.-]'), '_');
    final fileName = 'Plan_Jazdy_${cleanCode}_$cleanDates.txt';

    return _writeFileToDesktop(context, fileName, text);
  }

  static Future<String?> _writeFileToDesktop(BuildContext context, String fileName, String text) async {
    try {
      final macDesktop = Directory('/Users/greko/Desktop');
      File targetFile;

      if (macDesktop.existsSync()) {
        targetFile = File('${macDesktop.path}/$fileName');
      } else {
        final tempDir = Directory.systemTemp;
        targetFile = File('${tempDir.path}/$fileName');
      }

      await targetFile.writeAsString(text);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Row(
              children: [
                const Icon(Icons.desktop_mac, color: AppColors.brandingOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zapisano plik na Twoim Biurku:\n$fileName',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return targetFile.path;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC10801),
            content: Text('Błąd zapisu pliku: $e'),
          ),
        );
      }
      return null;
    }
  }

  static Future<void> sendViaWhatsApp(BuildContext context, String text) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success && context.mounted) {
        copyToClipboard(context, text, 'Nie udało się otworzyć WhatsApp. Raport skopiowano do schowka!');
      }
    } catch (_) {
      if (context.mounted) {
        copyToClipboard(context, text, 'Raport skopiowano do schowka!');
      }
    }
  }

  static void copyToClipboard(BuildContext context, String text, [String? message]) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.brandingOrange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message ?? 'Skopiowano pełny raport rozliczeniowy do schowka!',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCurrentDateTime() {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final y = now.year.toString();
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return '$d.$m.$y, $h:$min';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
