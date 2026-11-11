import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/sample_routes.dart';
import 'models/route_models.dart';
import 'services/docx_report_service.dart';
import 'services/excel_parser_service.dart';
import 'services/launcher_service.dart';
import 'services/report_service.dart';
import 'services/storage_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final isDark = await StorageService.loadThemeMode();
  BalticBusApp.themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  final savedPalette = await StorageService.loadPaletteTheme();
  if (savedPalette == 'warmGrey') {
    AppColors.currentTheme.value = AppThemeStyle.warmGrey;
  } else if (savedPalette == 'balticOcean') {
    AppColors.currentTheme.value = AppThemeStyle.balticOcean;
  } else if (savedPalette == 'walnutNoir') {
    AppColors.currentTheme.value = AppThemeStyle.walnutNoir;
  } else if (savedPalette == 'emeraldDepth') {
    AppColors.currentTheme.value = AppThemeStyle.emeraldDepth;
  } else {
    AppColors.currentTheme.value = AppThemeStyle.charcoalNoir;
  }

  final initialHasActiveTrip = await StorageService.hasActiveTrip();
  runApp(BalticBusApp(initialHasActiveTrip: initialHasActiveTrip));
}

class BalticBusApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  final bool? initialHasActiveTrip;

  const BalticBusApp({super.key, this.initialHasActiveTrip});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<AppThemeStyle>(
          valueListenable: AppColors.currentTheme,
          builder: (context, paletteStyle, _) {
            final active = AppColors.activeTheme;
            return MaterialApp(
              title: 'BalticBus',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: Colors.transparent,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: active.primaryAccent,
                  brightness: Brightness.light,
                  primary: active.primaryAccent,
                  secondary: active.secondaryAccent,
                  surface: Colors.white,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: Colors.transparent,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: active.primaryAccent,
                  brightness: Brightness.dark,
                  primary: active.primaryAccent,
                  secondary: active.secondaryAccent,
                  surface: active.boxStart,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                segmentedButtonTheme: SegmentedButtonThemeData(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return active.primaryAccent;
                      }
                      return active.boxStart.withValues(alpha: 0.90);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return active.textSecondary;
                    }),
                    side: WidgetStateProperty.all(
                      BorderSide(color: active.border.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),
              home: SplashScreen(initialHasActiveTrip: initialHasActiveTrip),
            );
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  final bool? initialHasActiveTrip;
  final Widget? nextScreen;
  const SplashScreen({super.key, this.initialHasActiveTrip, this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isNavigated = true;
          });
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _isNavigated
          ? (widget.nextScreen ??
              DriverRouteScreen(initialHasActiveTrip: widget.initialHasActiveTrip))
          : Scaffold(
              key: const ValueKey('splash_scaffold'),
              backgroundColor: Colors.black,
              body: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 320,
                      height: 120,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Image.asset(
                        'assets/images/balticbus_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class DriverRouteScreen extends StatefulWidget {
  final bool? initialHasActiveTrip;
  const DriverRouteScreen({super.key, this.initialHasActiveTrip});

  @override
  State<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends State<DriverRouteScreen> {
  late List<BusRoute> _allRoutes;
  String _selectedBusCode = 'BB.01';
  String _selectedDate = '2026-08-01'; // Sobota wywóz lub Niedziela przywóz
  bool _isLoading = false;
  double _advanceEur = 0.0;
  double _advancePln = 0.0;
  double _cashCollectedPln = 0.0;
  double _cashCollectedEur = 0.0;
  bool _showDevOptions = false;
  int _logoTapCounter = 0;
  OverlayEntry? _currentNoticeOverlay;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark
      ? AppColors.activeTheme.boxStart
      : Colors.white.withValues(alpha: 0.95);
  Color get _borderColor => _isDark
      ? AppColors.activeTheme.border.withValues(alpha: 0.45)
      : AppColors.shade7.withValues(alpha: 0.65);
  Color get _textPrimary => _isDark ? Colors.white : AppColors.darkBackground;
  Color get _textSecondary =>
      _isDark ? AppColors.activeTheme.textSecondary : AppColors.darkGray;
  Color get _subtleBg => _isDark
      ? AppColors.activeTheme.boxStart.withValues(alpha: 0.85)
      : Colors.white.withValues(alpha: 0.75);

  @override
  void initState() {
    super.initState();
    final hasActive = widget.initialHasActiveTrip ?? true;
    _allRoutes = hasActive ? sampleBusRoutes : [];
    _checkInitialTripState();
  }

  Future<void> _checkInitialTripState() async {
    final hasActive = await StorageService.hasActiveTrip();
    if (!hasActive) {
      if (mounted && _allRoutes.isNotEmpty) {
        setState(() {
          _allRoutes = [];
        });
      }
    } else if (_allRoutes.isEmpty) {
      if (mounted) {
        setState(() {
          _allRoutes = sampleBusRoutes;
        });
      }
      await _restoreStateForRoute(_currentRoute);
    } else {
      await _restoreStateForRoute(_currentRoute);
    }
  }

  BusRoute get _currentRoute {
    if (_allRoutes.isEmpty) {
      return sampleBusRoutes.first;
    }
    final matched = _allRoutes.where(
      (r) => r.code == _selectedBusCode && r.date == _selectedDate,
    );
    if (matched.isNotEmpty) {
      return matched.first;
    }
    final busMatch = _allRoutes.where((r) => r.code == _selectedBusCode);
    if (busMatch.isNotEmpty) {
      return busMatch.first;
    }
    return _allRoutes.first;
  }

  List<String> get _availableBusCodes =>
      _allRoutes.map((r) => r.code).toSet().toList();

  List<String> get _availableDates =>
      _allRoutes.map((r) => r.date).toSet().toList()..sort();

  BusRoute? get _saturdayRoute {
    if (_allRoutes.isEmpty) return null;
    final busRoutes = _allRoutes.where((r) => r.code == _selectedBusCode).toList();
    for (final r in busRoutes) {
      if (r.direction == 'PL-DE' || r.date.endsWith('-01') || r.title.toLowerCase().contains('sobota')) {
        return r;
      }
    }
    return busRoutes.isNotEmpty ? busRoutes.first : null;
  }

  BusRoute? get _sundayRoute {
    if (_allRoutes.isEmpty) return null;
    final busRoutes = _allRoutes.where((r) => r.code == _selectedBusCode).toList();
    for (final r in busRoutes) {
      if (r.direction == 'DE-PL' || r.date.endsWith('-02') || r.title.toLowerCase().contains('niedziela')) {
        return r;
      }
    }
    return busRoutes.length > 1 ? busRoutes[1] : (busRoutes.isNotEmpty ? busRoutes.first : null);
  }

  int? get _tripStartOdometer =>
      _saturdayRoute?.startOdometerKm ?? _sundayRoute?.startOdometerKm;

  int? get _tripEndOdometer =>
      _sundayRoute?.endOdometerKm ?? _saturdayRoute?.endOdometerKm;

  int? get _tripDistanceKm {
    final start = _tripStartOdometer;
    final end = _tripEndOdometer;
    if (start != null && end != null && end >= start) {
      return end - start;
    }
    return null;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _restoreStateForRoute(BusRoute route) async {
    await StorageService.restoreRouteState(route);
    final otherRoutes = _allRoutes.where((r) => r.code == route.code && r.id != route.id);
    for (final other in otherRoutes) {
      await StorageService.restoreRouteState(other);
    }
    final fin = await StorageService.loadTripFinancials(route.code);
    _advanceEur = fin.advanceEur;
    _advancePln = fin.advancePln;
    _cashCollectedPln = fin.cashPln;
    _cashCollectedEur = fin.cashEur;
    if (mounted) setState(() {});
  }

  Future<void> _importFromAssets() async {
    setState(() => _isLoading = true);
    try {
      final routes = await ExcelParserService.loadFromAssets();
      if (routes.isNotEmpty) {
        await StorageService.setHasActiveTrip(true);
        setState(() {
          _allRoutes = routes;
          if (!_availableBusCodes.contains(_selectedBusCode)) {
            _selectedBusCode = _availableBusCodes.first;
          }
        });
        await _restoreStateForRoute(_currentRoute);
        if (mounted) {
          final totalPassengers = routes.fold(0, (s, r) => s + r.stops.length);
          _showNotice(
            'Wczytano ${routes.length} tras (${_availableBusCodes.length} busów, $totalPassengers pasażerów) z pliku WEEK_01-02.08.2026.xlsx!',
            Icons.check_circle,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showNotice('Błąd wczytywania: $e', Icons.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() => _isLoading = true);

        final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);

        if (bytes != null) {
          final routes = ExcelParserService.parseExcelBytes(bytes);
          if (routes.isNotEmpty) {
            await StorageService.setHasActiveTrip(true);
            setState(() {
              _allRoutes = routes;
              if (!_availableBusCodes.contains(_selectedBusCode)) {
                _selectedBusCode = _availableBusCodes.first;
              }
            });
            await _restoreStateForRoute(_currentRoute);
            if (mounted) {
              final totalPassengers = routes.fold(0, (s, r) => s + r.stops.length);
              _showNotice(
                'Wczytano ${file.name}: ${routes.length} tras (${_availableBusCodes.length} busów, $totalPassengers pasażerów)!',
                Icons.check_circle,
              );
            }
          } else if (mounted) {
            _showNotice('Nie znaleziono pasujących tras w pliku.', Icons.warning);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showNotice('Błąd importu pliku: $e', Icons.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import rozkładu jazdy (Excel)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.brandingOrange,
                  child: Icon(Icons.file_upload, color: Colors.white, size: 20),
                ),
                title: Text('Wybierz plik Excel z urządzenia', style: TextStyle(color: _textPrimary)),
                subtitle: Text('Wybierz dowolny plik .xlsx z pamięci telefonu / dysku', style: TextStyle(color: _textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickExcelFile();
                },
              ),
              if (_showDevOptions)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.calendar_month, color: Colors.white, size: 20),
                  ),
                  title: Text('Wczytaj WEEK_01-02.08.2026.xlsx (Test)', style: TextStyle(color: _textPrimary)),
                  subtitle: Text('Załaduj cały weekend dla wszystkich busów (BB.01 - BB.10)', style: TextStyle(color: _textSecondary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _importFromAssets();
                  },
                ),
              if (_allRoutes.isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFC10801),
                    child: Icon(Icons.flag_outlined, color: Colors.white, size: 20),
                  ),
                  title: const Text(
                    'Zakończ kurs i wyczyść dane',
                    style: TextStyle(color: Color(0xFFC10801), fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Wyczyść dane bieżącego weekendu i przygotuj aplikację na nowy kurs',
                    style: TextStyle(color: _textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmFinishTrip();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmFinishTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFC10801)),
            SizedBox(width: 8),
            Expanded(child: Text('Zakończyć kurs?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upewnij się, że pobrałeś plik Word (.docx) lub wysłałeś raport na WhatsApp!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Wszystkie dane tego wyjazdu zostaną trwale wyczyszczone z telefonu:\n'
              '• Przebieg i stan licznika (START / KONIEC)\n'
              '• Rejestr tankowań i paliwa\n'
              '• Zarejestrowane pauzy i przerwy\n'
              '• Statusy pasażerów i godziny dowozów\n'
              '• Rozliczenie gotówki i zaliczek\n\n'
              'Aplikacja zostanie zresetowana i przygotowana na wczytanie nowego rozkładu (.xlsx).',
              style: TextStyle(fontSize: 12.5, color: _textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Wróć'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC10801),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever, size: 16),
            label: const Text('Wyczyść i zakończ kurs'),
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _executeFinishTrip();
    }
  }

  Future<void> _executeFinishTrip() async {
    setState(() => _isLoading = true);
    await StorageService.clearAllTripData();
    setState(() {
      _allRoutes = [];
      _advanceEur = 0.0;
      _advancePln = 0.0;
      _cashCollectedPln = 0.0;
      _cashCollectedEur = 0.0;
      _isLoading = false;
    });
    if (mounted) {
      _showNotice(
        'Kurs został pomyślnie zakończony, a baza wyczyszczona!',
        Icons.check_circle,
      );
    }
  }

  Widget _buildNoActiveTripView(AppThemeData activeTheme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Zdjęcie mercedesa na trasie w tle z 30% przezroczystością
        Positioned.fill(
          child: Opacity(
            opacity: 0.30,
            child: Image.asset(
              'assets/images/mercedes_vito_road.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(-0.25, 0.0),
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ),
        // Delikatny gradient przyciemniający górę dla czytelności paska stanu
        // Dół i środek pozostają przejrzyste, aby tapeta była świetnie widoczna
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.20),
                ],
                stops: const [0.0, 0.22, 0.60, 1.0],
              ),
            ),
          ),
        ),
        // Zawartość ekranu (Logo, opis na górze; przyciski na dole ekranu)
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Górna sekcja: Logo BalticBus, tytuł i opis
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          // Logo BalticBus (5-krotne kliknięcie odblokowuje/ukrywa opcje testowe)
                          GestureDetector(
                            key: const ValueKey('balticbus_logo_detector'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _logoTapCounter++;
                              if (_logoTapCounter >= 5) {
                                _logoTapCounter = 0;
                                setState(() {
                                  _showDevOptions = !_showDevOptions;
                                });
                                _showNotice(
                                  _showDevOptions
                                      ? 'Odblokowano opcje testowe (Assets)'
                                      : 'Ukryto opcje testowe',
                                  _showDevOptions ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                  const Color(0xFFCBD5E1),
                                );
                              }
                            },
                            child: Container(
                              width: 330,
                              height: 115,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Image.asset(
                                'assets/images/balticbus_logo.png',
                                height: 105,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 105,
                                  height: 105,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.brandingOrange.withValues(alpha: 0.35),
                                        activeTheme.boxStart,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: AppColors.brandingOrange.withValues(alpha: 0.65),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus,
                                    color: Colors.white,
                                    size: 52,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Brak aktywnego kursu',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Poprzedni kurs został rozliczony, a baza danych wyczyszczona.\nWczytaj rozkład jazdy (.xlsx) na kolejny weekend.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: _textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      // Dolna sekcja: Przezroczyste boksy akcji umieszczone na dole ekranu
                      Padding(
                        padding: const EdgeInsets.only(top: 28, bottom: 12),
                        child: Column(
                          children: [
                            _buildOutlinedActionCard(
                              icon: Icons.file_upload,
                              accentColor: const Color(0xFFCBD5E1),
                              title: 'Wczytaj plik Excel (.xlsx)',
                              onTap: _pickExcelFile,
                            ),
                            if (_showDevOptions) ...[
                              const SizedBox(height: 14),
                              _buildOutlinedActionCard(
                                icon: Icons.bug_report_outlined,
                                accentColor: const Color(0xFF94A3B8),
                                title: 'Wczytaj z bazy (Assets)',
                                trailingBadge: _buildBrandBadge('DEV / TEST', const Color(0xFF94A3B8)),
                                onTap: _importFromAssets,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOutlinedActionCard({
    required IconData icon,
    required Color accentColor,
    required String title,
    String subtitle = '',
    required VoidCallback onTap,
    Widget? trailingBadge,
    bool showBorder = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: showBorder
            ? Border.all(
                color: accentColor,
                width: 1.3,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: accentColor.withValues(alpha: 0.25),
          highlightColor: accentColor.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 6,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (trailingBadge != null) ...[
                            const SizedBox(width: 6),
                            trailingBadge,
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.2,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updatePassengerStatus(PassengerStop stop, PickupStatus status) {
    setState(() {
      stop.status = status;
      final now = DateTime.now();
      if (status == PickupStatus.pickedUp) {
        stop.pickedUpAt ??= now;
        stop.isCollapsed = true;
      } else if (status == PickupStatus.delivered) {
        stop.deliveredAt ??= now;
        stop.isCollapsed = true;
      } else if (status == PickupStatus.pending) {
        stop.isCollapsed = true;
      } else if (status == PickupStatus.noShow || status == PickupStatus.cancelled) {
        stop.isCollapsed = true;
      }
    });

    // Zapis offline
    StorageService.savePassengerState(
      _currentRoute.id,
      stop.order,
      stop.status,
      stop.pickedUpAt,
      stop.deliveredAt,
    );
  }

  void _togglePassengerCollapse(PassengerStop stop) {
    setState(() {
      stop.isCollapsed = !stop.isCollapsed;
    });
  }

  void _toggleTransferPoint(TransferPoint point) {
    setState(() {
      point.isCompleted = !point.isCompleted;
    });
  }

  void _toggleDriverBreak() {
    final route = _currentRoute;
    final active = route.activeBreak;
    setState(() {
      if (active == null) {
        final b = DriverBreak(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startTime: DateTime.now(),
        );
        route.breaks.add(b);
        _showNotice(
          'Rozpoczęto przerwę o ${_formatTime(b.startTime)}',
          Icons.coffee,
        );
      } else {
        active.endTime = DateTime.now();
        _showNotice(
          'Zakończono przerwę (${active.durationMinutes} min, ${_formatTime(active.startTime)} - ${_formatTime(active.endTime!)})',
          Icons.check_circle,
        );
      }
    });
    StorageService.saveBreaks(route.id, route.breaks);
  }

  void _editOdometer(bool isStart) {
    final startVal = _tripStartOdometer;
    final endVal = _tripEndOdometer;
    final controller = TextEditingController(
      text: isStart
          ? (startVal?.toString() ?? '')
          : (endVal?.toString() ?? ''),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isStart ? 'Licznik START' : 'Licznik KONIEC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isStart
                  ? 'Podaj stan licznika na początku całej trasy (przed wyjazdem).'
                  : 'Podaj stan licznika po zakończeniu całej trasy (po powrocie na bazę).',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: isStart ? 'Stan licznika START (km)' : 'Stan licznika KONIEC (km)',
                border: const OutlineInputBorder(),
                suffixText: 'km',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandingOrange,
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              setState(() {
                if (isStart) {
                  final sat = _saturdayRoute;
                  if (sat != null) {
                    sat.startOdometerKm = val;
                    StorageService.saveOdometers(sat.id, sat.startOdometerKm, sat.endOdometerKm);
                  }
                  final sun = _sundayRoute;
                  if (sun != null && sat == null) {
                    sun.startOdometerKm = val;
                    StorageService.saveOdometers(sun.id, sun.startOdometerKm, sun.endOdometerKm);
                  }
                  StorageService.saveTripOdometers(_selectedBusCode, val, null);
                } else {
                  final sun = _sundayRoute;
                  if (sun != null) {
                    sun.endOdometerKm = val;
                    StorageService.saveOdometers(sun.id, sun.startOdometerKm, sun.endOdometerKm);
                  }
                  final sat = _saturdayRoute;
                  if (sat != null && sun == null) {
                    sat.endOdometerKm = val;
                    StorageService.saveOdometers(sat.id, sat.startOdometerKm, sat.endOdometerKm);
                  }
                  StorageService.saveTripOdometers(_selectedBusCode, null, val);
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  void _showRefuelingsSheet() {
    final route = _currentRoute;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_gas_station, color: AppColors.brandingOrange),
                          const SizedBox(width: 8),
                          Text(
                            'Tankowania na trasie',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  if (route.refuelings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _subtleBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Diesel (ON)', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                              Text(
                                '${route.totalDieselLiters.toStringAsFixed(1)} L',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.brandingOrange),
                              ),
                            ],
                          ),
                          if (route.totalAdBlueLiters > 0)
                            Column(
                              children: [
                                const Text('AdBlue', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                                Text(
                                  '${route.totalAdBlueLiters.toStringAsFixed(1)} L',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                          if (route.averageConsumptionLPer100Km != null)
                            Column(
                              children: [
                                const Text('Śr. spalanie ON', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                                Text(
                                  '${route.averageConsumptionLPer100Km!.toStringAsFixed(2)} l/100km',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...route.refuelings.map((ref) {
                      final isAdBlue = ref.fuelType == 'AdBlue';
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: _cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: _borderColor),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: isAdBlue ? Colors.blue.shade100 : (_isDark ? AppColors.darkCard : AppColors.primary),
                            child: Icon(
                              isAdBlue ? Icons.water_drop : Icons.ev_station,
                              color: isAdBlue ? Colors.blue.shade800 : Colors.white,
                              size: 14,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                '${ref.liters.toStringAsFixed(1)} L • ${ref.amount.toStringAsFixed(2)} ${ref.currency}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isAdBlue ? Colors.blue.shade50 : AppColors.brandingOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isAdBlue ? Colors.blue.shade200 : AppColors.brandingOrange.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  ref.fuelType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isAdBlue ? Colors.blue.shade900 : AppColors.brandingOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${ref.stationName} (${ref.paymentMethod}) @ ${ref.odometerKm} km',
                            style: TextStyle(color: _textSecondary),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () {
                              setSheetState(() {
                                route.refuelings.removeWhere((r) => r.id == ref.id);
                              });
                              setState(() {});
                              StorageService.saveRefuelings(route.id, route.refuelings);
                            },
                          ),
                        ),
                      );
                    }),
                    const Divider(height: 20),
                  ],
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandingOrange,
                      minimumSize: const Size.fromHeight(45),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj nowe tankowanie'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddRefuelingDialog();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddRefuelingDialog() {
    final route = _currentRoute;
    final odoController = TextEditingController(
      text: (route.endOdometerKm ?? route.startOdometerKm ?? '').toString(),
    );
    final litersController = TextEditingController();
    final amountController = TextEditingController();
    String fuelType = 'Diesel (ON)';
    String stationName = 'MOYA';
    String paymentMethod = 'Karta flota MOYA';
    String currency = 'PLN';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.local_gas_station, color: AppColors.brandingOrange),
              SizedBox(width: 8),
              Text('Nowe tankowanie', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Co było tankowane: Diesel (ON) vs AdBlue
                const Text('Co było tankowane:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'Diesel (ON)',
                      label: Text('Diesel (ON)'),
                      icon: Icon(Icons.local_gas_station, size: 16),
                    ),
                    ButtonSegment<String>(
                      value: 'AdBlue',
                      label: Text('AdBlue'),
                      icon: Icon(Icons.water_drop, size: 16),
                    ),
                  ],
                  selected: {fuelType},
                  onSelectionChanged: (newVal) {
                    setDialogState(() {
                      fuelType = newVal.first;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Stan licznika
                TextField(
                  controller: odoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stan licznika (km)',
                    border: OutlineInputBorder(),
                    suffixText: 'km',
                  ),
                ),
                const SizedBox(height: 10),

                // Ilość litrów i kwota
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: litersController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Litry (L)',
                          border: OutlineInputBorder(),
                          suffixText: 'L',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Kwota ($currency)',
                          border: const OutlineInputBorder(),
                          suffixText: currency,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Stacja paliw: tylko MOYA oraz Tankowanie DE
                DropdownButtonFormField<String>(
                  initialValue: stationName,
                  decoration: const InputDecoration(
                    labelText: 'Stacja paliw',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MOYA', child: Text('MOYA')),
                    DropdownMenuItem(value: 'Tankowanie DE', child: Text('Tankowanie DE')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        stationName = val;
                        if (val == 'Tankowanie DE') {
                          paymentMethod = 'Gotówka EUR';
                          currency = 'EUR';
                        } else {
                          paymentMethod = 'Karta flota MOYA';
                          currency = 'PLN';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Metoda płatności: tylko Karta flota MOYA, Gotówka PLN, Gotówka EUR
                DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Metoda płatności',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Karta flota MOYA', child: Text('Karta flota MOYA')),
                    DropdownMenuItem(value: 'Gotówka PLN', child: Text('Gotówka PLN')),
                    DropdownMenuItem(value: 'Gotówka EUR', child: Text('Gotówka EUR')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        paymentMethod = val;
                        if (val == 'Gotówka EUR') {
                          currency = 'EUR';
                        } else {
                          currency = 'PLN';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Wybór waluty (PLN / EUR)
                Row(
                  children: [
                    const Text('Waluta: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ChoiceChip(
                      label: const Text('PLN'),
                      selected: currency == 'PLN',
                      onSelected: (val) {
                        setDialogState(() => currency = 'PLN');
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('EUR'),
                      selected: currency == 'EUR',
                      onSelected: (val) {
                        setDialogState(() => currency = 'EUR');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandingOrange,
              ),
              onPressed: () {
                final odo = int.tryParse(odoController.text.trim()) ?? 0;
                final liters = double.tryParse(litersController.text.replaceAll(',', '.').trim()) ?? 0.0;
                final amount = double.tryParse(amountController.text.replaceAll(',', '.').trim()) ?? 0.0;

                if (liters <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Podaj poprawną liczbę litrów')),
                  );
                  return;
                }

                final newRefueling = RefuelingEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  odometerKm: odo,
                  liters: liters,
                  amount: amount,
                  currency: currency,
                  stationName: stationName,
                  paymentMethod: paymentMethod,
                  fuelType: fuelType,
                  timestamp: DateTime.now(),
                );

                setState(() {
                  route.refuelings.add(newRefueling);
                  if (route.endOdometerKm == null || odo > route.endOdometerKm!) {
                    route.endOdometerKm = odo;
                  }
                });

                StorageService.saveRefuelings(route.id, route.refuelings);
                StorageService.saveOdometers(route.id, route.startOdometerKm, route.endOdometerKm);

                Navigator.pop(ctx);
                _showNotice(
                  'Zapisano: ${liters.toStringAsFixed(1)} L $fuelType na stacji $stationName ($paymentMethod)!',
                  fuelType == 'AdBlue' ? Icons.water_drop : Icons.local_gas_station,
                );
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeStyle>(
      valueListenable: AppColors.currentTheme,
      builder: (context, currentThemeStyle, _) {
        final activeTheme = AppColors.activeTheme;

        if (_allRoutes.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            extendBody: true,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.palette_outlined, color: Colors.white, size: 20),
                    tooltip: 'Zmień motyw',
                    onPressed: _showThemeSelectorSheet,
                  ),
                ),
              ],
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.brandingOrange),
                  )
                : _buildNoActiveTripView(activeTheme),
          );
        }

        final route = _currentRoute;
        final isPLtoDE = route.direction == 'PL-DE';

        return Container(
          decoration: BoxDecoration(
            gradient: activeTheme.screenGradient,
          ),
          child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            '${route.code} • ${route.vehicleModel} (${route.registrationNumber})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.palette_outlined, color: Colors.white, size: 20),
                tooltip: 'Zmień motyw (Emerald / Walnut)',
                onPressed: _showThemeSelectorSheet,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.file_open_outlined, color: Colors.white, size: 20),
                tooltip: 'Wczytaj rozkład z pliku Excel',
                onPressed: _showImportOptions,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                tooltip: 'Wybierz pojazd (${_availableBusCodes.length} dostępnych)',
                initialValue: _selectedBusCode,
                onSelected: (code) {
                  setState(() {
                    _selectedBusCode = code;
                  });
                  _restoreStateForRoute(_currentRoute);
                },
                itemBuilder: (context) => _availableBusCodes.map((code) {
                  final bus = _allRoutes.firstWhere((r) => r.code == code);
                  return PopupMenuItem<String>(
                    value: code,
                    child: Text('$code – ${bus.vehicleModel} (${bus.driverName})'),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.brandingOrange),
                    SizedBox(height: 16),
                    Text(
                      'Wczytywanie trasy...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  // Szybkie akcje kierowcy (Pauza, Paliwo, Plan Jazdy) - pastylki bez boxa
                  _buildQuickActionsBar(route),
                  const SizedBox(height: 12),

                  // Przełącznik Dnia / Kierunku (Sobota Wywóz vs Niedziela Przywóz) - pastylki bez boxa
                  _buildDaySelector(),
                  const SizedBox(height: 12),

                  // Karta pojazdu, kierowcy i kierunku trasy
                  _buildVehicleCard(route, isPLtoDE),
                  const SizedBox(height: 12),

                  // Liczniki kilometrów (START / STOP)
                  _buildOdometerCard(route),
                  const SizedBox(height: 12),

                  // Aktywna przerwa kierowcy (jeśli trwa)
                  if (route.activeBreak != null) ...[
                    _buildActiveBreakBanner(route.activeBreak!),
                    const SizedBox(height: 12),
                  ],

                  // Specjalne uwagi logistyczne
                  if (route.specialNotes.isNotEmpty) ...[
                    _buildSpecialNotesCard(route.specialNotes),
                    const SizedBox(height: 12),
                  ],

                  // Punkty przesiadkowe
                  if (route.transferPoints.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '🔄 Punkty przesiadkowe i zbiórki',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                    ),
                    ...route.transferPoints.map(_buildTransferPointCard),
                    const SizedBox(height: 12),
                  ],

                  // Lista pasażerów
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPLtoDE
                              ? '👥 Wywóz: Pasażerowie do Niemiec'
                              : '👥 Przywóz: Pasażerowie do Polski',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                        Text(
                          '${route.stops.length} adresów',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  ...route.stops.map((stop) => _buildPassengerCard(stop, isPLtoDE)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      );
  }

  BoxDecoration _convexDecoration({
    Color? baseStartColor,
    Color? baseEndColor,
    Color? baseTopColor,
    Color? baseBottomColor,
    BorderRadius? borderRadius,
    Color? borderColor,
    double borderWidth = 1.2,
    bool isHighlighted = false,
  }) {
    final theme = AppColors.activeTheme;
    final start = baseStartColor ?? baseTopColor ?? theme.boxStart;
    final end = baseEndColor ?? baseBottomColor ?? theme.boxEnd;
    final radius = borderRadius ?? BorderRadius.circular(16);
    final borderCol = borderColor ??
        (_isDark
            ? (isHighlighted
                ? theme.secondaryAccent
                : theme.border.withValues(alpha: 0.45))
            : Colors.white.withValues(alpha: 0.90));

    return BoxDecoration(
      borderRadius: radius,
      gradient: _isDark
          ? LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [start, end],
            )
          : LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.white.withValues(alpha: 0.94),
              ],
            ),
      border: Border.all(
        color: borderCol,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: _isDark ? 0.65 : 0.22),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 8),
        ),
        if (_isDark)
          BoxShadow(
            color: borderCol.withValues(alpha: isHighlighted ? 0.35 : 0.15),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
      ],
    );
  }

  Widget _buildQuickActionsBar(BusRoute route) {
    final isBreakActive = route.activeBreak != null;

    return Row(
      children: [
        // Pastylka Pauza
        Expanded(
          child: _buildActionPill(
            label: isBreakActive
                ? 'Koniec pauzy'
                : (route.breaks.isNotEmpty ? 'Pauza (${route.breaks.length})' : 'Pauza'),
            icon: isBreakActive ? Icons.stop_circle_outlined : Icons.coffee,
            isActive: isBreakActive,
            onTap: _toggleDriverBreak,
          ),
        ),
        const SizedBox(width: 8),

        // Pastylka Paliwo
        Expanded(
          child: _buildActionPill(
            label: route.refuelings.isNotEmpty
                ? 'Paliwo (${route.refuelings.length})'
                : 'Paliwo',
            icon: Icons.local_gas_station,
            onTap: _showRefuelingsSheet,
          ),
        ),
        const SizedBox(width: 8),

        // Pastylka Plan Jazdy
        Expanded(
          child: _buildActionPill(
            label: 'Plan Jazdy',
            icon: Icons.assignment,
            onTap: _showPlanJazdyDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final theme = AppColors.activeTheme;

    // Pełna spójność kolorystyczna z aktywnym motywem
    final Gradient gradient = isActive
        ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF8B251B), Color(0xFFC84031)],
          )
        : LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              theme.boxStart.withValues(alpha: 0.90),
              theme.boxEnd.withValues(alpha: 0.75),
            ],
          );

    final Border border = Border.all(
      color: isActive
          ? Colors.white
          : theme.border.withValues(alpha: 0.50),
      width: isActive ? 1.4 : 1.1,
    );

    final List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.40),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
      if (isActive)
        BoxShadow(
          color: const Color(0xFFC84031).withValues(alpha: 0.45),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(22),
            border: border,
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : theme.secondaryAccent,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSelectorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF0F161A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: AppColors.activeTheme.border.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Wybierz motyw kolorystyczny',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Wybierz wzór palety barw dla aplikacji kierowcy:',
                    style: TextStyle(fontSize: 13, color: Colors.white60),
                  ),
                  const SizedBox(height: 18),
                  ...AppThemeStyle.values.map((style) {
                    final data = AppColors.themes[style]!;
                    final isSelected = AppColors.currentTheme.value == style;
                    return _buildThemePreviewCard(
                      theme: data,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          AppColors.currentTheme.value = style;
                        });
                        StorageService.savePaletteTheme(style.name);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemePreviewCard({
    required AppThemeData theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final hexStart = '#${theme.boxStart.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    final hexEnd = '#${theme.boxEnd.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: theme.cardGradient,
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : theme.border.withValues(alpha: 0.50),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 7),
              ),
              if (isSelected)
                BoxShadow(
                  color: theme.secondaryAccent.withValues(alpha: 0.40),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hexStart,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    theme.title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.8,
                      color: Colors.white,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  ],
                ],
              ),
              Text(
                hexEnd,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBreakBanner(DriverBreak activeBreak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _convexDecoration(
        baseTopColor: _isDark ? const Color(0xFF3D2C14) : Colors.amber.shade100,
        baseBottomColor: _isDark ? const Color(0xFF261A0A) : Colors.amber.shade50,
        borderColor: Colors.amber.shade600,
        borderWidth: 1.8,
        isHighlighted: true,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF422E15) : Colors.amber.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.coffee, color: Colors.amber, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '☕ TRWA PRZERWA KIEROWCY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _isDark ? Colors.amber.shade300 : Colors.brown,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rozpoczęto: ${_formatTime(activeBreak.startTime)} (${activeBreak.durationMinutes} min temu)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.stop, size: 16),
            label: const Text('Zakończ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: _toggleDriverBreak,
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final dates = _availableDates;
    if (dates.length < 2) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // Pastylka Sobota
        Expanded(
          child: _buildDayPill(
            label: 'Sobota (${_shortDate(dates[0])})',
            icon: Icons.flight_takeoff,
            isSelected: _selectedDate == dates[0],
            onTap: () {
              setState(() => _selectedDate = dates[0]);
              _restoreStateForRoute(_currentRoute);
            },
          ),
        ),
        const SizedBox(width: 8),

        // Pastylka Niedziela
        Expanded(
          child: _buildDayPill(
            label: 'Niedziela (${_shortDate(dates[1])})',
            icon: Icons.flight_land,
            isSelected: _selectedDate == dates[1],
            onTap: () {
              setState(() => _selectedDate = dates[1]);
              _restoreStateForRoute(_currentRoute);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = AppColors.activeTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: isSelected
                ? LinearGradient(
                    colors: [theme.primaryAccent, theme.secondaryAccent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [
                      theme.boxStart.withValues(alpha: 0.90),
                      theme.boxEnd.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.90)
                  : theme.border.withValues(alpha: 0.50),
              width: isSelected ? 1.4 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              if (isSelected)
                BoxShadow(
                  color: theme.primaryAccent.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : theme.secondaryAccent,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.90),
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(String date) {
    final parts = date.split('-');
    if (parts.length >= 3) {
      return '${parts[2]}.${parts[1]}';
    }
    return date;
  }

  Widget _buildVehicleCard(BusRoute route, bool isPLtoDE) {
    return Container(
      decoration: _convexDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    route.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPLtoDE
                        ? AppColors.brandingOrange.withValues(alpha: 0.15)
                        : (_isDark ? const Color(0xFF093F52).withValues(alpha: 0.35) : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPLtoDE
                          ? AppColors.brandingOrange.withValues(alpha: 0.4)
                          : (_isDark ? const Color(0xFF65A7C2).withValues(alpha: 0.45) : Colors.blue.shade300),
                    ),
                  ),
                  child: Text(
                    isPLtoDE ? '🛫 WYWÓZ (PL ➔ DE)' : '🛬 PRZYWÓZ (DE ➔ PL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPLtoDE
                          ? AppColors.brandingOrange
                          : (_isDark ? const Color(0xFFC7E5F2) : const Color(0xFF093F52)),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${route.plannedDistanceKm} km',
                  style: const TextStyle(
                    color: AppColors.brandingOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            Divider(height: 18, color: _borderColor),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.gray),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    route.driverName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (route.driverPhone.isNotEmpty)
                  InkWell(
                    onTap: () => LauncherService.openPhone(
                      context,
                      route.driverPhone,
                      route.driverName,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 15, color: AppColors.brandingOrange),
                          const SizedBox(width: 4),
                          Text(
                            route.driverPhone,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.brandingOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (route.googleMapsUrl != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isDark ? Colors.white : AppColors.primary,
                    side: const BorderSide(color: AppColors.brandingOrange),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => LauncherService.openFullRoute(
                    context,
                    route.googleMapsUrl!,
                  ),
                  icon: const Icon(Icons.map, size: 18, color: AppColors.brandingOrange),
                  label: const Text(
                    'Otwórz zaplanowaną trasę w Google Maps',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOdometerCard(BusRoute route) {
    final start = _tripStartOdometer;
    final end = _tripEndOdometer;
    final diff = _tripDistanceKm;

    return Container(
      decoration: _convexDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // START (cała trasa)
            Expanded(
              child: InkWell(
                onTap: () => _editOdometer(true),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.play_circle_outline, size: 14, color: AppColors.activeTheme.secondaryAccent),
                          const SizedBox(width: 4),
                          Text(
                            'START',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.activeTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        start != null ? '$start km' : 'Podaj na starcie',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: start != null ? _textPrimary : AppColors.brandingOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 36, color: _borderColor),
            // KONIEC (cała trasa)
            Expanded(
              child: InkWell(
                onTap: () => _editOdometer(false),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 14, color: AppColors.activeTheme.secondaryAccent),
                          const SizedBox(width: 4),
                          Text(
                            'KONIEC',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.activeTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        end != null ? '$end km' : 'Podaj po powrocie',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: end != null ? _textPrimary : AppColors.brandingOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (diff != null) ...[
              Container(width: 1, height: 36, color: _borderColor),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Cała trasa',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.activeTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$diff km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.brandingOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialNotesCard(List<String> notes) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _convexDecoration(
        baseTopColor: _isDark ? AppColors.activeTheme.boxEnd : AppColors.primary.withValues(alpha: 0.15),
        baseBottomColor: _isDark ? AppColors.activeTheme.boxStart : AppColors.primary.withValues(alpha: 0.05),
        borderColor: AppColors.activeTheme.border,
        borderWidth: 1.5,
        isHighlighted: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.brandingOrange, size: 20),
              const SizedBox(width: 6),
              Text(
                'Ważne polecenia logistyczne:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $note',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferPointCard(TransferPoint point) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: _convexDecoration(
        borderRadius: BorderRadius.circular(12),
        baseTopColor: point.isCompleted
            ? (_isDark ? AppColors.activeTheme.boxStart.withValues(alpha: 0.6) : Colors.grey.shade100)
            : null,
        baseBottomColor: point.isCompleted
            ? (_isDark ? AppColors.activeTheme.boxStart.withValues(alpha: 0.3) : Colors.grey.shade50)
            : null,
        borderColor: point.isCompleted ? _borderColor : AppColors.activeTheme.border,
        borderWidth: point.isCompleted ? 1.0 : 1.5,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: CheckboxListTile(
          activeColor: AppColors.brandingOrange,
          value: point.isCompleted,
          onChanged: (_) => _toggleTransferPoint(point),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            '${point.time} • ${point.location}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _textPrimary,
              decoration: point.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            point.instruction,
            style: TextStyle(
              fontSize: 12,
              color: point.isCompleted ? AppColors.gray : _textSecondary,
            ),
          ),
          secondary: IconButton(
            icon: const Icon(Icons.near_me, color: AppColors.brandingOrange, size: 20),
            tooltip: 'Nawiguj do punktu',
            onPressed: () => LauncherService.openNavigation(context, point.location),
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerCard(PassengerStop stop, bool isPLtoDE) {
    final isDelivered = stop.status == PickupStatus.delivered;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (stop.status) {
      case PickupStatus.pickedUp:
        statusColor = const Color(0xFF27AE60);
        final timeStr = stop.pickedUpAt != null ? ' (${_formatTime(stop.pickedUpAt!)})' : '';
        statusText = 'Odebrany$timeStr';
        statusIcon = Icons.check_circle;
        break;
      case PickupStatus.delivered:
        statusColor = _isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);
        final timeStr = stop.deliveredAt != null ? ' (${_formatTime(stop.deliveredAt!)})' : '';
        statusText = 'Dostarczony$timeStr';
        statusIcon = Icons.home;
        break;
      case PickupStatus.noShow:
        statusColor = const Color(0xFFC10801);
        statusText = 'Nieobecny';
        statusIcon = Icons.cancel;
        break;
      case PickupStatus.cancelled:
        statusColor = AppColors.gray;
        statusText = 'Odwołany';
        statusIcon = Icons.block;
        break;
      case PickupStatus.pending:
        statusColor = AppColors.brandingOrange;
        statusText = 'Oczekuje';
        statusIcon = Icons.schedule;
        break;
    }

    final Widget cardWidget;

    // Widok zwiniętej karty
    if (stop.isCollapsed) {
      cardWidget = Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: _convexDecoration(
          borderRadius: BorderRadius.circular(12),
          borderColor: isDelivered
              ? (_isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade400)
              : statusColor.withValues(alpha: 0.70),
          borderWidth: isDelivered ? 1.0 : 1.4,
          isHighlighted: !isDelivered && stop.status == PickupStatus.pending,
          baseStartColor: isDelivered
              ? (_isDark ? const Color(0xFF141414) : Colors.grey.shade200)
              : null,
          baseEndColor: isDelivered
              ? (_isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _togglePassengerCollapse(stop),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isDelivered
                        ? (_isDark ? Colors.white12 : Colors.grey.shade300)
                        : statusColor.withValues(alpha: 0.15),
                    child: Text(
                      '${stop.order}',
                      style: TextStyle(
                        color: isDelivered
                            ? (_isDark ? Colors.white60 : Colors.grey.shade700)
                            : statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                stop.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDelivered
                                      ? (_isDark ? Colors.white60 : Colors.black54)
                                      : _textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${stop.passengerCount} os.)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDelivered
                                    ? (_isDark ? Colors.white38 : Colors.grey.shade600)
                                    : AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                            if (stop.resort.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• ${stop.resort}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDelivered
                                      ? (_isDark ? Colors.white38 : Colors.grey.shade600)
                                      : AppColors.gray,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: isDelivered
                          ? (_isDark ? Colors.white38 : Colors.grey.shade500)
                          : AppColors.gray,
                    ),
                    tooltip: 'Rozwiń szczegóły',
                    onPressed: () => _togglePassengerCollapse(stop),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Widok rozwiniętej karty
      cardWidget = Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: _convexDecoration(
          borderRadius: BorderRadius.circular(14),
          borderColor: isDelivered
              ? (_isDark ? Colors.white.withValues(alpha: 0.14) : Colors.grey.shade400)
              : statusColor.withValues(alpha: 0.75),
          borderWidth: isDelivered ? 1.0 : 1.6,
          isHighlighted: !isDelivered && stop.status == PickupStatus.pending,
          baseStartColor: isDelivered
              ? (_isDark ? const Color(0xFF141414) : Colors.grey.shade200)
              : null,
          baseEndColor: isDelivered
              ? (_isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isDelivered
                          ? (_isDark ? Colors.white24 : Colors.grey)
                          : AppColors.primary,
                      child: Text(
                        '${stop.order}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDelivered
                                  ? (_isDark ? Colors.white60 : Colors.black54)
                                  : _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildBrandBadge('${stop.passengerCount} os.', _textSecondary),
                              if (stop.office.isNotEmpty)
                                _buildBrandBadge(stop.office, AppColors.gray),
                              if (stop.resort.isNotEmpty)
                                _buildBrandBadge(
                                  isPLtoDE ? '🏨 ${stop.resort}' : '🏨 Cel: ${stop.resort}',
                                  isDelivered
                                      ? (_isDark ? Colors.white54 : Colors.grey)
                                      : AppColors.brandingOrange,
                                ),
                              if (stop.comment.isNotEmpty)
                                _buildBrandBadge('⚠️ ${stop.comment}', const Color(0xFFC10801)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<PickupStatus>(
                      initialValue: stop.status,
                      tooltip: 'Zmień status',
                      onSelected: (newStatus) => _updatePassengerStatus(stop, newStatus),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: PickupStatus.pending,
                          child: Text('⏳ Oczekuje'),
                        ),
                        const PopupMenuItem(
                          value: PickupStatus.pickedUp,
                          child: Text('📥 Odebrany (zapisz czas)'),
                        ),
                        const PopupMenuItem(
                          value: PickupStatus.delivered,
                          child: Text('🏠 Dostarczony (zapisz czas)'),
                        ),
                        const PopupMenuItem(
                          value: PickupStatus.noShow,
                          child: Text('❌ Nieobecny'),
                        ),
                        const PopupMenuItem(
                          value: PickupStatus.cancelled,
                          child: Text('🚫 Odwołany'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _togglePassengerCollapse(stop),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.expand_less, size: 20, color: AppColors.gray),
                      ),
                    ),
                  ],
                ),
                Divider(height: 16, color: _borderColor),

                // Adres
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: isDelivered
                          ? (_isDark ? Colors.white38 : Colors.grey)
                          : AppColors.brandingOrange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stop.address,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDelivered
                              ? (_isDark ? Colors.white54 : Colors.black45)
                              : _textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Zarejestrowane czasy jeśli istnieją
                if (stop.pickedUpAt != null || stop.deliveredAt != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 22),
                      if (stop.pickedUpAt != null)
                        Text(
                          'Odebrano: ${_formatTime(stop.pickedUpAt!)} ',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDelivered ? Colors.grey : const Color(0xFF27AE60),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (stop.deliveredAt != null)
                        Text(
                          '• Dostarczono: ${_formatTime(stop.deliveredAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDelivered ? Colors.grey : const Color(0xFF1E824C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],

                // Czas i odległość jeśli dostępne
                if (stop.driveTime != null || stop.distance != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 22),
                      Text(
                        '${stop.driveTime ?? ''} • ${stop.distance ?? ''}',
                        style: const TextStyle(fontSize: 11, color: AppColors.gray),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // Przyciski akcji: Telefon i Nawigacja
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textSecondary,
                          side: BorderSide(color: _borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: stop.phone.isNotEmpty
                            ? () => LauncherService.openPhone(
                                  context,
                                  stop.phone,
                                  stop.name,
                                )
                            : null,
                        icon: const Icon(Icons.phone, size: 16),
                        label: Text(
                          stop.phone.isNotEmpty ? stop.phone : 'Brak tel.',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: isDelivered
                              ? (_isDark ? const Color(0xFF2C2C2C) : Colors.grey)
                              : AppColors.brandingOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: stop.address.isNotEmpty
                            ? () => LauncherService.openNavigation(
                                  context,
                                  stop.address,
                                )
                            : null,
                        icon: const Icon(Icons.near_me, size: 16),
                        label: const Text(
                          'Nawiguj',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isDelivered) {
      return Opacity(
        opacity: 0.55,
        child: cardWidget,
      );
    }
    return cardWidget;
  }

  Widget _buildBrandBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentNoticeOverlay?.remove();
    _currentNoticeOverlay = null;
    super.dispose();
  }

  void _showNotice(String message, IconData icon, [Color? accentColor]) {
    _currentNoticeOverlay?.remove();
    _currentNoticeOverlay = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final accent = accentColor ?? const Color(0xFFCBD5E1);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopNoticeWidget(
        message: message,
        icon: icon,
        accentColor: accent,
        onDismissed: () {
          if (_currentNoticeOverlay == entry) {
            entry.remove();
            _currentNoticeOverlay = null;
          }
        },
      ),
    );

    _currentNoticeOverlay = entry;
    overlay.insert(entry);
  }

  WeekendTripSummary _getWeekendTripSummaryForCurrentBus() {
    final busRoutes = _allRoutes.where((r) => r.code == _selectedBusCode).toList();

    BusRoute? satRoute;
    BusRoute? sunRoute;

    for (final r in busRoutes) {
      if (r.direction == 'PL-DE' || r.date.endsWith('-01')) {
        satRoute = r;
      } else if (r.direction == 'DE-PL' || r.date.endsWith('-02')) {
        sunRoute = r;
      }
    }

    if (satRoute == null && busRoutes.isNotEmpty) satRoute = busRoutes.first;
    if (sunRoute == null && busRoutes.length > 1) sunRoute = busRoutes[1];

    final baseRoute = satRoute ?? sunRoute ?? _currentRoute;

    String dateRange = baseRoute.date;
    if (satRoute != null && sunRoute != null && satRoute.date != sunRoute.date) {
      dateRange = '${_shortDate(satRoute.date)} - ${_shortDate(sunRoute.date)}.2026';
    }

    return WeekendTripSummary(
      busCode: baseRoute.code,
      dateRange: dateRange,
      driverName: baseRoute.driverName,
      driverPhone: baseRoute.driverPhone,
      vehicleModel: baseRoute.vehicleModel,
      registrationNumber: baseRoute.registrationNumber,
      saturdayRoute: satRoute,
      sundayRoute: sunRoute,
      advanceEur: _advanceEur,
      advancePln: _advancePln,
      cashCollectedPln: _cashCollectedPln,
      cashCollectedEur: _cashCollectedEur,
    );
  }

  void _showEditFinancialsDialog(VoidCallback onSaved) {
    final advEurCtrl = TextEditingController(text: _advanceEur > 0 ? _advanceEur.toStringAsFixed(2) : '');
    final advPlnCtrl = TextEditingController(text: _advancePln > 0 ? _advancePln.toStringAsFixed(2) : '');
    final cashEurCtrl = TextEditingController(text: _cashCollectedEur > 0 ? _cashCollectedEur.toStringAsFixed(2) : '');
    final cashPlnCtrl = TextEditingController(text: _cashCollectedPln > 0 ? _cashCollectedPln.toStringAsFixed(2) : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zaliczka i pobrania gotówki', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ZALICZKA OTRZYMANA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: advEurCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Zaliczka EUR', suffixText: '€', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: advPlnCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Zaliczka PLN', suffixText: 'zł', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('ODEBRANE OD GOŚCI:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cashEurCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Odebrane EUR', suffixText: '€', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: cashPlnCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Odebrane PLN', suffixText: 'zł', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brandingOrange),
            onPressed: () {
              setState(() {
                _advanceEur = double.tryParse(advEurCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                _advancePln = double.tryParse(advPlnCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                _cashCollectedEur = double.tryParse(cashEurCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                _cashCollectedPln = double.tryParse(cashPlnCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
              });
              StorageService.saveTripFinancials(
                busCode: _selectedBusCode,
                advanceEur: _advanceEur,
                advancePln: _advancePln,
                cashCollectedPln: _cashCollectedPln,
                cashCollectedEur: _cashCollectedEur,
              );
              Navigator.pop(ctx);
              onSaved();
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  void _showPlanJazdyDialog() {
    final summary = _getWeekendTripSummaryForCurrentBus();
    final start = summary.startOdometer;
    final end = summary.endOdometer;
    final diff = summary.totalDistanceKm;
    final consumption = summary.averageConsumptionLPer100Km;
    final satBreaks = summary.saturdayBreaks;
    final sunBreaks = summary.sundayBreaks;
    final maxBreaks = satBreaks.length > sunBreaks.length ? satBreaks.length : sunBreaks.length;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final eurStr = summary.advanceEur > 0 ? '${summary.advanceEur.toStringAsFixed(2)} €' : '0,00 €';
          final plnStr = summary.advancePln > 0 ? '${summary.advancePln.toStringAsFixed(2)} zł' : '0,00 zł';
          final guestPln = summary.cashCollectedPln > 0 ? '${summary.cashCollectedPln.toStringAsFixed(2)} zł' : '';
          final guestEur = summary.cashCollectedEur > 0 ? '${summary.cashCollectedEur.toStringAsFixed(2)} €' : '';
          final guestText = [guestEur, guestPln].where((s) => s.isNotEmpty).join(' / ');

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.assignment, color: AppColors.brandingOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLAN JAZDY • ${summary.busCode}',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${summary.dateRange} • ${summary.driverName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pojazd: ${summary.vehicleModel} / ${summary.registrationNumber}',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _textSecondary),
                  ),
                  const SizedBox(height: 10),

                  // TABELA: STAN LICZNIKA (START / KONIEC / SUMA)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: _borderColor),
                      borderRadius: BorderRadius.circular(8),
                      color: _subtleBg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: _isDark ? AppColors.darkCard : AppColors.primary,
                          child: const Text(
                            'STAN LICZNIKA',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('start', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                                  Text(
                                    start != null ? '$start' : '—',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 28, color: _borderColor),
                              Column(
                                children: [
                                  const Text('koniec', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                                  Text(
                                    end != null ? '$end' : '—',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 28, color: _borderColor),
                              Column(
                                children: [
                                  const Text('suma', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                                  Text(
                                    diff != null ? '$diff km' : '—',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.brandingOrange),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ZALICZKA & ODEBRANE OD GOŚCI (z opcją edycji)
                  InkWell(
                    onTap: () {
                      _showEditFinancialsDialog(() {
                        setDialogState(() {
                          summary.advanceEur = _advanceEur;
                          summary.advancePln = _advancePln;
                          summary.cashCollectedPln = _cashCollectedPln;
                          summary.cashCollectedEur = _cashCollectedEur;
                        });
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderColor),
                        borderRadius: BorderRadius.circular(8),
                        color: _cardBg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ZALICZKA:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray)),
                              Row(
                                children: [
                                  Text('$eurStr  /  $plnStr', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.edit, size: 14, color: AppColors.brandingOrange),
                                ],
                              ),
                            ],
                          ),
                          Divider(height: 12, color: _borderColor),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ODEBRANE OD GOŚCI:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray)),
                              Text(
                                guestText.isNotEmpty ? guestText : '0,00 zł / 0,00 €',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // WYDATKI EURO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: _borderColor),
                      borderRadius: BorderRadius.circular(8),
                      color: _subtleBg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('WYDATKI EURO:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray)),
                            Text(
                              '${summary.totalExpensesEur.toStringAsFixed(2)} EUR',
                              style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
                            ),
                          ],
                        ),
                        if (summary.expensesEur.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('0,00 EUR', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                          )
                        else
                          ...summary.expensesEur.map((e) => Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  '• ${e.amount.toStringAsFixed(2)} EUR (TANK - ${e.stationName})',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary),
                                ),
                              )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // WYDATKI ZŁ
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: _borderColor),
                      borderRadius: BorderRadius.circular(8),
                      color: _subtleBg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('WYDATKI ZŁ:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray)),
                            Text(
                              '${summary.totalExpensesPln.toStringAsFixed(2)} zł',
                              style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
                            ),
                          ],
                        ),
                        if (summary.expensesPln.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('0,00 zł', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                          )
                        else
                          ...summary.expensesPln.map((e) => Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  '• ${e.amount.toStringAsFixed(2)} zł (${e.fuelType} - ${e.stationName})',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary),
                                ),
                              )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ŚR. SPALANIE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF093F52).withValues(alpha: 0.35) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _isDark ? const Color(0xFF65A7C2).withValues(alpha: 0.35) : Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.speed, size: 16, color: AppColors.brandingOrange),
                            const SizedBox(width: 6),
                            Text(
                              'ŚR. SPALANIE:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          consumption != null ? '${consumption.toStringAsFixed(1).replaceAll('.', ',')} l/100km' : 'brak danych',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // PRZERWY (SOBOTA / NIEDZIELA)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: _borderColor),
                      borderRadius: BorderRadius.circular(8),
                      color: _subtleBg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: _isDark ? AppColors.darkCard : AppColors.white,
                          child: const Row(
                            children: [
                              Icon(Icons.coffee, size: 14, color: Colors.brown),
                              SizedBox(width: 6),
                              Text('PRZERWY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown)),
                            ],
                          ),
                        ),
                        if (maxBreaks == 0)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Brak zarejestrowanych przerw.', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('SOBOTA', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _textPrimary))),
                                    Expanded(child: Text('NIEDZIELA', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _textPrimary))),
                                  ],
                                ),
                                Divider(height: 8, color: _borderColor),
                                for (int i = 0; i < maxBreaks; i++) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          i < satBreaks.length
                                              ? '${i + 1}. ${_formatTime(satBreaks[i].startTime)} - ${satBreaks[i].endTime != null ? _formatTime(satBreaks[i].endTime!) : "w toku"}'
                                              : '',
                                          style: TextStyle(fontSize: 10.5, color: _textSecondary),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          i < sunBreaks.length
                                              ? '${i + 1}. ${_formatTime(sunBreaks[i].startTime)} - ${sunBreaks[i].endTime != null ? _formatTime(sunBreaks[i].endTime!) : "w toku"}'
                                              : '',
                                          style: TextStyle(fontSize: 10.5, color: _textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // PASAŻEROWIE
                  Text(
                    'Pasażerowie łącznie: ${summary.pickedUpPassengers} / ${summary.totalPassengers} os. (wywóz: ${summary.saturdayRoute?.pickedUpPassengers ?? 0}, przywóz: ${summary.sundayRoute?.pickedUpPassengers ?? 0})',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.gray),
                  ),
                ],
              ),
            ),
            actions: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _isDark ? Colors.white : AppColors.primary,
                  side: const BorderSide(color: AppColors.brandingOrange),
                ),
                icon: const Icon(Icons.description, size: 16, color: AppColors.brandingOrange),
                label: const Text('Zapisz Word (.docx)'),
                onPressed: () {
                  DocxReportService.savePlanJazdyDocxToDesktop(context, summary);
                },
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textSecondary,
                  side: BorderSide(color: _borderColor),
                ),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Kopiuj'),
                onPressed: () {
                  final text = ReportService.generatePlanJazdyText(summary);
                  ReportService.copyToClipboard(context, text);
                },
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('WhatsApp'),
                onPressed: () {
                  final text = ReportService.generatePlanJazdyText(summary);
                  ReportService.sendViaWhatsApp(context, text);
                },
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC10801),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Zakończ kurs'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmFinishTrip();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopNoticeWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onDismissed;

  const _TopNoticeWidget({
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.onDismissed,
  });

  @override
  State<_TopNoticeWidget> createState() => _TopNoticeWidgetState();
}

class _TopNoticeWidgetState extends State<_TopNoticeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    _dismissTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_controller.isAnimating || !_controller.isDismissed) {
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onDismissed();
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: topPadding + 12,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.opaque,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.accentColor,
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: widget.accentColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


