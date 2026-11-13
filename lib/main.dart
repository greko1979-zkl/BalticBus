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
  AppColors.currentTheme.value = AppThemeStyle.values.firstWhere(
    (s) => s.name == savedPalette,
    orElse: () => AppThemeStyle.balticNoir,
  );

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
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 380),
                      height: 150,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Image.asset(
                        'assets/images/balticbus_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 72,
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
  int _currentTabIndex = 0;
  bool _showCompletedPassengers = false;
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
    } else {
      // Automatycznie wczytujemy kompletny rozkład z pliku Excel (assets)
      try {
        final parsed = await ExcelParserService.loadFromAssets();
        if (parsed.isNotEmpty && mounted) {
          setState(() {
            _allRoutes = parsed;
          });
        }
      } catch (_) {
        if (_allRoutes.isEmpty && mounted) {
          setState(() {
            _allRoutes = sampleBusRoutes;
          });
        }
      }
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
        final busCodes = routes.map((r) => r.code).toSet().toList();
        final dates = routes.map((r) => r.date).toSet().toList()..sort();

        String defaultBus = _selectedBusCode;
        if (!busCodes.contains(defaultBus)) {
          defaultBus = busCodes.first;
        }

        setState(() {
          _allRoutes = routes;
          _selectedBusCode = defaultBus;
          if (!dates.contains(_selectedDate) && dates.isNotEmpty) {
            _selectedDate = dates.first;
          }
          _isLoading = false;
        });

        if (mounted) {
          if (busCodes.length > 1) {
            await _showBusSelectionDialog(busCodes, routes, 'WEEK_01-02.08.2026.xlsx');
          } else {
            await _restoreStateForRoute(_currentRoute);
            if (mounted) {
              _showNotice(
                'Wczytano ${routes.length} tras (${routes.first.driverName})!',
                Icons.check_circle,
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showNotice('Błąd wczytywania: $e', Icons.error);
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
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

            // Wylicz dostępne busy
            final busCodes = routes.map((r) => r.code).toSet().toList();
            final dates = routes.map((r) => r.date).toSet().toList()..sort();

            String defaultBus = _selectedBusCode;
            if (!busCodes.contains(defaultBus)) {
              defaultBus = busCodes.first;
            }

            setState(() {
              _allRoutes = routes;
              _selectedBusCode = defaultBus;
              if (!dates.contains(_selectedDate) && dates.isNotEmpty) {
                _selectedDate = dates.first;
              }
              _isLoading = false;
            });

            // Jeśli jest więcej niż 1 bus, pokaż okno wyboru busa i kierowcy
            if (mounted) {
              if (busCodes.length > 1) {
                await _showBusSelectionDialog(busCodes, routes, file.name);
              } else {
                await _restoreStateForRoute(_currentRoute);
                if (mounted) {
                  _showNotice(
                    'Wczytano ${file.name}: ${routes.length} tras (${routes.first.driverName})!',
                    Icons.check_circle,
                  );
                }
              }
            }
          } else if (mounted) {
            setState(() => _isLoading = false);
            _showNotice('Nie znaleziono pasujących tras w pliku.', Icons.warning);
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showNotice('Błąd importu pliku: $e', Icons.error);
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _showBusSelectionDialog(List<String> busCodes, List<BusRoute> routes, String fileName) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dialogHeight = MediaQuery.sizeOf(dialogCtx).height * 0.80;
          return Dialog(
            backgroundColor: const Color(0xFF1E1E1E),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(
                color: Color(0xFF383838),
                width: 1.0,
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                minHeight: dialogHeight,
                maxHeight: dialogHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.directions_bus_filled, color: Color(0xFFFFE7D0), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WYBIERZ SWÓJ POJAZD',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Wybierz busa i kierowcę, aby załadować trasę:',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFF333333)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: busCodes.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final code = busCodes[index];
                          final busRoute = routes.firstWhere((r) => r.code == code);
                          final isSelected = _selectedBusCode == code;
                          final driver = busRoute.driverName.isNotEmpty ? busRoute.driverName : 'Brak danych';
                          final vehicle = '${busRoute.vehicleModel} ${busRoute.registrationNumber}'.trim();
                          final stopsCount = routes.where((r) => r.code == code).fold(0, (s, r) => s + r.stops.length);

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setDialogState(() {
                                _selectedBusCode = code;
                              });
                              setState(() {
                                _selectedBusCode = code;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2C2A28)
                                    : const Color(0xFF232323),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFFE7D0).withValues(alpha: 0.65)
                                      : const Color(0xFF333333),
                                  width: isSelected ? 1.3 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF48423C) : const Color(0xFF323232),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      code,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFFE7D0),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          driver,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          vehicle.isNotEmpty ? vehicle : 'Pasażerów: $stopsCount',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isSelected ? const Color(0xFFFFE7D0) : Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Color(0xFFFFE7D0), size: 20)
                                  else
                                    Text(
                                      '$stopsCount os.',
                                      style: const TextStyle(fontSize: 11.5, color: Colors.white38),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF36322E),
                          foregroundColor: const Color(0xFFFFE7D0),
                          side: const BorderSide(
                            color: Color(0xFF554D44),
                            width: 1.0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(dialogCtx);
                          await _restoreStateForRoute(_currentRoute);
                          if (mounted) {
                            final busRoute = routes.firstWhere((r) => r.code == _selectedBusCode);
                            _showNotice(
                              'Załadowano trasę dla $_selectedBusCode (${busRoute.driverName})!',
                              Icons.check_circle,
                            );
                          }
                        },
                        child: Text(
                          'Załaduj trasę ($_selectedBusCode)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                            color: Color(0xFFFFE7D0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFF383838), width: 1.0),
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
                  backgroundColor: Color(0xFF36322E),
                  child: Icon(Icons.file_upload, color: Color(0xFFFFE7D0), size: 20),
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
      _currentTabIndex = 0;
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
                      // Górna sekcja: Logo BalticBus (podniesione o ~2 cm wyżej)
                      Padding(
                        padding: EdgeInsets.only(
                          top: ((constraints.maxHeight - 32) * 0.09).clamp(24.0, 100.0),
                        ),
                        child: GestureDetector(
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
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 380),
                          height: 140,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Image.asset(
                            'assets/images/balticbus_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 120,
                              height: 120,
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
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ),
                      // Dolna sekcja: Pastylka "Rozpocznij przejazd" prowadząca do arkusza importu/zarządzania rozkładem
                      Padding(
                        padding: const EdgeInsets.only(top: 28, bottom: 20),
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF36322E),
                            foregroundColor: const Color(0xFFFFE7D0),
                            side: const BorderSide(
                              color: Color(0xFF554D44),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _showImportOptions,
                          child: const Text(
                            'Rozpocznij przejazd',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Color(0xFFFFE7D0),
                            ),
                          ),
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

  void _handleBreakPillTap(BusRoute route) {
    var active = route.activeBreak;
    if (active == null) {
      final b = DriverBreak(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
      );
      setState(() {
        route.breaks.add(b);
      });
      StorageService.saveBreaks(route.id, route.breaks);
      _showNotice(
        'Rozpoczęto przerwę o ${_formatTime(b.startTime)}',
        Icons.coffee,
      );
      active = b;
    }
    _showDriverBreakDialog(active);
  }

  Future<void> _showDriverBreakDialog(DriverBreak activeBreak) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => DriverBreakDialog(
        activeBreak: activeBreak,
        busCode: _selectedBusCode,
        onEndBreak: () {
          setState(() {
            activeBreak.endTime = DateTime.now();
          });
          StorageService.saveBreaks(_currentRoute.id, _currentRoute.breaks);
          _showNotice(
            'Zakończono przerwę (${activeBreak.durationMinutes} min, ${_formatTime(activeBreak.startTime)} - ${_formatTime(activeBreak.endTime!)})',
            Icons.check_circle,
          );
        },
      ),
    );
    if (mounted) setState(() {});
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${route.code} • ${route.vehicleModel}',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                '${route.driverName}${route.registrationNumber.isNotEmpty ? ' • ${route.registrationNumber}' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.2,
                  shadows: const [
                    Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
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
          ],
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: activeTheme.border),
                    const SizedBox(height: 16),
                    const Text(
                      'Wczytywanie trasy...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            : IndexedStack(
                index: _currentTabIndex,
                children: [
                  _buildRouteTab(route, isPLtoDE),
                  _buildVehicleAndFuelTab(route, isPLtoDE),
                  _buildReportsAndWorkTimeTab(route, isPLtoDE),
                ],
              ),
        bottomNavigationBar: _buildBottomNavigationBar(route),
      ),
    );
  },
);
}

  Widget _buildBottomNavigationBar(BusRoute route) {
    final isDark = _isDark;
    final theme = AppColors.activeTheme;
    final selectedColor = theme.style == AppThemeStyle.balticNoir
        ? const Color(0xFFFFE7D0)
        : (theme.style == AppThemeStyle.balticOrange
            ? AppColors.brandingOrange
            : theme.secondaryAccent);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C1014).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: theme.border.withValues(alpha: 0.40),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) => setState(() => _currentTabIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: selectedColor,
          unselectedItemColor: Colors.white60,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.alt_route_outlined),
              activeIcon: Icon(Icons.alt_route),
              label: 'Trasa',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.local_gas_station_outlined),
              activeIcon: Icon(Icons.local_gas_station),
              label: 'Tankowanie',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: route.activeBreak != null,
                backgroundColor: const Color(0xFFC84031),
                label: const Text('PAUZA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                child: const Icon(Icons.assignment_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: route.activeBreak != null,
                backgroundColor: const Color(0xFFC84031),
                label: const Text('PAUZA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                child: const Icon(Icons.assignment),
              ),
              label: 'Raporty & Czas',
            ),
          ],
        ),
      ),
    );
  }

  // TAB 0: TRASA & PASAŻEROWIE
  Widget _buildRouteTab(BusRoute route, bool isPLtoDE) {
    // 1. Sprawdzamy, czy trwa jeszcze etap zbiórki pasażerów
    final pendingPickups = route.stops
        .where((s) => s.status == PickupStatus.pending)
        .toList();

    // Wszyscy pasażerowie są zebrani, gdy nie ma już żadnego ze statusem "Oczekuje" (są odebrani, odwołani lub noShow)
    final bool allPickedUp = pendingPickups.isEmpty;

    // Bieżący cel podróży (pasażer wieziony jako pierwszy):
    // Pojawia się jako duży Hero Box DOPIERO gdy wszyscy pasażerowie zostaną odebrani!
    PassengerStop? currentTarget;
    if (allPickedUp) {
      try {
        currentTarget = route.stops.firstWhere(
          (s) =>
              s.status != PickupStatus.delivered &&
              s.status != PickupStatus.cancelled &&
              s.status != PickupStatus.noShow,
        );
      } catch (_) {
        currentTarget = null;
      }
    }

    // Pozostali oczekujący pasażerowie (bez tego, który jest na karcie głównego celu)
    final otherPendingStops = route.stops.where((s) {
      if (s == currentTarget) return false;
      return s.status != PickupStatus.delivered &&
          s.status != PickupStatus.cancelled &&
          s.status != PickupStatus.noShow;
    }).toList();

    // Pasażerowie już obsłużeni (dowiezieni / anulowani / noShow)
    final completedStops = route.stops.where((s) {
      if (s == currentTarget) return false;
      return s.status == PickupStatus.delivered ||
          s.status == PickupStatus.cancelled ||
          s.status == PickupStatus.noShow;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        // Przełącznik Dnia (Sobota / Niedziela) + Pastylka Pauzy Kierowcy
        _buildDaySelector(route),
        const SizedBox(height: 12),

        // Specjalne uwagi i polecenia logistyczne
        if (route.specialNotes.isNotEmpty) ...[
          _buildSpecialNotesCard(route.specialNotes),
          const SizedBox(height: 12),
        ],

        // Punkty przesiadkowe (pod poleceniami logistycznymi)
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

        // Wyróżniona karta Bieżącego Celu Podróży (Kto pierwszy do domu / hotelu) lub Status Zbiórki
        _buildNextStopHeroCard(
          route,
          isPLtoDE,
          currentTarget,
          allPickedUp: allPickedUp,
          pendingCount: pendingPickups.length,
          totalCount: route.stops.length,
        ),
        const SizedBox(height: 14),

        // Pozostali pasażerowie do obsłużenia
        if (otherPendingStops.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  !allPickedUp
                      ? (isPLtoDE
                          ? '📋 Pasażerowie do odebrania z hoteli (${otherPendingStops.length})'
                          : '📋 Pasażerowie do odebrania z domów (${otherPendingStops.length})')
                      : (isPLtoDE
                          ? '👥 Pozostali do dowiezienia (${otherPendingStops.length})'
                          : '👥 Pozostali do obsłużenia (${otherPendingStops.length})'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...otherPendingStops.map((stop) => _buildPassengerCard(stop, isPLtoDE)),
          const SizedBox(height: 14),
        ],

        // Sekcja obsłużonych pasażerów (zwijana, aby nie robić bałaganu na ekranie)
        if (completedStops.isNotEmpty) ...[
          InkWell(
            onTap: () => setState(() => _showCompletedPassengers = !_showCompletedPassengers),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1.1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF52B788), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isPLtoDE
                          ? 'Dowiezieni do domów (${completedStops.length})'
                          : 'Obsłużeni pasażerowie (${completedStops.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Icon(
                    _showCompletedPassengers ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_showCompletedPassengers) ...[
            const SizedBox(height: 6),
            ...completedStops.map((stop) => _buildPassengerCard(stop, isPLtoDE)),
          ],
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNextStopHeroCard(
    BusRoute route,
    bool isPLtoDE,
    PassengerStop? currentTarget, {
    required bool allPickedUp,
    required int pendingCount,
    required int totalCount,
  }) {
    // Jeśli trwa jeszcze etap zbiórki pasażerów z hoteli/domów
    if (!allPickedUp) {
      final pickedCount = totalCount - pendingCount;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _convexDecoration(
          borderRadius: BorderRadius.circular(16),
          baseTopColor: _isDark
              ? AppColors.activeTheme.boxStart.withValues(alpha: 0.9)
              : Colors.orange.shade50,
          baseBottomColor: _isDark
              ? AppColors.activeTheme.boxEnd.withValues(alpha: 0.9)
              : Colors.white,
          borderColor: AppColors.brandingOrange.withValues(alpha: 0.6),
          borderWidth: 1.2,
          isHighlighted: true,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.brandingOrange.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: AppColors.brandingOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPLtoDE
                        ? 'ETAP ZBIÓRKI Z HOTELI'
                        : 'ETAP ZBIÓRKI Z DOMÓW (NIEMCY)',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.brandingOrange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Odebrano: $pickedCount z $totalCount pasażerów',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Po odebraniu wszystkich pojawi się cel podróży do dowiezienia.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (currentTarget == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B4332).withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D6A4F), width: 1.4),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF52B788), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPLtoDE
                        ? 'Wszyscy pasażerowie dowiezieni do domów!'
                        : 'Wszyscy pasażerowie dowiezieni do hoteli!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Kurs na tym kierunku został pomyślnie zrealizowany.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isSundayHomePickup = !isPLtoDE && currentTarget.status == PickupStatus.pending;

    return Container(
      decoration: _convexDecoration(
        borderRadius: BorderRadius.circular(16),
        borderColor: _isDark
            ? AppColors.activeTheme.secondaryAccent.withValues(alpha: 0.70)
            : AppColors.brandingOrange.withValues(alpha: 0.85),
        borderWidth: 1.3,
        isHighlighted: true,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imię i nazwisko pasażera + ikony zadzwoń, nawiguj + pastylka dowieziono/odebrano
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        currentTarget.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (currentTarget.passengerCount > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '👥 ${currentTarget.passengerCount}',
                          style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (currentTarget.phone.isNotEmpty) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  icon: const Icon(Icons.phone, size: 20, color: Colors.greenAccent),
                  tooltip: 'Zadzwoń (${currentTarget.phone})',
                  onPressed: () => LauncherService.openPhone(
                    context,
                    currentTarget.phone,
                    currentTarget.name,
                  ),
                ),
                const SizedBox(width: 2),
              ],
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.navigation, size: 20, color: AppColors.brandingOrange),
                tooltip: 'Nawiguj do celu',
                onPressed: () => LauncherService.openNavigation(
                  context,
                  currentTarget.address,
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 32),
                ),
                onPressed: () {
                  _updatePassengerStatus(
                    currentTarget,
                    isPLtoDE
                        ? PickupStatus.delivered
                        : (isSundayHomePickup ? PickupStatus.pickedUp : PickupStatus.delivered),
                  );
                },
                child: Text(
                  isPLtoDE
                      ? 'Dowieziono'
                      : (isSundayHomePickup ? 'Odebrano' : 'Dowieziono'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Szczegóły trasy i godzin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12, width: 1.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPLtoDE) ...[
                  // 1. Odbiór z hotelu + Nazwa hotelu + Godzina odbioru
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hotel_rounded, size: 20, color: Colors.amber),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ODBIÓR Z HOTELU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.gray,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              currentTarget.resort.isNotEmpty ? currentTarget.resort : 'Hotel w Polsce',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF2C2A28) : Colors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isDark
                                ? const Color(0xFFFFE7D0).withValues(alpha: 0.40)
                                : Colors.amber.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_filled,
                              size: 13,
                              color: _isDark ? const Color(0xFFFFE7D0) : Colors.amber,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              currentTarget.hotelTime ?? '--:--',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _isDark ? const Color(0xFFFFE7D0) : Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.white12),
                  ),

                  // 2. Adres domowy (Niemcy)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.brandingOrange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.home_rounded, size: 20, color: AppColors.brandingOrange),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ADRES DOMOWY (NIEMCY)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.gray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentTarget.displayAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.white12),
                  ),

                  // 3. Planowany dojazd do domu godzina
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flag_rounded, size: 20, color: Color(0xFF52B788)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PLANOWANY DOJAZD DO DOMU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 14, color: Color(0xFF52B788)),
                            const SizedBox(width: 5),
                            Text(
                              currentTarget.homeTimeDisplay,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF52B788),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Niedziela: Odbiór z adresu domowego ➔ Dojazd do hotelu
                  // 1. Adres domowy + Godzina odbioru z domu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.brandingOrange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.home_rounded, size: 20, color: AppColors.brandingOrange),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ODBIÓR Z ADRESU DOMOWEGO (NIEMCY)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.gray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentTarget.displayAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF2C2A28) : AppColors.brandingOrange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isDark
                                ? const Color(0xFFFFE7D0).withValues(alpha: 0.40)
                                : AppColors.brandingOrange.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_filled,
                              size: 13,
                              color: _isDark ? const Color(0xFFFFE7D0) : AppColors.brandingOrange,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              currentTarget.homeTimeDisplay,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _isDark ? const Color(0xFFFFE7D0) : AppColors.brandingOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.white12),
                  ),

                  // 2. Hotel docelowy w Polsce + Planowany dojazd do hotelu
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hotel_rounded, size: 20, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HOTEL DOCELOWY W POLSCE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.gray,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              currentTarget.resort.isNotEmpty ? currentTarget.resort : 'Hotel w Polsce',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 14, color: Colors.lightBlueAccent),
                            const SizedBox(width: 5),
                            Text(
                              currentTarget.hotelTime ?? '--:--',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (currentTarget.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFC10801).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFC10801).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 13, color: Color(0xFFFF8A80)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Uwagi: ${currentTarget.comment}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFFF8A80), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // TAB 1: TANKOWANIE
  Widget _buildVehicleAndFuelTab(BusRoute route, bool isPLtoDE) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        // Liczniki kilometrów (START / STOP / PRZEBIEG)
        _buildOdometerCard(route),
        const SizedBox(height: 14),

        // Moduł tankowań i paliwa
        _buildRefuelingsModule(route),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRefuelingsModule(BusRoute route) {
    return Container(
      decoration: _convexDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_gas_station,
                      color: _isDark ? AppColors.activeTheme.secondaryAccent : AppColors.brandingOrange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Paliwo i Tankowania',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _isDark ? AppColors.activeTheme.primaryAccent : AppColors.brandingOrange,
                  foregroundColor: _isDark ? AppColors.activeTheme.secondaryAccent : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Dodaj tankowanie', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                onPressed: _showAddRefuelingDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Kafelki podsumowania zużycia
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Diesel (ON)', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    const SizedBox(height: 2),
                    Text(
                      '${route.totalDieselLiters.toStringAsFixed(1)} L',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.brandingOrange),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: Colors.white12),
                Column(
                  children: [
                    const Text('AdBlue', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    const SizedBox(height: 2),
                    Text(
                      '${route.totalAdBlueLiters.toStringAsFixed(1)} L',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: Colors.white12),
                Column(
                  children: [
                    const Text('Śr. spalanie ON', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    const SizedBox(height: 2),
                    Text(
                      route.averageConsumptionLPer100Km != null
                          ? '${route.averageConsumptionLPer100Km!.toStringAsFixed(2)} l'
                          : '—',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (route.refuelings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Brak zarejestrowanych tankowań na tej trasie.',
                  style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            )
          else ...[
            const Text(
              'Historia tankowań:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 6),
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
                          color: isAdBlue
                              ? (_isDark ? const Color(0xFF1B3A4B) : Colors.blue.shade50)
                              : (_isDark ? const Color(0xFF2C2A28) : AppColors.brandingOrange.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isAdBlue
                                ? (_isDark ? const Color(0xFF3A6073) : Colors.blue.shade200)
                                : (_isDark ? const Color(0xFF554D44) : AppColors.brandingOrange.withValues(alpha: 0.3)),
                          ),
                        ),
                        child: Text(
                          ref.fuelType,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isAdBlue
                                ? (_isDark ? const Color(0xFF90CAF9) : Colors.blue.shade900)
                                : (_isDark ? const Color(0xFFFFE7D0) : AppColors.brandingOrange),
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
                      setState(() {
                        route.refuelings.removeWhere((r) => r.id == ref.id);
                      });
                      StorageService.saveRefuelings(route.id, route.refuelings);
                    },
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // TAB 2: RAPORTY & CZAS
  Widget _buildReportsAndWorkTimeTab(BusRoute route, bool isPLtoDE) {
    final summary = _getWeekendTripSummaryForCurrentBus();
    final isBreakActive = route.activeBreak != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        // 1. Moduł Przerw i Czasu Pracy Kierowcy
        Container(
          decoration: _convexDecoration(
            borderRadius: BorderRadius.circular(16),
            isHighlighted: isBreakActive,
            borderColor: isBreakActive ? const Color(0xFFC84031) : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isBreakActive ? Icons.timer : Icons.coffee,
                        color: isBreakActive ? const Color(0xFFE57373) : AppColors.brandingOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Czas Pracy & Pauzy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF36322E),
                      foregroundColor: const Color(0xFFFFE7D0),
                      side: const BorderSide(color: Color(0xFF554D44), width: 1.0),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(isBreakActive ? Icons.stop : Icons.play_arrow, size: 16),
                    label: Text(
                      isBreakActive ? 'Koniec pauzy' : 'Rozpocznij pauzę',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _toggleDriverBreak,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isBreakActive) ...[
                InkWell(
                  onTap: () => _showDriverBreakDialog(route.activeBreak!),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2A28),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF554D44)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.coffee, color: Color(0xFFFFE7D0), size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '☕ TRWA PRZERWA KIEROWCY',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFE7D0),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rozpoczęto o ${_formatTime(route.activeBreak!.startTime)} • Dotknij, aby otworzyć licznik',
                                style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.open_in_new, color: Color(0xFFFFE7D0), size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                'Zarejestrowane przerwy (${route.breaks.length} • łącznie: ${route.totalBreakMinutes} min):',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              if (route.breaks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Brak zarejestrowanych przerw w tym kursie.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                )
              else
                ...route.breaks.map((b) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: AppColors.brandingOrange),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatTime(b.startTime)} - ${b.endTime != null ? _formatTime(b.endTime!) : "w toku"} (${b.durationMinutes} min)',
                          style: const TextStyle(fontSize: 12.5, color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Moduł Finansów i Rozliczenia
        Container(
          decoration: _convexDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payments_outlined, color: AppColors.brandingOrange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Zaliczka i Finanse',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: _isDark ? const Color(0xFF554D44) : AppColors.brandingOrange,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(
                      Icons.edit,
                      size: 14,
                      color: _isDark ? const Color(0xFFFFE7D0) : AppColors.brandingOrange,
                    ),
                    label: const Text('Edytuj', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () => _showEditFinancialsDialog(() => setState(() {})),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ZALICZKA:', style: TextStyle(fontSize: 11, color: Colors.white60)),
                        const SizedBox(height: 3),
                        Text(
                          '${summary.advanceEur.toStringAsFixed(2)} €',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        Text(
                          '${summary.advancePln.toStringAsFixed(2)} zł',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    Container(height: 36, width: 1, color: Colors.white12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ODEBRANE:', style: TextStyle(fontSize: 11, color: Colors.white60)),
                        const SizedBox(height: 3),
                        Text(
                          '${summary.cashCollectedEur.toStringAsFixed(2)} €',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.greenAccent),
                        ),
                        Text(
                          '${summary.cashCollectedPln.toStringAsFixed(2)} zł',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Centrum Raportowania i Zakończenia Kursu
        Container(
          decoration: _convexDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment,
                      color: _isDark ? AppColors.activeTheme.secondaryAccent : AppColors.brandingOrange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Centrum Raportowania',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Przycisk Plan Jazdy
              _buildReportActionRow(
                icon: Icons.assignment_outlined,
                accentColor: _isDark ? AppColors.activeTheme.secondaryAccent : AppColors.brandingOrange,
                title: 'Otwórz pełny Plan Jazdy',
                subtitle: 'Kompletne podsumowanie weekendu, tabelka km i rozliczenie',
                onTap: _showPlanJazdyDialog,
              ),
              const SizedBox(height: 8),
              // Zapisz Word
              _buildReportActionRow(
                icon: Icons.description_outlined,
                accentColor: Colors.blueAccent,
                title: 'Zapisz raport Word (.docx)',
                subtitle: 'Generuje oficjalny plik rozliczenia zgodny ze wzorcem',
                onTap: () => DocxReportService.savePlanJazdyDocxToDesktop(context, summary),
              ),
              const SizedBox(height: 8),
              // Wyślij WhatsApp
              _buildReportActionRow(
                icon: Icons.chat_outlined,
                accentColor: const Color(0xFF25D366),
                title: 'Wyślij raport na WhatsApp',
                subtitle: 'Prześlij tekstowe podsumowanie kursu na czat firmowy',
                onTap: () {
                  final text = ReportService.generatePlanJazdyText(summary);
                  ReportService.sendViaWhatsApp(context, text);
                },
              ),
              const Divider(height: 24, color: Colors.white12),
              // Zakończ kurs
              _buildReportActionRow(
                icon: Icons.flag_outlined,
                accentColor: const Color(0xFFC10801),
                title: 'Zakończ kurs i wyczyść dane',
                subtitle: 'Trwale wyczyść dane bieżącego wyjazdu i przygotuj aplikację na nowy rozkład',
                onTap: _confirmFinishTrip,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReportActionRow({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accentColor.withValues(alpha: 0.18),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white54),
            ],
          ),
        ),
      ),
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

  Widget _buildDaySelector(BusRoute route) {
    final dates = _availableDates;
    final isBreakActive = route.activeBreak != null;

    if (dates.length < 2) {
      return Row(
        children: [
          const Spacer(),
          _buildBreakPill(route, isBreakActive),
        ],
      );
    }

    return Row(
      children: [
        // Pastylka Sobota
        Expanded(
          flex: 4,
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
        const SizedBox(width: 6),

        // Pastylka Niedziela
        Expanded(
          flex: 4,
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
        const SizedBox(width: 6),

        // Pastylka Pauzy Kierowcy
        _buildBreakPill(route, isBreakActive),
      ],
    );
  }

  Widget _buildBreakPill(BusRoute route, bool isBreakActive) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleBreakPillTap(route),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isBreakActive ? const Color(0xFF2C2A28) : const Color(0xFF232323),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBreakActive
                  ? const Color(0xFFFFE7D0).withValues(alpha: 0.85)
                  : const Color(0xFF383838),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBreakActive ? Icons.timer : Icons.coffee,
                size: 16,
                color: isBreakActive ? const Color(0xFFFFE7D0) : const Color(0xFFB0B0B0),
              ),
              const SizedBox(width: 6),
              Text(
                isBreakActive ? 'Pauza w toku' : 'Pauza',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isBreakActive ? const Color(0xFFFFE7D0) : const Color(0xFFD0D0D0),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0D0D0D),
                      Color(0xFF141414),
                      Color(0xFF1C1C1C),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2C2A28),
                      Color(0xFF232220),
                      Color(0xFF1E1D1B),
                    ],
                    stops: [0.0, 0.50, 1.0],
                  ),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2B2B2B)
                  : const Color(0xFF3E3B37),
              width: 1.1,
            ),
            boxShadow: isSelected
                ? [
                    // Efekt wklęsłości / wciśnięcia: głęboki cień u góry wewnątrz
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.75),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    // Efekt wypukłości (przycisk niewciśnięty rzuca cień zewnętrzny)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05),
                      blurRadius: 1,
                      offset: const Offset(0, -1),
                    ),
                  ],
          ),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.only(top: isSelected ? 2.0 : 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? const Color(0xFFFFE7D0) : Colors.white60,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFFFFE7D0)
                          : Colors.white70,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
    final isDone = point.isCompleted;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isDone ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: _convexDecoration(
          borderRadius: BorderRadius.circular(12),
          baseTopColor: isDone
              ? (_isDark ? const Color(0xFF141414) : Colors.grey.shade200)
              : null,
          baseBottomColor: isDone
              ? (_isDark ? const Color(0xFF0F0F0F) : Colors.grey.shade100)
              : null,
          borderColor: isDone
              ? (_isDark ? Colors.white.withValues(alpha: 0.10) : Colors.grey.shade400)
              : AppColors.activeTheme.border,
          borderWidth: isDone ? 1.0 : 1.5,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: CheckboxListTile(
            activeColor: isDone ? AppColors.gray : AppColors.brandingOrange,
            checkColor: Colors.white,
            value: isDone,
            onChanged: (_) => _toggleTransferPoint(point),
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              '${point.time} • ${point.location}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDone ? AppColors.gray : _textPrimary,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              point.instruction,
              style: TextStyle(
                fontSize: 12,
                color: isDone
                    ? AppColors.gray.withValues(alpha: 0.75)
                    : _textSecondary,
              ),
            ),
            secondary: IconButton(
              icon: Icon(
                Icons.near_me,
                color: isDone ? AppColors.gray : AppColors.brandingOrange,
                size: 20,
              ),
              tooltip: 'Nawiguj do punktu',
              onPressed: () => LauncherService.openNavigation(context, point.location),
            ),
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
        statusColor = _isDark ? AppColors.activeTheme.secondaryAccent : AppColors.brandingOrange;
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
              : (_isDark ? AppColors.activeTheme.border.withValues(alpha: 0.55) : statusColor.withValues(alpha: 0.70)),
          borderWidth: 1.0,
          isHighlighted: false,
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
                        if (stop.hotelTime != null || stop.homeTime != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: _isDark
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Godzina 1: Odbiór
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPLtoDE ? Icons.hotel_rounded : Icons.home_rounded,
                                      size: 14,
                                      color: isDelivered ? AppColors.gray : AppColors.brandingOrange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isPLtoDE ? 'HOTEL ' : 'DOM ',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: isDelivered ? AppColors.gray : AppColors.gray,
                                      ),
                                    ),
                                    Text(
                                      (isPLtoDE ? stop.hotelTime : stop.homeTimeDisplay) ?? '--:--',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: isDelivered
                                            ? (_isDark ? Colors.white54 : Colors.grey.shade600)
                                            : _textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: AppColors.gray,
                                  ),
                                ),
                                // Godzina 2: Dojazd
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPLtoDE ? Icons.home_rounded : Icons.hotel_rounded,
                                      size: 14,
                                      color: isDelivered ? AppColors.gray : const Color(0xFF27AE60),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isPLtoDE ? 'DOM ' : 'HOTEL ',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                    Text(
                                      (isPLtoDE ? stop.homeTimeDisplay : stop.hotelTime) ?? '--:--',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: isDelivered
                                            ? (_isDark ? Colors.white54 : Colors.grey.shade600)
                                            : (isPLtoDE ? const Color(0xFF27AE60) : _textPrimary),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
              : (_isDark ? AppColors.activeTheme.border.withValues(alpha: 0.65) : statusColor.withValues(alpha: 0.75)),
          borderWidth: isDelivered ? 1.0 : 1.2,
          isHighlighted: false,
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
                          : (_isDark ? AppColors.activeTheme.primaryAccent : AppColors.primary),
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
                      stop.isTransfer ? Icons.sync_alt_rounded : Icons.location_on,
                      size: 16,
                      color: isDelivered
                          ? (_isDark ? Colors.white38 : Colors.grey)
                          : (stop.isTransfer ? const Color(0xFFE67E22) : AppColors.brandingOrange),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stop.displayAddress,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: stop.isTransfer ? FontWeight.w600 : FontWeight.normal,
                          color: isDelivered
                              ? (_isDark ? Colors.white54 : Colors.black45)
                              : (stop.isTransfer ? const Color(0xFFFFE7D0) : _textSecondary),
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

                // Harmonogram godzin (odjazd i dojazd)
                if (stop.hotelTime != null || stop.homeTime != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _borderColor.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                isPLtoDE ? Icons.hotel_rounded : Icons.home_rounded,
                                size: 15,
                                color: AppColors.brandingOrange,
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPLtoDE ? 'ODJAZD Z HOTELU' : 'ODBIÓR Z DOMU',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray,
                                    ),
                                  ),
                                  Text(
                                    (isPLtoDE ? stop.hotelTime : stop.homeTimeDisplay) ?? '--:--',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: _textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.gray.withValues(alpha: 0.6),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isPLtoDE ? 'DOJAZD DO DOMU' : 'DOJAZD DO HOTELU',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray,
                                    ),
                                  ),
                                  Text(
                                    (isPLtoDE ? stop.homeTimeDisplay : stop.hotelTime) ?? '--:--',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: isPLtoDE ? const Color(0xFF27AE60) : _textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isPLtoDE ? Icons.home_rounded : Icons.hotel_rounded,
                                size: 15,
                                color: const Color(0xFF27AE60),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                        onPressed: (stop.address.isNotEmpty && !stop.isTransfer)
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
                  side: BorderSide(
                    color: _isDark ? const Color(0xFF554D44) : AppColors.brandingOrange,
                  ),
                ),
                icon: Icon(
                  Icons.description,
                  size: 16,
                  color: _isDark ? const Color(0xFFFFE7D0) : AppColors.brandingOrange,
                ),
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

/// Okno dialogowe pauzy kierowcy w stylistyce Baltic Noir (odliczanie czasu na żywo)
class DriverBreakDialog extends StatefulWidget {
  final DriverBreak activeBreak;
  final String busCode;
  final VoidCallback onEndBreak;

  const DriverBreakDialog({
    super.key,
    required this.activeBreak,
    required this.busCode,
    required this.onEndBreak,
  });

  @override
  State<DriverBreakDialog> createState() => _DriverBreakDialogState();
}

class _DriverBreakDialogState extends State<DriverBreakDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatHms(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.activeBreak.startTime);
    final timeStr = _formatHms(elapsed);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFF383838),
          width: 1.0,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek w stylistyce okna wyboru pojazdu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.coffee,
                      color: Color(0xFFFFE7D0),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRZERWA KIEROWCY',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Odliczanie czasu trwania pauzy',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFB0B0B0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Ukryj (wróć do trasy)',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFF333333)),
              const SizedBox(height: 16),

              // Główna karta z zegarem cyfrowym i statusem
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF383838), width: 1.0),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE7D0),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'CZAS TRWANIA PAUZY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Color(0xFFB0B0B0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFE7D0),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pauza aktywna • Czas nalicza się automatycznie',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Belka informacyjna: godzina startu i pojazd
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.play_circle_outline, size: 16, color: Color(0xFFB0B0B0)),
                        const SizedBox(width: 6),
                        Text(
                          'Rozpoczęto: ${widget.activeBreak.startTime.hour.toString().padLeft(2, '0')}:${widget.activeBreak.startTime.minute.toString().padLeft(2, '0')}:${widget.activeBreak.startTime.second.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                        ),
                      ],
                    ),
                    Text(
                      'Bus: ${widget.busCode}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFE7D0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Przyciski akcji
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB0B0B0),
                        side: const BorderSide(color: Color(0xFF383838), width: 1.0),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Wróć do trasy', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF36322E),
                        foregroundColor: const Color(0xFFFFE7D0),
                        side: const BorderSide(
                          color: Color(0xFF554D44),
                          width: 1.0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.stop_circle_outlined, size: 19),
                      label: const Text(
                        'Zakończ przerwę',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      onPressed: () {
                        widget.onEndBreak();
                        Navigator.pop(context);
                      },
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
}




