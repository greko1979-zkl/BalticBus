import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/route_models.dart';
import '../theme/app_colors.dart';

class ReportService {
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
    if (summary.advanceEur > 0) {
      buffer.writeln('  Pozostało z zaliczki (reszta): ${summary.remainingAdvanceEur.toStringAsFixed(2)} EUR');
    }
    buffer.writeln('─────────────────────────────────────────────────────');
    final guestPln = summary.cashCollectedPln > 0 ? '${summary.cashCollectedPln.toStringAsFixed(2)} zł' : '';
    final guestEur = summary.cashCollectedEur > 0 ? '${summary.cashCollectedEur.toStringAsFixed(2)} €' : '';
    final guestText = [guestEur, guestPln].where((s) => s.isNotEmpty).join(' / ');
    buffer.writeln('ODEBRANE OD GOŚCI:');
    if (summary.guestPayments.isNotEmpty) {
      for (final p in summary.guestPayments) {
        final passStr = p.passengerName.isNotEmpty ? ' - ${p.passengerName}' : '';
        buffer.writeln('  • ${p.amount.toStringAsFixed(2)} ${p.currency}$passStr');
      }
      buffer.writeln('  Razem: ${guestText.isNotEmpty ? guestText : '0,00 zł / 0,00 €'}');
    } else {
      buffer.writeln('  ${guestText.isNotEmpty ? guestText : '0,00 zł / 0,00 €'}');
    }
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

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
