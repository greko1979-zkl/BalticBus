import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import '../models/route_models.dart';
import '../theme/app_colors.dart';

class DocxReportService {
  /// Generuje plik Word (.docx) zliczony z całego weekendu (Sobota + Niedziela)
  /// i zapisuje go bezpośrednio na Biurku Maca w katalogu /Users/greko/Desktop/
  static Future<String?> savePlanJazdyDocxToDesktop(
    BuildContext context,
    WeekendTripSummary summary,
  ) async {
    try {
      final docxBytes = generatePlanJazdyDocxBytes(summary);

      final cleanCode = summary.busCode.replaceAll(RegExp(r'[^\w.-]'), '_');
      final cleanDates = summary.dateRange.replaceAll(RegExp(r'[^\w.-]'), '_');
      final fileName = 'Plan_Jazdy_${cleanCode}_$cleanDates.docx';

      final macDesktop = Directory('/Users/greko/Desktop');
      File targetFile;

      if (macDesktop.existsSync()) {
        targetFile = File('${macDesktop.path}/$fileName');
      } else {
        final tempDir = Directory.systemTemp;
        targetFile = File('${tempDir.path}/$fileName');
      }

      await targetFile.writeAsBytes(docxBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Row(
              children: [
                const Icon(Icons.description, color: AppColors.brandingOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zapisano plik Word (.docx) na Twoim Biurku:\n$fileName',
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
            content: Text('Błąd zapisu pliku Word: $e'),
          ),
        );
      }
      return null;
    }
  }

  /// Tworzy binarną zawartość archiwum OpenXML (.docx)
  static List<int> generatePlanJazdyDocxBytes(WeekendTripSummary summary) {
    final archive = Archive();

    void addXml(String path, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    // 1. [Content_Types].xml
    addXml('[Content_Types].xml', _contentTypesXml);

    // 2. _rels/.rels
    addXml('_rels/.rels', _rootRelsXml);

    // 3. word/_rels/document.xml.rels
    addXml('word/_rels/document.xml.rels', _documentRelsXml);

    // 4. word/styles.xml
    addXml('word/styles.xml', _stylesXml);

    // 5. word/settings.xml
    addXml('word/settings.xml', _settingsXml);

    // 6. word/webSettings.xml
    addXml('word/webSettings.xml', _webSettingsXml);

    // 7. word/fontTable.xml
    addXml('word/fontTable.xml', _fontTableXml);

    // 8. word/document.xml
    final documentXml = _buildDocumentXml(summary);
    addXml('word/document.xml', documentXml);

    return ZipEncoder().encode(archive)!;
  }

  static String _esc(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _buildDocumentXml(WeekendTripSummary summary) {
    final start = summary.startOdometer;
    final end = summary.endOdometer;
    final diff = summary.totalDistanceKm;
    final consumption = summary.averageConsumptionLPer100Km;
    final satBreaks = summary.saturdayBreaks;
    final sunBreaks = summary.sundayBreaks;

    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    buffer.write('<w:body>');

    // --- 1. NAGŁÓWEK: BB.08 (lewa strona) oraz PLAN JAZDY (wyśrodkowany, bold) ---
    buffer.write('''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="10400" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="none"/>
          <w:left w:val="none"/>
          <w:bottom w:val="none"/>
          <w:right w:val="none"/>
          <w:insideH w:val="none"/>
          <w:insideV w:val="none"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="2500"/>
        <w:gridCol w:w="7900"/>
      </w:tblGrid>
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="2500" w:type="dxa"/></w:tcPr>
          <w:p>
            <w:r><w:rPr><w:b/><w:sz w:val="26"/></w:rPr><w:t>${_esc(summary.busCode)}</w:t></w:r>
          </w:p>
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="7900" w:type="dxa"/></w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="center"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="32"/><w:u w:val="single"/></w:rPr><w:t>PLAN JAZDY</w:t></w:r>
          </w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
    ''');

    // Odstęp
    buffer.write('<w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>');

    // --- 2. TABELA: DATA, KIEROWCA, BUS / NR REJ. ---
    buffer.write('''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="10400" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="none"/>
          <w:left w:val="none"/>
          <w:bottom w:val="none"/>
          <w:right w:val="none"/>
          <w:insideH w:val="none"/>
          <w:insideV w:val="none"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="2200"/>
        <w:gridCol w:w="8200"/>
      </w:tblGrid>

      <!-- Wiersz DATA -->
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="2200" w:type="dxa"/><w:vAlign w:val="center"/></w:tcPr>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:t>DATA:</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="8200" w:type="dxa"/></w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="center"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="22"/></w:rPr><w:t>${_esc(summary.dateRange)}</w:t></w:r>
          </w:p>
        </w:tc>
      </w:tr>

      <!-- Wiersz KIEROWCA (z obramowaną ramką) -->
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="2200" w:type="dxa"/><w:vAlign w:val="center"/></w:tcPr>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:t>KIEROWCA:</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="8200" w:type="dxa"/>
            <w:tcBorders>
              <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
            </w:tcBorders>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="center"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="22"/></w:rPr><w:t>${_esc(summary.driverName.toUpperCase())}</w:t></w:r>
          </w:p>
        </w:tc>
      </w:tr>

      <!-- Wiersz BUS / NR REJ. (z obramowaną ramką) -->
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="2200" w:type="dxa"/><w:vAlign w:val="center"/></w:tcPr>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:t>BUS / NR REJ.:</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="8200" w:type="dxa"/>
            <w:tcBorders>
              <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
            </w:tcBorders>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="center"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="22"/></w:rPr><w:t>${_esc(summary.vehicleModel.toUpperCase())} / ${_esc(summary.registrationNumber.toUpperCase())}</w:t></w:r>
          </w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
    ''');

    // Odstęp
    buffer.write('<w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>');

    // --- 3. TABELA: STAN LICZNIKA (start | koniec | suma) ---
    buffer.write('''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="10400" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:insideH w:val="single" w:sz="6" w:space="0" w:color="000000"/>
          <w:insideV w:val="single" w:sz="6" w:space="0" w:color="000000"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="2200"/>
        <w:gridCol w:w="2700"/>
        <w:gridCol w:w="2800"/>
        <w:gridCol w:w="2700"/>
      </w:tblGrid>

      <!-- Nagłówki licznika -->
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="2200" w:type="dxa"/><w:vAlign w:val="center"/></w:tcPr>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>STAN LICZNIKA:</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="2700" w:type="dxa"/></w:tcPr>
          <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>start</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="2800" w:type="dxa"/></w:tcPr>
          <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>koniec</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="2700" w:type="dxa"/></w:tcPr>
          <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>suma</w:t></w:r></w:p>
        </w:tc>
      </w:tr>

      <!-- Wartości licznika -->
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="2200" w:type="dxa"/><w:vAlign w:val="center"/></w:tcPr>
          <w:p><w:r><w:t></w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="2700" w:type="dxa"/></w:tcPr>
          <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>${start != null ? start.toString() : ''}</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="2800" w:type="dxa"/></w:tcPr>
          <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>${end != null ? end.toString() : ''}</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="2700" w:type="dxa"/></w:tcPr>
          <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>${diff != null ? diff.toString() : ''}</w:t></w:r></w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
    ''');

    // Odstęp
    buffer.write('<w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>');

    // --- 4. SEKCJA ZALICZKA ---
    final advEurStr = summary.advanceEur > 0 ? '${summary.advanceEur.toStringAsFixed(0)} €' : '0,00 €';
    final advPlnStr = summary.advancePln > 0 ? '${summary.advancePln.toStringAsFixed(2)} zł' : '0,00 zł';
    buffer.write('''
    <w:p>
      <w:pPr><w:spacing w:after="40"/></w:pPr>
      <w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:t>ZALICZKA:        </w:t></w:r>
      <w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>${_esc(advEurStr)}</w:t></w:r>
    </w:p>
    <w:p>
      <w:pPr><w:spacing w:after="80"/></w:pPr>
      <w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:t>                         </w:t></w:r>
      <w:r><w:rPr><w:b/><w:sz w:val="22"/></w:rPr><w:t>${_esc(advPlnStr)}</w:t></w:r>
    </w:p>
    ''');

    // --- 5. RAMKA: WYDATKI ZŁ ---
    buffer.write('''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="10400" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="10400"/>
      </w:tblGrid>
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="10400" w:type="dxa"/></w:tcPr>
          <w:p>
            <w:pPr><w:spacing w:after="40"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>WYDATKI ZŁ</w:t></w:r>
          </w:p>
    ''');
    if (summary.expensesPln.isEmpty) {
      buffer.write('<w:p><w:pPr><w:spacing w:after="60"/></w:pPr><w:r><w:t></w:t></w:r></w:p>');
    } else {
      for (final exp in summary.expensesPln) {
        buffer.write('''
          <w:p>
            <w:r><w:rPr><w:b/><w:sz w:val="22"/></w:rPr><w:t>${exp.amount.toStringAsFixed(2)} zł (${_esc(exp.fuelType)} - ${_esc(exp.stationName)})</w:t></w:r>
          </w:p>
        ''');
      }
    }
    buffer.write('</w:tc></w:tr></w:tbl>');

    // Odstęp
    buffer.write('<w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>');

    // --- 6. RAMKA: WYDATKI EURO ---
    buffer.write('''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="10400" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="10400"/>
      </w:tblGrid>
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="10400" w:type="dxa"/></w:tcPr>
          <w:p>
            <w:pPr><w:spacing w:after="40"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>WYDATKI EURO</w:t></w:r>
          </w:p>
    ''');
    if (summary.expensesEur.isEmpty) {
      buffer.write('<w:p><w:pPr><w:spacing w:after="80"/></w:pPr><w:r><w:t></w:t></w:r></w:p>');
    } else {
      for (final exp in summary.expensesEur) {
        buffer.write('''
          <w:p>
            <w:r><w:rPr><w:b/><w:sz w:val="22"/></w:rPr><w:t>${exp.amount.toStringAsFixed(2)} EUR (TANK - ${_esc(exp.stationName)})</w:t></w:r>
          </w:p>
        ''');
      }
    }
    buffer.write('</w:tc></w:tr></w:tbl>');

    // Odstęp
    buffer.write('<w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>');

    // --- 7. RAMKA: ODEBRANE OD GOŚCI ---
    final guestPln = summary.cashCollectedPln > 0 ? '${summary.cashCollectedPln.toStringAsFixed(2)} zł' : '';
    final guestEur = summary.cashCollectedEur > 0 ? '${summary.cashCollectedEur.toStringAsFixed(2)} €' : '';
    final guestText = [guestEur, guestPln].where((s) => s.isNotEmpty).join(' / ');
    buffer.write('''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="10400" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
          <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="10400"/>
      </w:tblGrid>
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="10400" w:type="dxa"/></w:tcPr>
          <w:p>
            <w:pPr><w:spacing w:after="40"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>ODEBRANE OD GOŚCI</w:t></w:r>
          </w:p>
          <w:p>
            <w:pPr><w:spacing w:after="60"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="22"/></w:rPr><w:t>${_esc(guestText)}</w:t></w:r>
          </w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
    ''');

    // Odstęp
    buffer.write('<w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>');

    // --- 8. DOLNY WIERSZ: ŚR. SPALANIE, PODPIS oraz TABELA PRZERWY (SOBOTA / NIEDZIELA) ---
    final consStr = consumption != null
        ? consumption.toStringAsFixed(1).replaceAll('.', ',')
        : '';

    buffer.write('''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="10400" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="none"/>
          <w:left w:val="none"/>
          <w:bottom w:val="none"/>
          <w:right w:val="none"/>
          <w:insideH w:val="none"/>
          <w:insideV w:val="none"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="2980"/>
        <w:gridCol w:w="7420"/>
      </w:tblGrid>
      <w:tr>
        <!-- Kolumna lewa: ŚR. SPALANIE i PODPIS -->
        <w:tc>
          <w:tcPr><w:tcW w:w="3000" w:type="dxa"/><w:vAlign w:val="top"/></w:tcPr>

          <!-- Box: ŚR. SPALANIE -->
          <w:tbl>
            <w:tblPr>
              <w:tblW w:w="2800" w:type="dxa"/>
              <w:tblBorders>
                <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
                <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
                <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
                <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              </w:tblBorders>
            </w:tblPr>
            <w:tblGrid>
              <w:gridCol w:w="2800"/>
            </w:tblGrid>
            <w:tr>
              <w:tc>
                <w:tcPr><w:tcW w:w="2800" w:type="dxa"/></w:tcPr>
                <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>ŚR. SPALANIE</w:t></w:r></w:p>
                <w:p>
                  <w:pPr><w:jc w:val="center"/><w:spacing w:after="40"/></w:pPr>
                  <w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>${_esc(consStr)}</w:t></w:r>
                </w:p>
              </w:tc>
            </w:tr>
          </w:tbl>

          <w:p><w:pPr><w:spacing w:after="60"/></w:pPr></w:p>

          <!-- Box: PODPIS -->
          <w:tbl>
            <w:tblPr>
              <w:tblW w:w="2800" w:type="dxa"/>
              <w:tblBorders>
                <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
                <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
                <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
                <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              </w:tblBorders>
            </w:tblPr>
            <w:tblGrid>
              <w:gridCol w:w="2800"/>
            </w:tblGrid>
            <w:tr>
              <w:tc>
                <w:tcPr><w:tcW w:w="2800" w:type="dxa"/></w:tcPr>
                <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>PODPIS</w:t></w:r></w:p>
                <w:p><w:pPr><w:spacing w:after="160"/></w:pPr><w:r><w:t></w:t></w:r></w:p>
              </w:tc>
            </w:tr>
          </w:tbl>

          <!-- Każda komórka tc w OpenXML musi kończyć się paragrafem w:p -->
          <w:p><w:pPr><w:spacing w:after="0"/></w:pPr></w:p>
        </w:tc>

        <!-- Kolumna prawa: PRZERWY (SOBOTA / NIEDZIELA) bez słów 'Od' i 'Do' -->
        <w:tc>
          <w:tcPr><w:tcW w:w="7400" w:type="dxa"/><w:vAlign w:val="top"/></w:tcPr>
          <w:tbl>
            <w:tblPr>
              <w:tblW w:w="7400" w:type="dxa"/>
              <w:tblBorders>
                <w:top w:val="none"/>
                <w:left w:val="none"/>
                <w:bottom w:val="none"/>
                <w:right w:val="none"/>
                <w:insideH w:val="none"/>
                <w:insideV w:val="none"/>
              </w:tblBorders>
            </w:tblPr>
            <w:tblGrid>
              <w:gridCol w:w="1200"/>
              <w:gridCol w:w="3100"/>
              <w:gridCol w:w="3100"/>
            </w:tblGrid>

            <!-- Nagłówek PRZERWY -->
            <w:tr>
              <w:tc>
                <w:tcPr><w:tcW w:w="1200" w:type="dxa"/></w:tcPr>
                <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>PRZERWY</w:t></w:r></w:p>
              </w:tc>
              <w:tc>
                <w:tcPr><w:tcW w:w="3100" w:type="dxa"/></w:tcPr>
                <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>SOBOTA</w:t></w:r></w:p>
              </w:tc>
              <w:tc>
                <w:tcPr><w:tcW w:w="3100" w:type="dxa"/></w:tcPr>
                <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>NIEDZIELA</w:t></w:r></w:p>
              </w:tc>
            </w:tr>
    ''');

    // Wiersze 1 do 5 (BEZ słów "Od" i "Do")
    for (int i = 0; i < 5; i++) {
      String satText = '';
      if (i < satBreaks.length) {
        final b = satBreaks[i];
        final endStr = b.endTime != null ? _formatTime(b.endTime!) : 'w toku';
        satText = '${_formatTime(b.startTime)} - $endStr';
      }

      String sunText = '';
      if (i < sunBreaks.length) {
        final b = sunBreaks[i];
        final endStr = b.endTime != null ? _formatTime(b.endTime!) : 'w toku';
        sunText = '${_formatTime(b.startTime)} - $endStr';
      }

      buffer.write('''
        <w:tr>
          <w:tc>
            <w:tcPr><w:tcW w:w="1200" w:type="dxa"/></w:tcPr>
            <w:p><w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:t>${i + 1}.</w:t></w:r></w:p>
          </w:tc>
          <w:tc>
            <w:tcPr>
              <w:tcW w:w="3100" w:type="dxa"/>
              <w:tcBorders>
                <w:bottom w:val="single" w:sz="6" w:space="0" w:color="000000"/>
              </w:tcBorders>
            </w:tcPr>
            <w:p>
              <w:pPr><w:jc w:val="center"/></w:pPr>
              <w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:t>${_esc(satText)}</w:t></w:r>
            </w:p>
          </w:tc>
          <w:tc>
            <w:tcPr>
              <w:tcW w:w="3100" w:type="dxa"/>
              <w:tcBorders>
                <w:bottom w:val="single" w:sz="6" w:space="0" w:color="000000"/>
              </w:tcBorders>
            </w:tcPr>
            <w:p>
              <w:pPr><w:jc w:val="center"/></w:pPr>
              <w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr><w:t>${_esc(sunText)}</w:t></w:r>
            </w:p>
          </w:tc>
        </w:tr>
      ''');
    }

    buffer.write('''
          </w:tbl>
          <!-- Każda komórka tc w OpenXML musi kończyć się paragrafem w:p -->
          <w:p><w:pPr><w:spacing w:after="0"/></w:pPr></w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
    ''');

    // Przed w:sectPr musi znajdować się paragraf w:p
    buffer.write('<w:p><w:pPr><w:spacing w:after="0"/></w:pPr></w:p>');

    // Rozmiar strony A4 i marginesy (pół cala = 720 dxa)
    buffer.write('''
      <w:sectPr>
        <w:pgSz w:w="11906" w:h="16838"/>
        <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/>
      </w:sectPr>
    ''');

    buffer.write('</w:body></w:document>');
    return buffer.toString();
  }

  static const String _contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
  <Override PartName="/word/webSettings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml"/>
  <Override PartName="/word/fontTable.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml"/>
</Types>''';

  static const String _rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static const String _documentRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/webSettings" Target="webSettings.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable" Target="fontTable.xml"/>
</Relationships>''';

  static const String _stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>
        <w:sz w:val="20"/>
        <w:color w:val="000000"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:line="240" w:lineRule="auto" w:before="0" w:after="0"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
</w:styles>''';

  static const String _settingsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:defaultTabStop w:val="708"/>
  <w:hyphenationZone w:val="425"/>
  <w:characterSpacingControl w:val="doNotCompress"/>
  <w:compat>
    <w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/>
  </w:compat>
</w:settings>''';

  static const String _webSettingsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:webSettings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:optimizeForBrowser/>
</w:webSettings>''';

  static const String _fontTableXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:fonts xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:font w:name="Arial">
    <w:panose1 w:val="020B0604020202020204"/>
    <w:family w:val="swiss"/>
    <w:pitch w:val="variable"/>
  </w:font>
</w:fonts>''';
}
