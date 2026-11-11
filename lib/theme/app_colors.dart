import 'package:flutter/material.dart';

enum AppThemeStyle {
  balticNoir,
  balticOrange,
  charcoalNoir,
  warmGrey,
  balticOcean,
  walnutNoir,
  emeraldDepth,
}

class AppThemeData {
  final AppThemeStyle style;
  final String title;
  final String subtitle;
  final Color boxStart;
  final Color boxEnd;
  final Color border;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color textPrimary;
  final Color textSecondary;
  final LinearGradient screenGradient;
  final LinearGradient cardGradient;

  const AppThemeData({
    required this.style,
    required this.title,
    required this.subtitle,
    required this.boxStart,
    required this.boxEnd,
    required this.border,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.screenGradient,
    required this.cardGradient,
  });
}

class AppColors {
  // Aktywny motyw kolorystyczny obserwowany w aplikacji (domyślnie Baltic Noir)
  static final ValueNotifier<AppThemeStyle> currentTheme =
      ValueNotifier<AppThemeStyle>(AppThemeStyle.balticNoir);

  static const Map<AppThemeStyle, AppThemeData> themes = {
    // 0. WERSJA GŁÓWNA: BALTIC NOIR (#1E1E1E ⇄ #2C2A28 • #FFE7D0) - stonowana kolorystyka z "Wybierz swój pojazd"
    AppThemeStyle.balticNoir: AppThemeData(
      style: AppThemeStyle.balticNoir,
      title: 'BALTIC NOIR',
      subtitle: '#1E1E1E • #FFE7D0',
      boxStart: Color(0xFF1E1E1E),
      boxEnd: Color(0xFF2C2A28),
      border: Color(0xFF554D44),
      primaryAccent: Color(0xFF36322E),
      secondaryAccent: Color(0xFFFFE7D0),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFFFE7D0),
      screenGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF141414),
          Color(0xFF1E1E1E),
          Color(0xFF232323),
          Color(0xFF2A2826),
          Color(0xFF322E2B),
        ],
        stops: [0.0, 0.25, 0.50, 0.75, 1.0],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF1E1E1E),
          Color(0xFF2C2A28),
        ],
      ),
    ),

    // 1. WERSJA: BALTIC ORANGE (#1B1B1B ⇄ #323232 • #FFE7D0 • #FC6E20)
    AppThemeStyle.balticOrange: AppThemeData(
      style: AppThemeStyle.balticOrange,
      title: 'BALTIC ORANGE',
      subtitle: '#1B1B1B • #FC6E20',
      boxStart: Color(0xFF1B1B1B),
      boxEnd: Color(0xFF323232),
      border: Color(0xFFFC6E20),
      primaryAccent: Color(0xFFFC6E20),
      secondaryAccent: Color(0xFFFFE7D0),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFFFE7D0),
      screenGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F0F0F),
          Color(0xFF1B1B1B),
          Color(0xFF242424),
          Color(0xFF2C2C2C),
          Color(0xFF323232),
        ],
        stops: [0.0, 0.25, 0.50, 0.75, 1.0],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF1B1B1B),
          Color(0xFF323232),
        ],
      ),
    ),

    // 1. WERSJA: CHARCOAL NOIR (#040204 ⇄ #3A3A35) - luksusowy grafit i prawie-czerń
    AppThemeStyle.charcoalNoir: AppThemeData(
      style: AppThemeStyle.charcoalNoir,
      title: 'CHARCOAL NOIR',
      subtitle: '#040204 • #3A3A35',
      boxStart: Color(0xFF040204),
      boxEnd: Color(0xFF3A3A35),
      border: Color(0xFF8C8C7C),
      primaryAccent: Color(0xFF3A3A35),
      secondaryAccent: Color(0xFF8C8C7C),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFD4D4CE),
      screenGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF040204), // ALMOST BLACK (04)
          Color(0xFF0D0D0C),
          Color(0xFF1A1A18), // DARK (03)
          Color(0xFF282824),
          Color(0xFF3A3A35), // CHARCOAL (02)
        ],
        stops: [0.0, 0.22, 0.48, 0.75, 1.0],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF040204),
          Color(0xFF3A3A35),
        ],
      ),
    ),

    // 2. WERSJA: WARM GREY (#1A1A18 ⇄ #8C8C7C) - ciepła szarość i ciemny grafit
    AppThemeStyle.warmGrey: AppThemeData(
      style: AppThemeStyle.warmGrey,
      title: 'WARM GREY',
      subtitle: '#1A1A18 • #8C8C7C',
      boxStart: Color(0xFF1A1A18),
      boxEnd: Color(0xFF5A5A50),
      border: Color(0xFF8C8C7C),
      primaryAccent: Color(0xFF3A3A35),
      secondaryAccent: Color(0xFF8C8C7C),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFEDEDE6),
      screenGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF040204),
          Color(0xFF1A1A18),
          Color(0xFF2E2E2A),
          Color(0xFF484841),
          Color(0xFF6B6B60),
        ],
        stops: [0.0, 0.22, 0.48, 0.75, 1.0],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF1A1A18),
          Color(0xFF4A4A42),
        ],
      ),
    ),

    // 3. WERSJA: BALTIC OCEAN (#021D24 ⇄ #216A85) - oficjalna tożsamość BalticBus
    AppThemeStyle.balticOcean: AppThemeData(
      style: AppThemeStyle.balticOcean,
      title: 'BALTIC OCEAN',
      subtitle: '#021D24 • #216A85',
      boxStart: Color(0xFF021D24),
      boxEnd: Color(0xFF216A85),
      border: Color(0xFF65A7C2),
      primaryAccent: Color(0xFF093F52),
      secondaryAccent: Color(0xFF216A85),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFC7E5F2),
      screenGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF021D24),
          Color(0xFF042933),
          Color(0xFF063442),
          Color(0xFF093F52),
          Color(0xFF216A85),
        ],
        stops: [0.0, 0.22, 0.48, 0.75, 1.0],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF021D24),
          Color(0xFF216A85),
        ],
      ),
    ),

    // 4. WERSJA: WALNUT NOIR (#2E1F1B ⇄ #5E4B43) - ciepły, ekskluzywny orzech
    AppThemeStyle.walnutNoir: AppThemeData(
      style: AppThemeStyle.walnutNoir,
      title: 'WALNUT NOIR',
      subtitle: '#2E1F1B • #5E4B43',
      boxStart: Color(0xFF2E1F1B),
      boxEnd: Color(0xFF5E4B43),
      border: Color(0xFFBFAF9E),
      primaryAccent: Color(0xFF8A6655),
      secondaryAccent: Color(0xFFB88B74),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFD4C2B8),
      screenGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF140D0B),
          Color(0xFF1E1411),
          Color(0xFF2E1F1B),
          Color(0xFF43322B),
          Color(0xFF5E4B43),
        ],
        stops: [0.0, 0.22, 0.48, 0.75, 1.0],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF2E1F1B),
          Color(0xFF5E4B43),
        ],
      ),
    ),

    // 5. WERSJA: EMERALD DEPTH (#0F2027 ⇄ #28623A) - stonowana, elegancka głęboka zieleń ze srebrnym wykończeniem
    AppThemeStyle.emeraldDepth: AppThemeData(
      style: AppThemeStyle.emeraldDepth,
      title: 'EMERALD DEPTH',
      subtitle: '#0F2027 • #28623A',
      boxStart: Color(0xFF0F2027),
      boxEnd: Color(0xFF28623A),
      border: Color(0xFF86A390),
      primaryAccent: Color(0xFF1B3D2A),
      secondaryAccent: Color(0xFF38654A),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFCAD8D0),
      screenGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF071216),
          Color(0xFF0B191D),
          Color(0xFF0F2223),
          Color(0xFF152F27),
          Color(0xFF1E3F30),
        ],
        stops: [0.0, 0.22, 0.48, 0.75, 1.0],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF0F2027),
          Color(0xFF28623A),
        ],
      ),
    ),
  };

  static AppThemeData get activeTheme =>
      themes[currentTheme.value] ?? themes[AppThemeStyle.balticNoir]!;

  // Nowa stonowana paleta z "Wybierz swój pojazd" (Baltic Noir)
  static const Color noirBackground = Color(0xFF1E1E1E);
  static const Color noirCard = Color(0xFF252525);
  static const Color noirCardWarm = Color(0xFF2C2A28);
  static const Color noirButton = Color(0xFF36322E);
  static const Color noirBorder = Color(0xFF554D44);
  static const Color noirCream = Color(0xFFFFE7D0);

  // Paleta Baltic Orange (#1B1B1B, #323232, #FFE7D0, #FC6E20)
  static const Color darkCharcoal = Color(0xFF1B1B1B);
  static const Color cardCharcoal = Color(0xFF323232);
  static const Color warmCream = Color(0xFFFFE7D0);
  static const Color vibrantOrange = Color(0xFFFC6E20);

  // Kolory ze wzornika Warm Grey & Charcoal
  static const Color warmGrey = Color(0xFF8C8C7C);
  static const Color charcoal = Color(0xFF3A3A35);
  static const Color darkGraphite = Color(0xFF1A1A18);
  static const Color almostBlack = Color(0xFF040204);

  // Stałe stałopozycyjne (dla pełnej zgodności z const w projekcie)
  static const Color primary = Color(0xFF216A85);
  static const Color brandingOrange = Color(0xFFFC6E20);
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF252525);
  static const Color darkCard = Color(0xFF2C2A28);
  static const Color darkBorder = Color(0xFF554D44);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFFFE7D0);
  static const Color darkGray = Color(0xFF093F52);
  static const Color gray = Color(0xFF8BC5DE);
  static const Color lightGray = Color(0xFFC7E5F2);
  static const Color white = Color(0xFFF4F8FA);
  static const Color iceBlue = Color(0xFFC7E5F2);

  static const Color shade1 = Color(0xFF021D24);
  static const Color shade2 = Color(0xFF042933);
  static const Color shade3 = Color(0xFF063442);
  static const Color shade4 = Color(0xFF093F52);
  static const Color shade5 = Color(0xFF216A85);
  static const Color shade6 = Color(0xFF65A7C2);
  static const Color shade7 = Color(0xFFC7E5F2);

  static const Color balticAzure = Color(0xFF216A85);
  static const Color balticRoyal = Color(0xFF093F52);
  static const Color balticTwilight = Color(0xFF042933);
  static const Color balticSeafoam = Color(0xFFC7E5F2);
  static const Color balticDeepNavy = Color(0xFF021D24);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF021D24),
      Color(0xFF042933),
      Color(0xFF063442),
      Color(0xFF093F52),
      Color(0xFF216A85),
    ],
    stops: [0.0, 0.22, 0.48, 0.75, 1.0],
  );

  static const LinearGradient brandingGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF021D24),
      Color(0xFF216A85),
    ],
  );
}
