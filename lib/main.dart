import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/sample_routes.dart';
import 'models/route_models.dart';
import 'services/docx_report_service.dart';
import 'services/excel_parser_service.dart';
import 'services/hotel_directory_service.dart';
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

  await HotelDirectoryService.loadAll();

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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Probably the best door-to-door transport in Europe.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.normal,
                              letterSpacing: 1.2,
                              height: 1.3,
                              color: Color(0xFFCBB79F),
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 14,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
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
                      ],
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
  bool _isNightHudMode = false;
  int? _hudManualStopIndex;
  String? _selectedHotelCity;
  final TextEditingController _hotelSearchController = TextEditingController();
  String _hotelSearchQuery = '';
  bool _showCompletedPassengers = false;
  double _advanceEur = 0.0;
  double _advancePln = 0.0;
  double _cashCollectedPln = 0.0;
  double _cashCollectedEur = 0.0;
  List<GuestPaymentEntry> _guestPayments = [];
  Timer? _welcomeClockTimer;
  DateTime _welcomeCurrentTime = DateTime.now();
  OverlayEntry? _currentNoticeOverlay;
  DateTime? _driveStartTime;
  DateTime? _coffeeBreakSnoozeUntil;
  int _coffeeReminderMinutes = 150; // 2.5 godziny domyślnie
  Timer? _driveTimeTicker;

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
    final hasActive = widget.initialHasActiveTrip ?? false;
    _allRoutes = hasActive ? sampleBusRoutes : [];
    _checkInitialTripState();
    _driveTimeTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _welcomeClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _allRoutes.isEmpty) {
        setState(() {
          _welcomeCurrentTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _checkInitialTripState() async {
    final hasActive = widget.initialHasActiveTrip ?? await StorageService.hasActiveTrip();
    if (!hasActive) {
      if (mounted && _allRoutes.isNotEmpty) {
        setState(() {
          _allRoutes = [];
        });
      }
      return;
    }

    // Kurs jest oznaczony jako aktywny -> odtwórz zapisane źródło trasy
    final source = await StorageService.loadActiveTripSource();
    List<BusRoute> parsed = [];
    if (source.excelBytes != null && source.excelBytes!.isNotEmpty) {
      parsed = ExcelParserService.parseExcelBytes(Uint8List.fromList(source.excelBytes!));
    }

    if (parsed.isNotEmpty && mounted) {
      final busCodes = parsed.map((r) => r.code).toSet().toList();
      if (source.busCode != null && busCodes.contains(source.busCode)) {
        _selectedBusCode = source.busCode!;
      }
      await HotelDirectoryService.ingestHotelsFromRoutes(parsed);
      setState(() {
        _allRoutes = parsed;
      });
      await _restoreStateForRoute(_currentRoute);
    } else if (mounted) {
      if (_allRoutes.isEmpty) {
        await StorageService.setHasActiveTrip(false);
      } else {
        await _restoreStateForRoute(_currentRoute);
      }
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
    _guestPayments = await StorageService.loadGuestPayments(route.code);
    if (_guestPayments.isNotEmpty) {
      _cashCollectedPln = _guestPayments.where((p) => p.currency == 'PLN').fold(0.0, (sum, p) => sum + p.amount);
      _cashCollectedEur = _guestPayments.where((p) => p.currency == 'EUR').fold(0.0, (sum, p) => sum + p.amount);
    }
    final savedDriveStart = await StorageService.loadDriveStartTime(route.id);
    if (savedDriveStart != null) {
      _driveStartTime = savedDriveStart;
    } else {
      final firstPickup = route.stops
          .where((s) => s.pickedUpAt != null)
          .map((s) => s.pickedUpAt!)
          .fold<DateTime?>(null, (min, dt) => min == null || dt.isBefore(min) ? dt : min);
      _driveStartTime = firstPickup ?? DateTime.now();
      await StorageService.saveDriveStartTime(route.id, _driveStartTime!);
    }
    _coffeeReminderMinutes = await StorageService.loadCoffeeReminderMinutes();
    if (mounted) setState(() {});
  }

  Future<void> _pickExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
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

            await StorageService.saveActiveTripSource(
              excelBytes: bytes,
              busCode: defaultBus,
            );

            setState(() {
              _allRoutes = routes;
              _selectedBusCode = defaultBus;
              if (!dates.contains(_selectedDate) && dates.isNotEmpty) {
                _selectedDate = dates.first;
              }
              _isLoading = false;
            });

            // Automatyczne wykrycie i dodanie nowych hoteli do stałej bazy
            final newHotelsCount = await HotelDirectoryService.ingestHotelsFromRoutes(routes);

            // Jeśli jest więcej niż 1 bus, pokaż okno wyboru busa i kierowcy
            if (mounted) {
              if (newHotelsCount > 0) {
                _showNotice(
                  'Wykryto i dodano $newHotelsCount nowych hoteli do katalogu!',
                  Icons.hotel_rounded,
                  _isDark ? AppColors.activeTheme.secondaryAccent : AppColors.brandingOrange,
                );
              }
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
                          await StorageService.saveActiveBusCode(_selectedBusCode);
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
              'Upewnij się, że zapisałeś raport Word (.docx) w telefonie!',
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
      _guestPayments = [];
      _driveStartTime = null;
      _coffeeBreakSnoozeUntil = null;
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
    final now = _welcomeCurrentTime;
    const weekdaysPl = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
      'Sobota',
      'Niedziela',
    ];
    final dayName = weekdaysPl[(now.weekday - 1).clamp(0, 6)];
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final dateStr =
        '$dayName, ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Zdjęcie mercedesa na trasie w tle
        Positioned.fill(
          child: Opacity(
            opacity: 0.34,
            child: Image.asset(
              'assets/images/mercedes_vito_road.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(-0.25, 0.0),
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ),
        // Gradient tła (przyciemnia krawędzie dla czytelności)
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
                  Colors.black.withValues(alpha: 0.45),
                ],
                stops: const [0.0, 0.25, 0.65, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Górna sekcja: Przeźroczysty Glass Box (u góry nad mercedesem)
                      ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.24),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.16),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Zegar, Data i status GPS / Offline
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  timeStr,
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.5,
                                                    height: 1.05,
                                                    color: Colors.white,
                                                    fontFeatures: [FontFeature.tabularFigures()],
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black54,
                                                        blurRadius: 8,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  dateStr,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white.withValues(alpha: 0.85),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 9,
                                                  vertical: 3.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.55),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.satellite_alt_rounded,
                                                      color: Color(0xFF38BDF8),
                                                      size: 11,
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      'GPS READY',
                                                      style: TextStyle(
                                                        color: Color(0xFF38BDF8),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 9,
                                                  vertical: 3.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF27AE60).withValues(alpha: 0.18),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: const Color(0xFF27AE60).withValues(alpha: 0.55),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.circle,
                                                      color: Color(0xFF2ECC71),
                                                      size: 7,
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      'OFFLINE READY',
                                                      style: TextStyle(
                                                        color: Color(0xFF2ECC71),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Divider(
                                        color: Colors.white.withValues(alpha: 0.14),
                                        height: 1,
                                      ),
                                      const SizedBox(height: 12),
                                      // 2 Kafle dotykowe (bardziej transparentne)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: _showImportOptions,
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.06),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.16),
                                                    width: 1.1,
                                                  ),
                                                ),
                                                child: const Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons.add_road_rounded,
                                                      color: Color(0xFF60A5FA),
                                                      size: 21,
                                                    ),
                                                    SizedBox(height: 5),
                                                    Text(
                                                      'Wczytaj trasę',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 1),
                                                    Text(
                                                      'Excel / Gotowe pliki',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: InkWell(
                                              onTap: _showHotelDirectoryDialog,
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.06),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.16),
                                                    width: 1.1,
                                                  ),
                                                ),
                                                child: const Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons.hotel_rounded,
                                                      color: Color(0xFF60A5FA),
                                                      size: 21,
                                                    ),
                                                    SizedBox(height: 5),
                                                    Text(
                                                      'Baza hoteli',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 1),
                                                    Text(
                                                      'Adresy i telefony',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ),

                      // Dolna sekcja: Logo BalticBus
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 10),
                        child: _buildWelcomeLogo(height: 82),
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

  /// Logo BalticBus na ekranie startowym
  Widget _buildWelcomeLogo({double height = 82}) {
    return Container(
      key: const ValueKey('balticbus_logo_detector'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      height: height,
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/balticbus_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brandingOrange.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.brandingOrange, width: 2),
          ),
          child: const Icon(Icons.directions_bus, color: Colors.white, size: 42),
        ),
      ),
    );
  }

  /// Podgląd i edycja bazy hoteli bezpośrednio z ekranu startowego
  void _showHotelDirectoryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final grouped = HotelDirectoryService.getHotelsGroupedByCitySync();
            final cities = grouped.keys.toList();
            final totalCount = grouped.values.fold<int>(0, (sum, list) => sum + list.length);

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.hotel_rounded, color: Color(0xFF60A5FA), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Katalog Hoteli ($totalCount obiektów)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Dodaj nowy hotel',
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.brandingOrange, size: 22),
                            onPressed: () {
                              _showEditHotelDialog(
                                onSaved: () {
                                  if (sheetCtx.mounted) setSheetState(() {});
                                },
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Zamknij',
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: cities.length,
                        itemBuilder: (context, index) {
                          final city = cities[index];
                          final hotels = grouped[city] ?? [];
                          return Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              key: PageStorageKey<String>('welcome_hotel_city_$city'),
                              iconColor: AppColors.brandingOrange,
                              collapsedIconColor: Colors.white60,
                              title: Text(
                                city,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              subtitle: Text(
                                '${hotels.length} obiektów',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              children: hotels.map((h) {
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.only(left: 16, right: 8),
                                  title: Text(
                                    h.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    h.address.isNotEmpty
                                        ? (h.note != null && h.note!.isNotEmpty ? '${h.address} • ${h.note}' : h.address)
                                        : 'Brak adresu (dodany z listy)',
                                    style: TextStyle(
                                      color: h.address.isNotEmpty ? Colors.white60 : Colors.amber.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (h.address.isNotEmpty)
                                        IconButton(
                                          tooltip: 'Nawiguj',
                                          icon: const Icon(Icons.navigation_rounded, color: AppColors.brandingOrange, size: 20),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            LauncherService.openNavigation(context, '${h.name}, ${h.address}');
                                          },
                                        ),
                                      PopupMenuButton<String>(
                                        tooltip: 'Opcje hotelu',
                                        icon: const Icon(Icons.more_vert, color: Colors.white60, size: 20),
                                        color: const Color(0xFF282828),
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _showEditHotelDialog(
                                              hotel: h,
                                              onSaved: () {
                                                if (sheetCtx.mounted) setSheetState(() {});
                                              },
                                            );
                                          } else if (val == 'delete') {
                                            _confirmDeleteHotel(
                                              h,
                                              onDeleted: () {
                                                if (sheetCtx.mounted) setSheetState(() {});
                                              },
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                                                SizedBox(width: 8),
                                                Text('Edytuj dane', style: TextStyle(color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                SizedBox(width: 8),
                                                Text('Usuń z bazy', style: TextStyle(color: Colors.redAccent)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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
        _coffeeBreakSnoozeUntil = null;
        _showNotice(
          'Rozpoczęto przerwę o ${_formatTime(b.startTime)}',
          Icons.coffee,
        );
      } else {
        active.endTime = DateTime.now();
        _driveStartTime = active.endTime;
        _coffeeBreakSnoozeUntil = null;
        StorageService.saveDriveStartTime(route.id, _driveStartTime!);
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
        _coffeeBreakSnoozeUntil = null;
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
            _driveStartTime = activeBreak.endTime;
            _coffeeBreakSnoozeUntil = null;
          });
          StorageService.saveBreaks(_currentRoute.id, _currentRoute.breaks);
          StorageService.saveDriveStartTime(_currentRoute.id, _driveStartTime!);
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
              child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _isDark ? const Color(0xFF5A391E) : const Color(0xFFE67300),
                foregroundColor: _isDark ? const Color(0xFFFFF1E3) : Colors.white,
                side: BorderSide(
                  color: _isDark ? const Color(0xFFD48B47) : const Color(0xFFB35900),
                  width: 1.2,
                ),
              ),
              icon: Icon(
                Icons.save_rounded,
                size: 17,
                color: _isDark ? const Color(0xFFFFD4A8) : Colors.white,
              ),
              label: const Text('Zapisz tankowanie', style: TextStyle(fontWeight: FontWeight.bold)),
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

        if (_isNightHudMode) {
          return _buildNightCockpitHud(route, isPLtoDE, activeTheme);
        }

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
            // Przycisk przełączania w tryb Kokpitu Nocnego (Duży HUD)
            Container(
              margin: const EdgeInsets.only(right: 6),
              child: FilledButton.tonalIcon(
                key: const ValueKey('hud_mode_toggle_btn'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  foregroundColor: const Color(0xFFFF9800),
                  side: BorderSide(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.75),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  setState(() {
                    _isNightHudMode = true;
                    _hudManualStopIndex = null;
                  });
                },
                icon: const Icon(Icons.speed_rounded, size: 17, color: Color(0xFFFF9800)),
                label: const Text(
                  'KOKPIT HUD',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                ),
              ),
            ),
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
                  _buildHotelsDirectoryTab(),
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
    // Czysty, wyraźny kolor ikony i tekstu: soczysty pomarańcz Baltic dla aktywnej, stonowana szarość dla nieaktywnej
    final selectedColor = isDark ? const Color(0xFFFF9800) : const Color(0xFFE65100);
    final unselectedColor = isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C1014).withValues(alpha: 0.98) : Colors.white.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF262626) : Colors.grey.shade300,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, -3),
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
          unselectedItemColor: unselectedColor,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
          ),
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.alt_route_outlined, size: 22),
              activeIcon: Icon(Icons.alt_route, size: 24),
              label: 'Trasa',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.local_gas_station_outlined, size: 22),
              activeIcon: Icon(Icons.local_gas_station, size: 24),
              label: 'Tankowanie',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: route.activeBreak != null,
                backgroundColor: const Color(0xFFC84031),
                label: const Text('PAUZA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                child: const Icon(Icons.assignment_outlined, size: 22),
              ),
              activeIcon: Badge(
                isLabelVisible: route.activeBreak != null,
                backgroundColor: const Color(0xFFC84031),
                label: const Text('PAUZA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                child: const Icon(Icons.assignment, size: 24),
              ),
              label: 'Raporty & Czas',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.hotel_outlined, size: 22),
              activeIcon: Icon(Icons.hotel, size: 24),
              label: 'Hotele',
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

        // Przypomnienie o kawie (jeśli kierowca jedzie >= 2.5h bez przerwy)
        if (_shouldShowCoffeeReminder(route)) ...[
          _buildCoffeeBreakReminderBanner(route),
        ],

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

    return Container(
      decoration: _convexDecoration(
        borderRadius: BorderRadius.circular(16),
        borderColor: _isDark
            ? AppColors.activeTheme.secondaryAccent.withValues(alpha: 0.70)
            : AppColors.brandingOrange.withValues(alpha: 0.85),
        borderWidth: 1.3,
        isHighlighted: true,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imię i nazwisko pasażera (po lewej) + ikona słuchawki i strzałka nawigacji w kółeczkach (po prawej)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        currentTarget.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (currentTarget.passengerCount > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1),
                        ),
                        child: Text(
                          '${currentTarget.passengerCount}',
                          style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (currentTarget.phone.isNotEmpty) ...[
                IconButton(
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.green.withValues(alpha: 0.20),
                    side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.55), width: 1.2),
                    minimumSize: const Size(42, 42),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.phone, size: 22, color: Colors.greenAccent),
                  tooltip: 'Zadzwoń (${currentTarget.phone})',
                  onPressed: () => LauncherService.openPhone(
                    context,
                    currentTarget.phone,
                    currentTarget.name,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: AppColors.brandingOrange.withValues(alpha: 0.20),
                  side: BorderSide(color: AppColors.brandingOrange.withValues(alpha: 0.55), width: 1.2),
                  minimumSize: const Size(42, 42),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.navigation, size: 22, color: AppColors.brandingOrange),
                tooltip: 'Nawiguj do celu',
                onPressed: () => _navigateToCurrentStop(currentTarget, isPLtoDE),
              ),
            ],
          ),
          const SizedBox(height: 11),

          // Szczegóły trasy i godzin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
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
                  InkWell(
                    onTap: () => _navigateToHotel(currentTarget.resort),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.hotel_rounded, size: 22, color: Colors.amber),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'ODBIÓR Z HOTELU',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(Icons.near_me_outlined, size: 13, color: Colors.amber),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  currentTarget.resort.isNotEmpty ? currentTarget.resort : 'Hotel w Polsce',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (currentTarget.resort.isNotEmpty) ...[
                                  Builder(
                                    builder: (context) {
                                      final h = HotelDirectoryService.getCachedHotel(currentTarget.resort);
                                      final addr = h != null && h.fullAddress.isNotEmpty
                                          ? h.fullAddress
                                          : '(brak zapisanego adresu)';
                                      return Text(
                                        addr,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.white.withValues(alpha: 0.75),
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.white24,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
                                  size: 14.5,
                                  color: _isDark ? const Color(0xFFFFE7D0) : Colors.amber,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  currentTarget.hotelTime ?? '--:--',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: _isDark ? const Color(0xFFFFE7D0) : Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 9),
                    child: Divider(height: 1, color: Colors.white12),
                  ),

                  // 2. Adres domowy (Niemcy)
                  InkWell(
                    onTap: () {
                      if (!currentTarget.isTransfer && currentTarget.address.trim().isNotEmpty) {
                        LauncherService.openNavigation(context, currentTarget.address);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.brandingOrange.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.home_rounded, size: 22, color: AppColors.brandingOrange),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'ADRES DOMOWY (NIEMCY)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                    if (!currentTarget.isTransfer) ...[
                                      const SizedBox(width: 5),
                                      const Icon(Icons.near_me_outlined, size: 13, color: AppColors.brandingOrange),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentTarget.displayAddress,
                                  style: const TextStyle(
                                    fontSize: 15.5,
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
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 9),
                    child: Divider(height: 1, color: Colors.white12),
                  ),

                  // 3. Planowany dojazd do domu godzina
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flag_rounded, size: 22, color: Color(0xFF52B788)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PLANOWANY DOJAZD DO DOMU',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 15, color: Color(0xFF52B788)),
                            const SizedBox(width: 5),
                            Text(
                              currentTarget.homeTimeDisplay,
                              style: const TextStyle(
                                fontSize: 17.5,
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
                  InkWell(
                    onTap: () {
                      if (!currentTarget.isTransfer && currentTarget.address.trim().isNotEmpty) {
                        LauncherService.openNavigation(context, currentTarget.address);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.brandingOrange.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.home_rounded, size: 22, color: AppColors.brandingOrange),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'ODBIÓR Z ADRESU DOMOWEGO (NIEMCY)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                    if (!currentTarget.isTransfer) ...[
                                      const SizedBox(width: 5),
                                      const Icon(Icons.near_me_outlined, size: 13, color: AppColors.brandingOrange),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentTarget.displayAddress,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
                                  size: 14.5,
                                  color: _isDark ? const Color(0xFFFFE7D0) : AppColors.brandingOrange,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  currentTarget.homeTimeDisplay,
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: _isDark ? const Color(0xFFFFE7D0) : AppColors.brandingOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 9),
                    child: Divider(height: 1, color: Colors.white12),
                  ),

                  // 2. Hotel docelowy w Polsce
                  InkWell(
                    onTap: () => _navigateToHotel(currentTarget.resort),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.hotel_rounded, size: 22, color: Colors.blueAccent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'HOTEL DOCELOWY W POLSCE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(Icons.near_me_outlined, size: 13, color: Colors.blueAccent),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  currentTarget.resort.isNotEmpty ? currentTarget.resort : 'Hotel w Polsce',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (currentTarget.resort.isNotEmpty) ...[
                                  Builder(
                                    builder: (context) {
                                      final h = HotelDirectoryService.getCachedHotel(currentTarget.resort);
                                      final addr = h != null && h.fullAddress.isNotEmpty
                                          ? h.fullAddress
                                          : '(brak zapisanego adresu)';
                                      return Text(
                                        addr,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.white.withValues(alpha: 0.75),
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.white24,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 9),
                    child: Divider(height: 1, color: Colors.white12),
                  ),

                  // 3. Planowany dojazd do hotelu
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flag_rounded, size: 22, color: Color(0xFF52B788)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PLANOWANY DOJAZD DO HOTELU',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 15, color: Color(0xFF52B788)),
                            const SizedBox(width: 5),
                            Text(
                              currentTarget.hotelTime ?? '--:--',
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF52B788),
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

          // Pod planowany dojazd: małe przyciski (Odebrany, Dostarczony, Przesiadka)
          const SizedBox(height: 9),
          Row(
            children: [
              // 1. ODEBRANY
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: currentTarget.status == PickupStatus.pickedUp
                        ? const Color(0xFF27AE60)
                        : (_isDark ? const Color(0xFF1B4332) : const Color(0xFFE8F5E9)),
                    foregroundColor: currentTarget.status == PickupStatus.pickedUp
                        ? Colors.white
                        : (_isDark ? Colors.white : const Color(0xFF1B5E20)),
                    side: BorderSide(
                      color: currentTarget.status == PickupStatus.pickedUp
                          ? const Color(0xFF52B788)
                          : (_isDark ? const Color(0xFF2D6A4F) : const Color(0xFF81C784)),
                      width: currentTarget.status == PickupStatus.pickedUp ? 1.5 : 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 38),
                  ),
                  onPressed: () {
                    _updatePassengerStatus(currentTarget, PickupStatus.pickedUp);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentTarget.status == PickupStatus.pickedUp
                            ? Icons.check_circle_rounded
                            : Icons.check,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Odebrany',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 2. DOSTARCZONY
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: currentTarget.status == PickupStatus.delivered
                        ? const Color(0xFF1976D2)
                        : (_isDark ? const Color(0xFF0F2B48) : const Color(0xFFE3F2FD)),
                    foregroundColor: currentTarget.status == PickupStatus.delivered
                        ? Colors.white
                        : (_isDark ? Colors.white : const Color(0xFF0D47A1)),
                    side: BorderSide(
                      color: currentTarget.status == PickupStatus.delivered
                          ? const Color(0xFF64B5F6)
                          : (_isDark ? const Color(0xFF1E5B8E) : const Color(0xFF90CAF9)),
                      width: currentTarget.status == PickupStatus.delivered ? 1.5 : 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 38),
                  ),
                  onPressed: () {
                    _updatePassengerStatus(currentTarget, PickupStatus.delivered);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentTarget.status == PickupStatus.delivered
                            ? Icons.check_circle_rounded
                            : Icons.home,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Dostarczony',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 3. PRZESIADKA
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: currentTarget.isTransfer
                        ? const Color(0xFFE67E22)
                        : (_isDark ? const Color(0xFF2E241D) : Colors.orange.shade50),
                    foregroundColor: currentTarget.isTransfer
                        ? Colors.white
                        : (_isDark ? const Color(0xFFFFD4A8) : Colors.deepOrange),
                    side: BorderSide(
                      color: currentTarget.isTransfer
                          ? const Color(0xFFB35900)
                          : const Color(0xFFE67E22).withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 38),
                  ),
                  onPressed: () {
                    _updatePassengerStatus(currentTarget, PickupStatus.delivered);
                    _showNotice('Pasażer oznaczony jako przesiadka', Icons.sync_alt, const Color(0xFFE67E22));
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync_alt, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'Przesiadka',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (currentTarget.comment.isNotEmpty) ...[
            const SizedBox(height: 7),
            _PulsingCommentBadge(
              comment: currentTarget.comment,
              isHero: true,
            ),
          ],
        ],
      ),
    );
  }

  // TRYB KOKPIT NOCNY (DUŻY HUD)
  Widget _buildNightCockpitHud(BusRoute route, bool isPLtoDE, AppThemeData activeTheme) {
    final now = DateTime.now();
    final nowFormatted =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final continuousDuration = _getContinuousDriveDuration(route);
    final cHours = continuousDuration.inHours;
    final cMins = continuousDuration.inMinutes % 60;
    final driveTimeFormatted = cHours > 0 ? '${cHours}h ${cMins}m' : '$cMins min';
    final isDriveAlert = continuousDuration.inMinutes >= _coffeeReminderMinutes;

    final dates = _availableDates;

    // Ustalanie bieżącego celu HUD
    PassengerStop? currentStop;
    int currentStopIndex = 0;

    if (route.stops.isNotEmpty) {
      if (_hudManualStopIndex != null &&
          _hudManualStopIndex! >= 0 &&
          _hudManualStopIndex! < route.stops.length) {
        currentStopIndex = _hudManualStopIndex!;
        currentStop = route.stops[currentStopIndex];
      } else {
        // Domyślnie: pierwszy ze statusem "Oczekuje" (etap odbioru), lub pierwszy niedostarczony
        final pending = route.stops.where((s) => s.status == PickupStatus.pending).toList();
        if (pending.isNotEmpty) {
          currentStop = pending.first;
          currentStopIndex = route.stops.indexOf(currentStop);
        } else {
          try {
            currentStop = route.stops.firstWhere(
              (s) =>
                  s.status != PickupStatus.delivered &&
                  s.status != PickupStatus.cancelled &&
                  s.status != PickupStatus.noShow,
            );
            currentStopIndex = route.stops.indexOf(currentStop);
          } catch (_) {
            currentStop = route.stops.last;
            currentStopIndex = route.stops.length - 1;
          }
        }
      }
    }

    // Wyznaczanie etapu (Odbiór vs Dowóz) i adresu docelowego dla aktywnego przystanku
    String phaseLabel = '';
    Color phaseColor = const Color(0xFFFF9800);
    IconData phaseIcon = Icons.directions_bus;
    String targetAddress = '';
    String plannedTime = '--:--';
    String hudStreetAndNumber = '';
    String hudPostalAndCity = '';

    if (currentStop != null) {
      final isPending = currentStop.status == PickupStatus.pending;
      if (currentStop.isTransfer) {
        phaseLabel = 'PUNKT PRZESIADKOWY';
        phaseColor = const Color(0xFFE67E22);
        phaseIcon = Icons.sync_alt;
        targetAddress = currentStop.address;
        plannedTime = currentStop.homeTimeDisplay;
        hudStreetAndNumber = currentStop.address;
        hudPostalAndCity = 'Punkt Przesiadkowy (Szczecin)';
      } else if (isPLtoDE) {
        // Sobota (Wywóz: PL ➔ DE)
        if (isPending) {
          // Odbiór z hotelu w Polsce
          phaseLabel = 'ODBIÓR Z HOTELU';
          phaseColor = const Color(0xFF27AE60);
          phaseIcon = Icons.hotel_rounded;
          final h = HotelDirectoryService.getCachedHotel(currentStop.resort);
          targetAddress = (h != null && h.fullAddress.isNotEmpty)
              ? h.fullAddress
              : (currentStop.resort.isNotEmpty ? '${currentStop.resort}, Polska' : currentStop.address);
          plannedTime = currentStop.hotelTime ?? '--:--';
          hudStreetAndNumber = (h != null && h.address.isNotEmpty) ? h.address : currentStop.resort;
          final cityPart = (h != null && h.city.isNotEmpty) ? h.city : 'Kołobrzeg';
          hudPostalAndCity = '$cityPart • ${currentStop.resort}';
        } else {
          // Dostawa pod adres domowy w Niemczech
          phaseLabel = 'DOWÓZ POD ADRES (DE)';
          phaseColor = const Color(0xFF1976D2);
          phaseIcon = Icons.home_rounded;
          targetAddress = currentStop.address;
          plannedTime = currentStop.homeTimeDisplay;
          _parseAddressComponents(currentStop.address, (street, postalCity) {
            hudStreetAndNumber = street;
            hudPostalAndCity = postalCity;
          });
        }
      } else {
        // Niedziela (Przywóz: DE ➔ PL)
        if (isPending) {
          // Odbiór z adresu domowego w Niemczech
          phaseLabel = 'ODBIÓR Z ADRESU (DE)';
          phaseColor = const Color(0xFF27AE60);
          phaseIcon = Icons.home_rounded;
          targetAddress = currentStop.address;
          plannedTime = currentStop.homeTimeDisplay;
          _parseAddressComponents(currentStop.address, (street, postalCity) {
            hudStreetAndNumber = street;
            hudPostalAndCity = postalCity;
          });
        } else {
          // Dostawa do hotelu w Polsce
          phaseLabel = 'DOWÓZ DO HOTELU (PL)';
          phaseColor = const Color(0xFF1976D2);
          phaseIcon = Icons.hotel_rounded;
          final h = HotelDirectoryService.getCachedHotel(currentStop.resort);
          targetAddress = (h != null && h.fullAddress.isNotEmpty)
              ? h.fullAddress
              : (currentStop.resort.isNotEmpty ? '${currentStop.resort}, Polska' : currentStop.address);
          plannedTime = currentStop.hotelTime ?? '--:--';
          hudStreetAndNumber = (h != null && h.address.isNotEmpty) ? h.address : currentStop.resort;
          final cityPart = (h != null && h.city.isNotEmpty) ? h.city : 'Kołobrzeg';
          hudPostalAndCity = '$cityPart • ${currentStop.resort}';
        }
      }

      // Zabezpieczenie: jeśli na dole wylądował tylko sam kod (np. "06618"), a miasto zostało przy adresie (np. "Naumburg, Gartenstr. 29")
      if (RegExp(r'^\d{4,5}$|^\d{2}-\d{3}$').hasMatch(hudPostalAndCity.trim())) {
        if (hudStreetAndNumber.contains(',')) {
          final commaParts = hudStreetAndNumber.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          if (commaParts.length >= 2) {
            final city = commaParts[0];
            hudStreetAndNumber = commaParts.sublist(1).join(', ');
            hudPostalAndCity = '${hudPostalAndCity.trim()} $city';
          }
        } else {
          final spaceMatch = RegExp(r'^([^\d,]+)\s+(.+)$').firstMatch(hudStreetAndNumber.trim());
          if (spaceMatch != null) {
            final city = spaceMatch.group(1)!.trim();
            hudStreetAndNumber = spaceMatch.group(2)!.trim();
            hudPostalAndCity = '${hudPostalAndCity.trim()} $city';
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP BAR HUD (Zegar, czas jazdy, przełącznik powrotu)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Duży cyfrowy zegar
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled, color: Color(0xFFFF9800), size: 20),
                      const SizedBox(width: 6),
                      Text(
                        nowFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Wskaźnik ciągłej jazdy
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDriveAlert
                          ? const Color(0xFFC10801).withValues(alpha: 0.35)
                          : const Color(0xFF1F180E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDriveAlert ? const Color(0xFFFF5252) : const Color(0xFFFFB74D),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.coffee_rounded,
                          size: 14,
                          color: isDriveAlert ? const Color(0xFFFF5252) : const Color(0xFFFFB74D),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          driveTimeFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDriveAlert ? const Color(0xFFFF8A80) : const Color(0xFFFFCC80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Przycisk powrotu do widoku normalnego
                  OutlinedButton.icon(
                    key: const ValueKey('hud_exit_button'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 34),
                    ),
                    onPressed: () {
                      setState(() {
                        _isNightHudMode = false;
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'NORMALNY',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. Przełącznik Dnia (Sobota / Niedziela) w trybie HUD
              if (dates.length > 1) ...[
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_selectedDate != dates[0]) {
                            setState(() {
                              _selectedDate = dates[0];
                              _hudManualStopIndex = null;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedDate == dates[0]
                                ? const Color(0xFF2E2210)
                                : const Color(0xFF121212),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedDate == dates[0]
                                  ? const Color(0xFFFF9800)
                                  : Colors.white12,
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sobota (${_shortDate(dates[0])})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedDate == dates[0]
                                  ? const Color(0xFFFF9800)
                                  : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_selectedDate != dates[1]) {
                            setState(() {
                              _selectedDate = dates[1];
                              _hudManualStopIndex = null;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedDate == dates[1]
                                ? const Color(0xFF2E2210)
                                : const Color(0xFF121212),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedDate == dates[1]
                                  ? const Color(0xFFFF9800)
                                  : Colors.white12,
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Niedziela (${_shortDate(dates[1])})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedDate == dates[1]
                                  ? const Color(0xFFFF9800)
                                  : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // 3. GŁÓWNA KARTA HUD (BIEŻĄCY CEL)
              Expanded(
                child: currentStop == null
                    ? const Center(
                        child: Text(
                          'Brak przystanków na tej trasie',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F0F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: phaseColor.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: phaseColor.withValues(alpha: 0.12),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Pasek etapu i numeru przystanku
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: phaseColor.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: phaseColor.withValues(alpha: 0.60),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(phaseIcon, size: 14, color: phaseColor),
                                      const SizedBox(width: 5),
                                      Text(
                                        phaseLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: phaseColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Punkt ${currentStopIndex + 1} z ${route.stops.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(flex: 1),

                            // WIELKA GODZINA
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    plannedTime,
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFF9800),
                                      letterSpacing: 1.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const Text(
                                    'PLANOWANA GODZINA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 1),

                            // 1. IMIĘ I NAZWISKO (na samej górze sekcji, do 2 linijek jeśli długie)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.person_rounded, size: 22, color: Color(0xFFFFB74D)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    currentStop.name,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${currentStop.passengerCount} os.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 2. ADRES Z NUMEREM I KOD Z MIASTEM / HOTELEM (kliknięcie odpala nawigację)
                            InkWell(
                              onTap: () {
                                if (targetAddress.isNotEmpty) {
                                  LauncherService.openNavigation(context, targetAddress);
                                } else {
                                  _showNotice('Brak adresu do nawigacji', Icons.warning, Colors.amber);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hudStreetAndNumber.isNotEmpty ? hudStreetAndNumber : currentStop.address,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.15,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    if (hudPostalAndCity.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 19, color: Color(0xFFFF9800)),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              hudPostalAndCity,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFFCC80),
                                                letterSpacing: 0.3,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.near_me_outlined, size: 18, color: Color(0xFFFF9800)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // UWAGI (np. pulsujący Rollator)
                            if (currentStop.comment.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _PulsingCommentBadge(
                                comment: currentStop.comment,
                                isHero: true,
                              ),
                            ],
                            const Spacer(flex: 2),

                            // DUŻY PRZYCISK NAWIGACJI GOOGLE MAPS
                            SizedBox(
                              height: 50,
                              child: FilledButton.icon(
                                key: const ValueKey('hud_navigate_button'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: () {
                                  if (targetAddress.isNotEmpty) {
                                    LauncherService.openNavigation(context, targetAddress);
                                  } else {
                                    _showNotice('Brak adresu do nawigacji', Icons.warning, Colors.amber);
                                  }
                                },
                                icon: const Icon(Icons.navigation_rounded, size: 24),
                                label: const Text(
                                  'NAWIGUJ (GOOGLE MAPS)',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // PRZYCISK TELEFONU (jeśli jest numer)
                            if (currentStop.phone.isNotEmpty) ...[
                              SizedBox(
                                height: 42,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    LauncherService.openPhone(
                                      context,
                                      currentStop!.phone,
                                      currentStop.name,
                                    );
                                  },
                                  icon: const Icon(Icons.phone, size: 18),
                                  label: Text(
                                    'ZADZWOŃ (${currentStop.phone})',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // 3 PRZYCISKI STATUSU: ODEBRANY | DOSTARCZONY | PRZESIADKA
                            Row(
                              children: [
                                // 1. ODEBRANY
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: currentStop.status == PickupStatus.pickedUp
                                            ? const Color(0xFF27AE60)
                                            : const Color(0xFF1B4332),
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: currentStop.status == PickupStatus.pickedUp
                                              ? const Color(0xFF52B788)
                                              : const Color(0xFF2D6A4F),
                                          width: currentStop.status == PickupStatus.pickedUp ? 1.5 : 1.1,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        _updatePassengerStatus(currentStop!, PickupStatus.pickedUp);
                                        _showNotice('Pasażer oznaczony: Odebrany', Icons.check_circle, const Color(0xFF27AE60));
                                        setState(() {
                                          _hudManualStopIndex = null;
                                        });
                                      },
                                      icon: Icon(
                                        currentStop.status == PickupStatus.pickedUp
                                            ? Icons.check_circle_rounded
                                            : Icons.check,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Odebrany',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // 2. DOSTARCZONY
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: currentStop.status == PickupStatus.delivered && !currentStop.isTransfer
                                            ? const Color(0xFF1976D2)
                                            : const Color(0xFF0F2B48),
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: currentStop.status == PickupStatus.delivered && !currentStop.isTransfer
                                              ? const Color(0xFF64B5F6)
                                              : const Color(0xFF1E5B8E),
                                          width: currentStop.status == PickupStatus.delivered && !currentStop.isTransfer ? 1.5 : 1.1,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        _updatePassengerStatus(currentStop!, PickupStatus.delivered);
                                        _showNotice('Pasażer oznaczony: Dostarczony', Icons.home, const Color(0xFF64B5F6));
                                        setState(() {
                                          _hudManualStopIndex = null;
                                        });
                                      },
                                      icon: Icon(
                                        currentStop.status == PickupStatus.delivered && !currentStop.isTransfer
                                            ? Icons.check_circle_rounded
                                            : Icons.home,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Dostarczony',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // 3. PRZESIADKA
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: FilledButton.icon(
                                      key: const ValueKey('hud_transfer_button'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: currentStop.isTransfer
                                            ? const Color(0xFFE67E22)
                                            : const Color(0xFF2E241D),
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: currentStop.isTransfer
                                              ? const Color(0xFFFFB74D)
                                              : const Color(0xFF6E401F),
                                          width: currentStop.isTransfer ? 1.5 : 1.1,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        _updatePassengerStatus(currentStop!, PickupStatus.delivered);
                                        _showNotice('Pasażer oznaczony jako przesiadka', Icons.sync_alt, const Color(0xFFE67E22));
                                        setState(() {
                                          _hudManualStopIndex = null;
                                        });
                                      },
                                      icon: const Icon(Icons.sync_alt, size: 16),
                                      label: const Text(
                                        'Przesiadka',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 8),

              // 4. DOLNA BELKA NAWIGACJI MIĘDZY PRZYSTANKAMI (< Poprzedni | Następny >)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: currentStopIndex > 0
                        ? () {
                            setState(() {
                              _hudManualStopIndex = currentStopIndex - 1;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                    label: const Text('Poprzedni', style: TextStyle(fontSize: 12)),
                  ),
                  if (_hudManualStopIndex != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _hudManualStopIndex = null;
                        });
                      },
                      child: const Text(
                        'Bieżący cel ↺',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Bieżący cel trasy',
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: currentStopIndex < route.stops.length - 1
                        ? () {
                            setState(() {
                              _hudManualStopIndex = currentStopIndex + 1;
                            });
                          }
                        : null,
                    icon: const Text('Następny', style: TextStyle(fontSize: 12)),
                    label: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _parseAddressComponents(
    String rawAddress,
    void Function(String streetAndNumber, String postalAndCity) onParsed,
  ) {
    final clean = rawAddress.trim();
    if (clean.isEmpty) {
      onParsed('', '');
      return;
    }

    // 1. Sprawdzamy podział po przecinkach
    if (clean.contains(',')) {
      final parts = clean.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      // Przypadek 3 lub więcej części, np. ["06618", "Naumburg", "Gartenstr. 29"] lub ["Gartenstr. 29", "06618", "Naumburg"]
      if (parts.length >= 3) {
        final postalIdx = parts.indexWhere((p) => RegExp(r'^\d{4,5}$|^\d{2}-\d{3}$').hasMatch(p));
        if (postalIdx != -1) {
          final postal = parts[postalIdx];
          int cityIdx = -1;
          if (postalIdx + 1 < parts.length && !RegExp(r'\d').hasMatch(parts[postalIdx + 1])) {
            cityIdx = postalIdx + 1;
          } else if (postalIdx - 1 >= 0 && !RegExp(r'\d').hasMatch(parts[postalIdx - 1])) {
            cityIdx = postalIdx - 1;
          } else {
            cityIdx = parts.indexWhere((p) => p != postal && !RegExp(r'\d').hasMatch(p));
          }

          if (cityIdx != -1) {
            final city = parts[cityIdx];
            final streetParts = <String>[];
            for (int i = 0; i < parts.length; i++) {
              if (i != postalIdx && i != cityIdx) {
                streetParts.add(parts[i]);
              }
            }
            final street = streetParts.join(', ');
            onParsed(street, '$postal $city');
            return;
          }
        }
      }

      // Przypadek 2 części, np. ["06618 Naumburg", "Gartenstr. 29"] lub ["06618", "Naumburg Gartenstr. 29"]
      if (parts.length == 2) {
        final p0 = parts[0];
        final p1 = parts[1];

        // p0 to sam kod: "06618", p1 to "Naumburg Gartenstr. 29"
        if (RegExp(r'^\d{4,5}$|^\d{2}-\d{3}$').hasMatch(p0)) {
          final subMatch = RegExp(r'^([^\d,]+)\s+(.+)$').firstMatch(p1);
          if (subMatch != null) {
            onParsed(subMatch.group(2)!.trim(), '$p0 ${subMatch.group(1)!.trim()}');
            return;
          }
        }

        // p1 to sam kod: "06618", p0 to "Naumburg Gartenstr. 29"
        if (RegExp(r'^\d{4,5}$|^\d{2}-\d{3}$').hasMatch(p1)) {
          final subMatch = RegExp(r'^([^\d,]+)\s+(.+)$').firstMatch(p0);
          if (subMatch != null) {
            onParsed(subMatch.group(2)!.trim(), '$p1 ${subMatch.group(1)!.trim()}');
            return;
          }
        }

        // p0 zaczyna się od kodu i ma miasto: "06618 Naumburg"
        if (RegExp(r'^\d{4,5}\s+|^(\d{2}-\d{3})\s+').hasMatch(p0)) {
          onParsed(p1, p0);
          return;
        }

        // p1 zaczyna się od kodu i ma miasto: "06618 Naumburg"
        if (RegExp(r'^\d{4,5}\s+|^(\d{2}-\d{3})\s+').hasMatch(p1)) {
          onParsed(p0, p1);
          return;
        }

        onParsed(p1, p0);
        return;
      }
    }

    // Bez przecinków, np. "06618 Naumburg Gartenstr. 29"
    final fullMatch = RegExp(r'^(\d{4,5}|\d{2}-\d{3})\s+([^\d,]+?)\s+([A-Za-zäöüßÄÖÜ].*\d+.*)$').firstMatch(clean);
    if (fullMatch != null) {
      onParsed(fullMatch.group(3)!.trim(), '${fullMatch.group(1)!.trim()} ${fullMatch.group(2)!.trim()}');
      return;
    }

    // Fallback gdy kod pocztowy znajduje się w tekście
    final zipMatch = RegExp(r'\b(\d{5}|\d{2}-\d{3})\b').firstMatch(clean);
    if (zipMatch != null) {
      final zip = zipMatch.group(0)!;
      final remaining = clean.replaceFirst(zip, '').trim();
      final subParts = remaining.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (subParts.length >= 2) {
        onParsed(subParts[1], '$zip ${subParts[0]}');
        return;
      }
    }

    onParsed(clean, '');
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
                  backgroundColor: _isDark ? const Color(0xFF5A391E) : const Color(0xFFE67300),
                  foregroundColor: _isDark ? const Color(0xFFFFF1E3) : Colors.white,
                  side: BorderSide(
                    color: _isDark ? const Color(0xFFD48B47) : const Color(0xFFB35900),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  Icons.add_rounded,
                  size: 17,
                  color: _isDark ? const Color(0xFFFFD4A8) : Colors.white,
                ),
                label: const Text('Dodaj tankowanie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: _isDark ? const Color(0xFF554D44) : AppColors.brandingOrange,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: Icon(
                          Icons.add,
                          size: 14,
                          color: _isDark ? const Color(0xFFFFE7D0) : AppColors.brandingOrange,
                        ),
                        label: const Text('Wpłata', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddGuestPaymentDialog(() => setState(() {})),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: _isDark ? const Color(0xFF554D44) : AppColors.brandingOrange,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ZALICZKA:', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
                          const SizedBox(height: 3),
                          Text(
                            '${summary.advanceEur.toStringAsFixed(2)} €',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${summary.advancePln.toStringAsFixed(2)} zł',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(height: 36, width: 1, color: Colors.white12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RESZTA EUR:', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
                            const SizedBox(height: 3),
                            Text(
                              '${summary.remainingAdvanceEur.toStringAsFixed(2)} €',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: summary.remainingAdvanceEur >= 0
                                    ? const Color(0xFF52B788)
                                    : const Color(0xFFFF8A80),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'wydano: ${summary.totalExpensesEur.toStringAsFixed(2)} €',
                              style: const TextStyle(fontSize: 10.5, color: Colors.white54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(height: 36, width: 1, color: Colors.white12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ODEBRANE:', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
                          const SizedBox(height: 3),
                          Text(
                            '${summary.cashCollectedEur.toStringAsFixed(2)} €',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.greenAccent),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${summary.cashCollectedPln.toStringAsFixed(2)} zł',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.greenAccent),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_guestPayments.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, size: 14, color: AppColors.brandingOrange),
                              const SizedBox(width: 6),
                              Text(
                                'WPŁATY OD GOŚCI (${_guestPayments.length}):',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white70),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => _showAddGuestPaymentDialog(() => setState(() {})),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.add, size: 13, color: AppColors.brandingOrange),
                                  SizedBox(width: 2),
                                  Text('Dodaj', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandingOrange)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ..._guestPayments.map((p) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p.passengerName.isNotEmpty ? p.passengerName : 'Gość / pasażer',
                                      style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${p.amount.toStringAsFixed(2)} ${p.currency}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF52B788)),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _deleteGuestPayment(p),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.close, size: 14, color: Colors.white38),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
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
                subtitle: 'Zapisuje oficjalny plik rozliczenia w pamięci telefonu',
                onTap: () => DocxReportService.savePlanJazdyDocx(context, summary),
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

  // TAB 3: BAZA HOTELI I OŚRODKÓW
  Widget _buildHotelsDirectoryTab() {
    final grouped = HotelDirectoryService.getHotelsGroupedByCitySync();
    final allHotels = HotelDirectoryService.getAllHotelsSync().values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final query = _hotelSearchQuery.trim().toLowerCase();
    final isSearching = query.isNotEmpty;
    final searchResults = isSearching
        ? allHotels.where((h) {
            return h.name.toLowerCase().contains(query) ||
                h.address.toLowerCase().contains(query) ||
                h.city.toLowerCase().contains(query) ||
                (h.note != null && h.note!.toLowerCase().contains(query));
          }).toList()
        : <HotelInfo>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _isDark ? const Color(0xFF5A391E) : const Color(0xFFE67300),
        foregroundColor: _isDark ? const Color(0xFFFFF1E3) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _isDark ? const Color(0xFFD48B47) : const Color(0xFFB35900),
            width: 1.2,
          ),
        ),
        icon: Icon(
          Icons.add_business_rounded,
          color: _isDark ? const Color(0xFFFFD4A8) : Colors.white,
        ),
        label: const Text('Dodaj hotel', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showEditHotelDialog(defaultCity: _selectedHotelCity),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Nagłówek zakładki
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: _convexDecoration(
                  borderRadius: BorderRadius.circular(14),
                  borderWidth: 1.1,
                  isHighlighted: false,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.hotel_rounded,
                        color: _isDark ? AppColors.activeTheme.secondaryAccent : _textPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'KATALOG HOTELI I SANATORIÓW',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Wyszukiwarka
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: TextField(
                  controller: _hotelSearchController,
                  onChanged: (val) => setState(() => _hotelSearchQuery = val),
                  style: TextStyle(color: _textPrimary, fontSize: 13.5),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Szukaj po nazwie, ulicy lub mieście...',
                    hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.7), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.gray),
                    suffixIcon: _hotelSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _hotelSearchController.clear();
                              setState(() => _hotelSearchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Pasek wyboru miast (poziome chipy)
            if (!isSearching)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ChoiceChip(
                      label: Text('Wszystkie (${allHotels.length})', style: const TextStyle(fontSize: 11.5)),
                      selected: _selectedHotelCity == null,
                      selectedColor: _isDark ? AppColors.activeTheme.primaryAccent : AppColors.brandingOrange.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: _selectedHotelCity == null
                            ? (_isDark ? AppColors.activeTheme.secondaryAccent : AppColors.brandingOrange)
                            : _textSecondary,
                        fontWeight: _selectedHotelCity == null ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: _selectedHotelCity == null
                            ? (_isDark ? AppColors.activeTheme.secondaryAccent.withValues(alpha: 0.6) : AppColors.brandingOrange)
                            : _borderColor.withValues(alpha: 0.4),
                      ),
                      backgroundColor: _isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _selectedHotelCity = null),
                    ),
                    const SizedBox(width: 6),
                    ...grouped.entries.map((entry) {
                      final isSelected = _selectedHotelCity == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${entry.key} (${entry.value.length})', style: const TextStyle(fontSize: 11.5)),
                          selected: isSelected,
                          selectedColor: _isDark ? AppColors.activeTheme.primaryAccent : AppColors.brandingOrange.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (_isDark ? AppColors.activeTheme.secondaryAccent : AppColors.brandingOrange)
                                : _textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? (_isDark ? AppColors.activeTheme.secondaryAccent.withValues(alpha: 0.6) : AppColors.brandingOrange)
                                : _borderColor.withValues(alpha: 0.4),
                          ),
                          backgroundColor: _isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(() => _selectedHotelCity = isSelected ? null : entry.key),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // Główna lista (Widok Miast LUB Lista Hoteli w danym Mieście LUB Wyniki Szukania)
            Expanded(
              child: isSearching
                  ? _buildHotelSearchResults(searchResults)
                  : (_selectedHotelCity == null
                      ? _buildCitiesOverviewList(grouped)
                      : _buildCityHotelsList(_selectedHotelCity!, grouped[_selectedHotelCity] ?? [])),
            ),
          ],
        ),
      ),
    );
  }

  // WIDOK 1: LISTA MIAST (PODZIAŁ NA MIEJSCOWOŚCI)
  Widget _buildCitiesOverviewList(Map<String, List<HotelInfo>> grouped) {
    final entries = grouped.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final city = entries[index].key;
        final hotels = entries[index].value;
        final previewHotels = hotels.take(3).map((h) => h.name).join(', ');
        final moreCount = hotels.length > 3 ? ' +${hotels.length - 3}' : '';

        final isFromList = city == 'Dodane z listy';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: _convexDecoration(
            borderRadius: BorderRadius.circular(14),
            borderColor: isFromList
                ? (_isDark ? const Color(0xFFD48B47) : AppColors.brandingOrange)
                : _borderColor,
            borderWidth: isFromList ? 1.4 : 1.1,
            isHighlighted: isFromList,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedHotelCity = city),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isFromList
                            ? (_isDark ? const Color(0xFF5A391E) : AppColors.brandingOrange.withValues(alpha: 0.15))
                            : (_isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isFromList ? Icons.playlist_add_check_circle_rounded : Icons.location_city_rounded,
                        color: isFromList
                            ? (_isDark ? const Color(0xFFFFD4A8) : AppColors.brandingOrange)
                            : (_isDark ? AppColors.activeTheme.secondaryAccent : _textSecondary),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                city,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isFromList
                                      ? (_isDark ? const Color(0xFFFFD4A8) : AppColors.brandingOrange)
                                      : _textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildBrandBadge(
                                '${hotels.length} ${hotels.length == 1 ? 'obiekt' : (hotels.length < 5 ? 'obiekty' : 'obiektów')}',
                                isFromList
                                    ? (_isDark ? const Color(0xFFD48B47) : AppColors.brandingOrange)
                                    : (_isDark ? AppColors.activeTheme.secondaryAccent : _textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFromList ? 'Nowe obiekty do uzupełnienia adresu: $previewHotels$moreCount' : '$previewHotels$moreCount',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isFromList ? (_isDark ? const Color(0xFFFFE7D0) : _textPrimary) : _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isFromList
                          ? (_isDark ? const Color(0xFFFFD4A8) : AppColors.brandingOrange)
                          : AppColors.gray,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // WIDOK 2: HOTELE W WYBRANYM MIEŚCIE
  Widget _buildCityHotelsList(String city, List<HotelInfo> hotels) {
    return Column(
      children: [
        // Belka nawigacyjna z powrotem do miast
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _selectedHotelCity = null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 14,
                        color: _isDark ? AppColors.activeTheme.secondaryAccent : _textPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Wszystkie miasta',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _isDark ? AppColors.activeTheme.secondaryAccent : _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$city (${hotels.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: hotels.isEmpty
              ? Center(
                  child: Text(
                    'Brak hoteli w miejscowości $city',
                    style: TextStyle(color: _textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: hotels.length,
                  itemBuilder: (context, index) => _buildHotelCard(hotels[index]),
                ),
        ),
      ],
    );
  }

  // WIDOK 3: WYNIKI WYSZUKIWANIA
  Widget _buildHotelSearchResults(List<HotelInfo> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: AppColors.gray),
            const SizedBox(height: 8),
            Text(
              'Nie znaleziono hoteli pasujących do zapytania',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: results.length,
      itemBuilder: (context, index) => _buildHotelCard(results[index]),
    );
  }

  // KARTA POJEDYNCZEGO HOTELU
  Widget _buildHotelCard(HotelInfo hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _convexDecoration(
        borderRadius: BorderRadius.circular(14),
        borderColor: _borderColor,
        borderWidth: 1.1,
        isHighlighted: false,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Nazwa hotelu + ikona hotelu + menu opcji
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    child: Icon(
                      Icons.hotel_rounded,
                      size: 18,
                      color: AppColors.brandingOrange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hotel.name,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: PopupMenuButton<String>(
                      tooltip: 'Opcje hotelu',
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, size: 19, color: AppColors.gray),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showEditHotelDialog(hotel: hotel);
                        } else if (val == 'delete') {
                          _confirmDeleteHotel(hotel);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edytuj dane'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Usuń z bazy', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),

              // 2. Adres (kliknięcie odpala nawigację, idealnie w linii z nazwą)
              InkWell(
                onTap: () {
                  final navTarget = hotel.address.isNotEmpty
                      ? hotel.fullAddress
                      : '${hotel.name}, ${hotel.city}';
                  LauncherService.openNavigation(context, navTarget);
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 20,
                        child: Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 17,
                            color: AppColors.gray,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hotel.fullAddress,
                          style: TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
        onLongPress: () => _showCoffeeReminderSettingsDialog(route),
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

  Duration _getContinuousDriveDuration(BusRoute route) {
    if (route.activeBreak != null) {
      return Duration.zero;
    }
    DateTime? start = _driveStartTime;
    if (start == null) {
      final finishedBreaks = route.breaks.where((b) => !b.isActive && b.endTime != null).toList();
      if (finishedBreaks.isNotEmpty) {
        finishedBreaks.sort((a, b) => a.endTime!.compareTo(b.endTime!));
        start = finishedBreaks.last.endTime;
      }
    }
    if (start == null) {
      final firstPickup = route.stops
          .where((s) => s.pickedUpAt != null)
          .map((s) => s.pickedUpAt!)
          .fold<DateTime?>(null, (min, dt) => min == null || dt.isBefore(min) ? dt : min);
      start = firstPickup;
    }
    if (start != null) {
      final diff = DateTime.now().difference(start);
      return diff.isNegative ? Duration.zero : diff;
    }
    return Duration.zero;
  }

  bool _shouldShowCoffeeReminder(BusRoute route) {
    if (route.activeBreak != null) return false;
    if (_coffeeBreakSnoozeUntil != null && DateTime.now().isBefore(_coffeeBreakSnoozeUntil!)) {
      return false;
    }
    final driveDuration = _getContinuousDriveDuration(route);
    return driveDuration.inMinutes >= _coffeeReminderMinutes;
  }

  Widget _buildCoffeeBreakReminderBanner(BusRoute route) {
    final duration = _getContinuousDriveDuration(route);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final timeFormatted = hours > 0 ? '${hours}h ${minutes}min' : '$minutes min';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF1F180E), const Color(0xFF130E07)]
              : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isDark
              ? const Color(0xFFFFB74D).withValues(alpha: 0.65)
              : const Color(0xFFFFA000).withValues(alpha: 0.70),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDark ? const Color(0xFFFFB74D).withValues(alpha: 0.08) : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDark ? const Color(0xFF2E2210) : const Color(0xFFFFE082),
                  border: Border.all(
                    color: _isDark ? const Color(0xFFFFA726) : const Color(0xFFFF8F00),
                    width: 1.3,
                  ),
                ),
                child: const Icon(
                  Icons.coffee_rounded,
                  size: 20,
                  color: Color(0xFFFFB74D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '☕ Czas na przerwę i kawę!',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: _isDark ? const Color(0xFFFFCC80) : const Color(0xFF5D4037),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _coffeeBreakSnoozeUntil = DateTime.now().add(const Duration(minutes: 30));
                            });
                            _showNotice('Przypomnienie o kawie wyciszone na 30 min', Icons.notifications_off, const Color(0xFFFFA726));
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: _isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prowadzisz już $timeFormatted bez przerwy. Zadbaj o chwilę odpoczynku dla bezpieczeństwa.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDark ? Colors.white70 : Colors.black87,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Przycisk "Zrób przerwę"
              Expanded(
                flex: 6,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE68A00),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFFFB74D), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () {
                    _handleBreakPillTap(route);
                  },
                  icon: const Icon(Icons.coffee, size: 16),
                  label: const Text(
                    'Zrób przerwę',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Przycisk "Za 15 min"
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isDark ? const Color(0xFFFFCC80) : const Color(0xFF5D4037),
                    backgroundColor: _isDark ? const Color(0xFF261D12) : Colors.white60,
                    side: BorderSide(
                      color: _isDark ? const Color(0xFFFFB74D).withValues(alpha: 0.50) : Colors.grey.shade400,
                      width: 1.1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () {
                    setState(() {
                      _coffeeBreakSnoozeUntil = DateTime.now().add(const Duration(minutes: 15));
                    });
                    _showNotice('Przypomnienie o kawie odłożone o 15 minut', Icons.snooze, const Color(0xFFFFA726));
                  },
                  icon: const Icon(Icons.alarm, size: 15),
                  label: const Text(
                    'Za 15 min',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCoffeeReminderSettingsDialog(BusRoute route) {
    final continuousDuration = _getContinuousDriveDuration(route);
    final hours = continuousDuration.inHours;
    final minutes = continuousDuration.inMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '$minutes min';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF383838)),
          ),
          title: const Row(
            children: [
              Icon(Icons.coffee_rounded, color: Color(0xFFFFD4A8), size: 22),
              SizedBox(width: 8),
              Text(
                'Przypomnienie o kawie',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFFFD4A8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bieżący czas ciągłej jazdy: $timeStr',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Przypomnij po czasie ciągłej jazdy:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gray),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('2 godz.'),
                    selected: _coffeeReminderMinutes == 120,
                    onSelected: (sel) async {
                      if (sel) {
                        setState(() => _coffeeReminderMinutes = 120);
                        setDialogState(() {});
                        await StorageService.saveCoffeeReminderMinutes(120);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('2,5 godz. (zalecane)'),
                    selected: _coffeeReminderMinutes == 150,
                    onSelected: (sel) async {
                      if (sel) {
                        setState(() => _coffeeReminderMinutes = 150);
                        setDialogState(() {});
                        await StorageService.saveCoffeeReminderMinutes(150);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('3 godz.'),
                    selected: _coffeeReminderMinutes == 180,
                    onSelected: (sel) async {
                      if (sel) {
                        setState(() => _coffeeReminderMinutes = 180);
                        setDialogState(() {});
                        await StorageService.saveCoffeeReminderMinutes(180);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD4A8),
                    side: const BorderSide(color: Color(0xFF8D4F1E)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      _driveStartTime = DateTime.now().subtract(Duration(minutes: _coffeeReminderMinutes + 5));
                      _coffeeBreakSnoozeUntil = null;
                    });
                    Navigator.pop(ctx);
                    _showNotice(
                      'Uruchomiono test: zasymulowano ${_coffeeReminderMinutes + 5} min jazdy!',
                      Icons.coffee_rounded,
                      const Color(0xFFD48B47),
                    );
                  },
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                  label: const Text(
                    'Symuluj 2,5h jazdy (test komunikatu)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Gotowe'),
            ),
          ],
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
    final hotelInfo = stop.resort.isNotEmpty ? HotelDirectoryService.getCachedHotel(stop.resort) : null;
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
        statusColor = _isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
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
                              Flexible(
                                child: Text(
                                  hotelInfo != null && hotelInfo.address.isNotEmpty
                                      ? '• ${stop.resort} (${hotelInfo.address})'
                                      : '• ${stop.resort}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDelivered
                                        ? (_isDark ? Colors.white38 : Colors.grey.shade600)
                                        : AppColors.gray,
                                  ),
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
                                            : const Color(0xFF27AE60),
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
      // Widok rozwiniętej karty (spójny z kartą aktywnego pasażera)
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RZĄD GÓRNY: Numerek przystanku + Imię i nazwisko + liczba osób + okrągłe przyciski (słuchawka, nawigacja) + zwinięcie
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 13,
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
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          stop.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDelivered
                                ? (_isDark ? Colors.white60 : Colors.black54)
                                : _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (stop.passengerCount > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1),
                          ),
                          child: Text(
                            '${stop.passengerCount}',
                            style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (stop.phone.isNotEmpty) ...[
                  IconButton(
                    style: IconButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.green.withValues(alpha: 0.20),
                      side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.55), width: 1.2),
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.phone, size: 19, color: Colors.greenAccent),
                    tooltip: 'Zadzwoń (${stop.phone})',
                    onPressed: () => LauncherService.openPhone(
                      context,
                      stop.phone,
                      stop.name,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: AppColors.brandingOrange.withValues(alpha: 0.20),
                    side: BorderSide(color: AppColors.brandingOrange.withValues(alpha: 0.55), width: 1.2),
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.navigation, size: 19, color: AppColors.brandingOrange),
                  tooltip: 'Nawiguj do celu',
                  onPressed: () => _navigateToCurrentStop(stop, isPLtoDE),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.expand_less, size: 22, color: AppColors.gray),
                  tooltip: 'Zwiń szczegóły',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _togglePassengerCollapse(stop),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Szczegóły trasy i godzin (czarny boks)
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
                    InkWell(
                      onTap: () => _navigateToHotel(stop.resort),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        child: Row(
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
                                  Row(
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
                                      const SizedBox(width: 4),
                                      const Icon(Icons.near_me_outlined, size: 12, color: Colors.amber),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    stop.resort.isNotEmpty ? stop.resort : 'Hotel w Polsce',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (stop.resort.isNotEmpty) ...[
                                    Builder(
                                      builder: (context) {
                                        final h = HotelDirectoryService.getCachedHotel(stop.resort);
                                        final addr = h != null && h.fullAddress.isNotEmpty
                                            ? h.fullAddress
                                            : '(brak zapisanego adresu)';
                                        return Text(
                                          addr,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.white.withValues(alpha: 0.75),
                                            decoration: TextDecoration.underline,
                                            decorationColor: Colors.white24,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ],
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
                                    stop.hotelTime ?? '--:--',
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
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Colors.white12),
                    ),

                    // 2. Adres domowy (Niemcy)
                    InkWell(
                      onTap: () {
                        if (!stop.isTransfer && stop.address.trim().isNotEmpty) {
                          LauncherService.openNavigation(context, stop.address);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        child: Row(
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
                                  Row(
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
                                      if (!stop.isTransfer) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.near_me_outlined, size: 12, color: AppColors.brandingOrange),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stop.displayAddress,
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
                      ),
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                                stop.homeTimeDisplay,
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
                    InkWell(
                      onTap: () {
                        if (!stop.isTransfer && stop.address.trim().isNotEmpty) {
                          LauncherService.openNavigation(context, stop.address);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        child: Row(
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
                                  Row(
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
                                      if (!stop.isTransfer) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.near_me_outlined, size: 12, color: AppColors.brandingOrange),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stop.displayAddress,
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
                                    stop.homeTimeDisplay,
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
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Colors.white12),
                    ),

                    // 2. Hotel docelowy w Polsce
                    InkWell(
                      onTap: () => _navigateToHotel(stop.resort),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Row(
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
                                      const SizedBox(width: 4),
                                      const Icon(Icons.near_me_outlined, size: 12, color: Colors.blueAccent),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    stop.resort.isNotEmpty ? stop.resort : 'Hotel w Polsce',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (stop.resort.isNotEmpty) ...[
                                    Builder(
                                      builder: (context) {
                                        final h = HotelDirectoryService.getCachedHotel(stop.resort);
                                        final addr = h != null && h.fullAddress.isNotEmpty
                                            ? h.fullAddress
                                            : '(brak zapisanego adresu)';
                                        return Text(
                                          addr,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.white.withValues(alpha: 0.75),
                                            decoration: TextDecoration.underline,
                                            decorationColor: Colors.white24,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Colors.white12),
                    ),

                    // 3. Planowany dojazd do hotelu
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PLANOWANY DOJAZD DO HOTELU',
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
                                stop.hotelTime ?? '--:--',
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
                  ],
                ],
              ),
            ),

          if (stop.pickedUpAt != null || stop.deliveredAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 4),
                if (stop.pickedUpAt != null)
                  Text(
                    'Odebrano: ${_formatTime(stop.pickedUpAt!)} ',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF27AE60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (stop.deliveredAt != null)
                  Text(
                    '• Dostarczono: ${_formatTime(stop.deliveredAt!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E824C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],

          // Pod planowany dojazd: 3 przyciski statusu (Odebrany, Dostarczony, Przesiadka)
          const SizedBox(height: 8),
          Row(
            children: [
              // 1. ODEBRANY
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: stop.status == PickupStatus.pickedUp
                        ? const Color(0xFF27AE60)
                        : (_isDark ? const Color(0xFF1B4332) : const Color(0xFFE8F5E9)),
                    foregroundColor: stop.status == PickupStatus.pickedUp
                        ? Colors.white
                        : (_isDark ? Colors.white : const Color(0xFF1B5E20)),
                    side: BorderSide(
                      color: stop.status == PickupStatus.pickedUp
                          ? const Color(0xFF52B788)
                          : (_isDark ? const Color(0xFF2D6A4F) : const Color(0xFF81C784)),
                      width: stop.status == PickupStatus.pickedUp ? 1.5 : 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () {
                    _updatePassengerStatus(stop, PickupStatus.pickedUp);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        stop.status == PickupStatus.pickedUp
                            ? Icons.check_circle_rounded
                            : Icons.check,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Odebrany',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 2. DOSTARCZONY
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: stop.status == PickupStatus.delivered
                        ? const Color(0xFF1976D2)
                        : (_isDark ? const Color(0xFF0F2B48) : const Color(0xFFE3F2FD)),
                    foregroundColor: stop.status == PickupStatus.delivered
                        ? Colors.white
                        : (_isDark ? Colors.white : const Color(0xFF0D47A1)),
                    side: BorderSide(
                      color: stop.status == PickupStatus.delivered
                          ? const Color(0xFF64B5F6)
                          : (_isDark ? const Color(0xFF1E5B8E) : const Color(0xFF90CAF9)),
                      width: stop.status == PickupStatus.delivered ? 1.5 : 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () {
                    _updatePassengerStatus(stop, PickupStatus.delivered);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        stop.status == PickupStatus.delivered
                            ? Icons.check_circle_rounded
                            : Icons.home,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Dostarczony',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 3. PRZESIADKA
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: stop.isTransfer
                        ? const Color(0xFFE67E22)
                        : (_isDark ? const Color(0xFF2E241D) : Colors.orange.shade50),
                    foregroundColor: stop.isTransfer
                        ? Colors.white
                        : (_isDark ? const Color(0xFFFFD4A8) : Colors.deepOrange),
                    side: BorderSide(
                      color: stop.isTransfer
                          ? const Color(0xFFB35900)
                          : const Color(0xFFE67E22).withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () {
                    _updatePassengerStatus(stop, PickupStatus.delivered);
                    _showNotice('Pasażer oznaczony jako przesiadka', Icons.sync_alt, const Color(0xFFE67E22));
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync_alt, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Przesiadka',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (stop.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            _PulsingCommentBadge(
              comment: stop.comment,
              isHero: false,
              animate: !isDelivered,
            ),
          ],
        ],
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
    _driveTimeTicker?.cancel();
    _welcomeClockTimer?.cancel();
    _hotelSearchController.dispose();
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

  void _navigateToHotel(String resortName) {
    final cleanResort = resortName.trim();
    if (cleanResort.isEmpty) {
      _showNotice('Brak przypisanego hotelu.', Icons.info_outline, Colors.amber);
      return;
    }
    final h = HotelDirectoryService.getCachedHotel(cleanResort);
    String target;
    if (h != null && h.fullAddress.isNotEmpty) {
      target = h.fullAddress;
    } else if (h != null && h.address.isNotEmpty) {
      final cityPart = h.city.isNotEmpty ? h.city : 'Kołobrzeg';
      target = '${h.address}, $cityPart';
    } else if (h != null && h.city.isNotEmpty) {
      target = '$cleanResort, ${h.city}';
    } else {
      target = '$cleanResort, Polska';
    }
    LauncherService.openNavigation(context, target);
  }

  void _navigateToCurrentStop(PassengerStop stop, bool isPLtoDE) {
    // Sobota (Wywóz: PL -> DE):
    //   Gdy pasażer jeszcze oczekuje na odbiór (pending) -> jedziemy do HOTELU
    //   Gdy pasażer odebrany (pickedUp / dalszy etap) -> jedziemy pod adres domowy w DE
    // Niedziela (Przywóz: DE -> PL):
    //   Gdy pasażer oczekuje na odbiór (pending) -> jedziemy pod adres domowy w DE
    //   Gdy odebrany -> jedziemy do HOTELU docelowego w Polsce
    final bool headingToHotel = isPLtoDE
        ? (stop.status == PickupStatus.pending)
        : (stop.status != PickupStatus.pending);

    if (headingToHotel && stop.resort.isNotEmpty) {
      _navigateToHotel(stop.resort);
    } else {
      if (stop.isTransfer || stop.address.trim().isEmpty) {
        if (stop.resort.isNotEmpty) {
          _navigateToHotel(stop.resort);
        } else {
          _showNotice('Pasażer przesiadkowy - brak adresu.', Icons.info_outline, Colors.amber);
        }
      } else {
        LauncherService.openNavigation(context, stop.address);
      }
    }
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
      guestPayments: _guestPayments,
    );
  }

  Future<void> _addGuestPayment(GuestPaymentEntry entry, [VoidCallback? onUpdated]) async {
    setState(() {
      _guestPayments.add(entry);
      _cashCollectedPln = _guestPayments.where((p) => p.currency == 'PLN').fold(0.0, (sum, p) => sum + p.amount);
      _cashCollectedEur = _guestPayments.where((p) => p.currency == 'EUR').fold(0.0, (sum, p) => sum + p.amount);
    });
    await StorageService.saveGuestPayments(_currentRoute.code, _guestPayments);
    await StorageService.saveTripFinancials(
      busCode: _selectedBusCode,
      advanceEur: _advanceEur,
      advancePln: _advancePln,
      cashCollectedPln: _cashCollectedPln,
      cashCollectedEur: _cashCollectedEur,
    );
    onUpdated?.call();
  }

  Future<void> _deleteGuestPayment(GuestPaymentEntry entry, [VoidCallback? onUpdated]) async {
    setState(() {
      _guestPayments.removeWhere((p) => p.id == entry.id);
      _cashCollectedPln = _guestPayments.where((p) => p.currency == 'PLN').fold(0.0, (sum, p) => sum + p.amount);
      _cashCollectedEur = _guestPayments.where((p) => p.currency == 'EUR').fold(0.0, (sum, p) => sum + p.amount);
    });
    await StorageService.saveGuestPayments(_currentRoute.code, _guestPayments);
    await StorageService.saveTripFinancials(
      busCode: _selectedBusCode,
      advanceEur: _advanceEur,
      advancePln: _advancePln,
      cashCollectedPln: _cashCollectedPln,
      cashCollectedEur: _cashCollectedEur,
    );
    onUpdated?.call();
  }

  void _showAddGuestPaymentDialog([VoidCallback? onSaved]) {
    String selectedCurrency = 'PLN';
    final amountCtrl = TextEditingController();
    final passengerCtrl = TextEditingController();

    final Set<String> passengerSet = {};
    for (final s in _currentRoute.stops) {
      if (s.name.trim().isNotEmpty) passengerSet.add(s.name.trim());
    }
    if (_saturdayRoute != null) {
      for (final s in _saturdayRoute!.stops) {
        if (s.name.trim().isNotEmpty) passengerSet.add(s.name.trim());
      }
    }
    if (_sundayRoute != null) {
      for (final s in _sundayRoute!.stops) {
        if (s.name.trim().isNotEmpty) passengerSet.add(s.name.trim());
      }
    }
    final passengerList = passengerSet.toList()..sort();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.payment, color: AppColors.brandingOrange, size: 20),
              SizedBox(width: 8),
              Text('Wpłata od gościa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WALUTA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('PLN (zł)', style: TextStyle(fontWeight: FontWeight.bold))),
                        selected: selectedCurrency == 'PLN',
                        selectedColor: AppColors.brandingOrange,
                        labelStyle: TextStyle(
                          color: selectedCurrency == 'PLN' ? Colors.white : _textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedCurrency = 'PLN');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('EUR (€)', style: TextStyle(fontWeight: FontWeight.bold))),
                        selected: selectedCurrency == 'EUR',
                        selectedColor: AppColors.brandingOrange,
                        labelStyle: TextStyle(
                          color: selectedCurrency == 'EUR' ? Colors.white : _textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedCurrency = 'EUR');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Kwota wpłaty',
                    suffixText: selectedCurrency == 'PLN' ? 'zł' : '€',
                    border: const OutlineInputBorder(),
                    hintText: 'np. 150.00',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passengerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Imię i nazwisko pasażera / opis',
                    border: OutlineInputBorder(),
                    hintText: 'np. Jan Kowalski',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                if (passengerList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Wybierz z listy pasażerów:', style: TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: passengerList.map((name) => ActionChip(
                          avatar: const Icon(Icons.add, size: 14),
                          label: Text(name, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setDialogState(() {
                              passengerCtrl.text = name;
                            });
                          },
                        )).toList(),
                      ),
                    ),
                  ),
                ],
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
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wpisz poprawną kwotę wpłaty')),
                  );
                  return;
                }
                final entry = GuestPaymentEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: amount,
                  currency: selectedCurrency,
                  passengerName: passengerCtrl.text.trim(),
                  timestamp: DateTime.now(),
                );
                Navigator.pop(ctx);
                await _addGuestPayment(entry, onSaved);
              },
              child: const Text('Dodaj wpłatę'),
            ),
          ],
        ),
      ),
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
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ODEBRANE OD GOŚCI:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                  if (_guestPayments.isNotEmpty)
                    Text('${_guestPayments.length} wpłat', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                ],
              ),
              const SizedBox(height: 6),
              if (_guestPayments.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kwoty wyliczane automatycznie z wpłat gości: ${_cashCollectedEur.toStringAsFixed(2)} € / ${_cashCollectedPln.toStringAsFixed(2)} zł.',
                        style: TextStyle(fontSize: 11.5, color: _textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddGuestPaymentDialog(onSaved);
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Zarządzaj / Dodaj wpłatę gościa'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
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
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddGuestPaymentDialog(onSaved);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Dodaj jako osobną wpłatę od gościa'),
                ),
              ],
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
                if (_guestPayments.isEmpty) {
                  _cashCollectedEur = double.tryParse(cashEurCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                  _cashCollectedPln = double.tryParse(cashPlnCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                }
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

  void _showEditHotelDialog({HotelInfo? hotel, String? defaultCity, VoidCallback? onSaved}) {
    final isEditing = hotel != null;
    final nameCtrl = TextEditingController(text: hotel?.name ?? '');
    final addressCtrl = TextEditingController(text: hotel?.address ?? '');
    final cityCtrl = TextEditingController(
      text: hotel?.city.isNotEmpty == true ? hotel!.city : (defaultCity ?? 'Kołobrzeg'),
    );
    final noteCtrl = TextEditingController(text: hotel?.note ?? '');

    const popularCities = ['Kołobrzeg', 'Świnoujście', 'Międzyzdroje', 'Ustronie Morskie', 'Mrzeżyno'];

    final dialogAccent = _isDark ? AppColors.activeTheme.secondaryAccent : AppColors.brandingOrange;
    final focusedBorderColor = _isDark ? AppColors.activeTheme.secondaryAccent.withValues(alpha: 0.8) : AppColors.brandingOrange;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.hotel_rounded, color: dialogAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEditing ? 'Edycja hotelu' : 'Nowy Hotel / Ośrodek',
                      style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      isEditing ? hotel.name : 'Dodaj do bazy stałej',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
                      overflow: TextOverflow.ellipsis,
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
                  'Hotel zostanie zapamiętany w bazie na stałe i nie zniknie po zakończeniu wyjazdu.',
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
                const SizedBox(height: 14),
                // Nazwa hotelu
                TextField(
                  controller: nameCtrl,
                  autofocus: !isEditing,
                  style: TextStyle(color: _textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Nazwa hotelu / ośrodka *',
                    hintText: 'np. San, Arka, Hotel New Skanpol',
                    labelStyle: TextStyle(color: _textSecondary),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Miejscowość
                TextField(
                  controller: cityCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: _textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Miejscowość *',
                    hintText: 'np. Kołobrzeg, Dziwnówek, Pobierowo',
                    labelStyle: TextStyle(color: _textSecondary),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Szybki wybór popularnych miejscowości
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: popularCities.map((c) {
                    final isSel = cityCtrl.text.trim().toLowerCase() == c.toLowerCase();
                    return ChoiceChip(
                      label: Text(
                        c,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSel
                              ? (_isDark ? AppColors.activeTheme.secondaryAccent : Colors.white)
                              : _textSecondary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: _isDark ? AppColors.activeTheme.primaryAccent : AppColors.brandingOrange,
                      side: BorderSide(
                        color: isSel
                            ? (_isDark ? AppColors.activeTheme.secondaryAccent.withValues(alpha: 0.6) : AppColors.brandingOrange)
                            : _borderColor.withValues(alpha: 0.4),
                      ),
                      backgroundColor: _isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) {
                        setDialogState(() {
                          cityCtrl.text = c;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Ulica i numer budynku
                TextField(
                  controller: addressCtrl,
                  style: TextStyle(color: _textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Ulica i numer budynku *',
                    hintText: 'np. ul. Kasprowicza 24',
                    labelStyle: TextStyle(color: _textSecondary),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Wskazówka / Uwagi
                TextField(
                  controller: noteCtrl,
                  style: TextStyle(color: _textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Wskazówka / Uwagi (opcjonalnie)',
                    hintText: 'np. Wjazd od promenady, dzwonek przy szlabanie',
                    labelStyle: TextStyle(color: _textSecondary),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
                    ),
                  ),
                ),
                if (hotel != null && hotel.fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      LauncherService.openNavigation(context, hotel.fullAddress);
                    },
                    icon: Icon(Icons.near_me_outlined, size: 16, color: dialogAccent),
                    label: Text(
                      'Sprawdź w Google Maps (${hotel.fullAddress})',
                      style: TextStyle(fontSize: 12, color: dialogAccent),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _isDark ? AppColors.activeTheme.primaryAccent : AppColors.brandingOrange,
                foregroundColor: _isDark ? AppColors.activeTheme.secondaryAccent : Colors.white,
                side: BorderSide(
                  color: _isDark ? AppColors.activeTheme.border.withValues(alpha: 0.8) : Colors.transparent,
                ),
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newAddr = addressCtrl.text.trim();
                final newCity = cityCtrl.text.trim().isEmpty ? 'Kołobrzeg' : cityCtrl.text.trim();
                final newNote = noteCtrl.text.trim();
                if (newName.isEmpty) {
                  _showNotice('Wpisz nazwę hotelu', Icons.warning_amber_rounded, Colors.orangeAccent);
                  return;
                }
                Navigator.pop(ctx);
                await HotelDirectoryService.saveHotel(
                  name: newName,
                  address: newAddr,
                  city: newCity,
                  note: newNote.isNotEmpty ? newNote : null,
                  fromList: newAddr.isEmpty, // Jeśli adres nadal jest pusty, pozostaje w 'Dodane z listy'
                  previousName: hotel?.name,
                );
                if (mounted) {
                  setState(() {
                    _selectedHotelCity = null; // Powrót do widoku wszystkich miast, aby nowy kafelek był widoczny
                  });
                  onSaved?.call();
                  _showNotice('Zapisano hotel $newName ($newCity)', Icons.check_circle, Colors.greenAccent);
                }
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Zapisz na stałe', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteHotel(HotelInfo hotel, {VoidCallback? onDeleted}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _borderColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Usuń hotel', style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Czy na pewno chcesz usunąć hotel "${hotel.name}" (${hotel.city.isNotEmpty ? hotel.city : 'Dodane z listy'}) z bazy?',
          style: TextStyle(color: _textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await HotelDirectoryService.deleteHotel(hotel.name);
              if (mounted) {
                setState(() {});
                onDeleted?.call();
                _showNotice('Usunięto hotel ${hotel.name}', Icons.delete_outline, Colors.orangeAccent);
              }
            },
            child: const Text('Usuń', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            actionsOverflowButtonSpacing: 8,
            actionsOverflowDirection: VerticalDirection.down,
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

                  // ZALICZKA (z opcją edycji)
                  InkWell(
                    onTap: () {
                      _showEditFinancialsDialog(() {
                        setDialogState(() {
                          summary.advanceEur = _advanceEur;
                          summary.advancePln = _advancePln;
                          summary.guestPayments = _guestPayments;
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ZALICZKA:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    '$eurStr  /  $plnStr',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit, size: 14, color: AppColors.brandingOrange),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ODEBRANE OD GOŚCI (z listą i opcją dodawania)
                  Container(
                    width: double.infinity,
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
                            const Text('ODEBRANE OD GOŚCI:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                guestText.isNotEmpty ? guestText : '0,00 zł / 0,00 €',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                        if (_guestPayments.isNotEmpty) ...[
                          Divider(height: 12, color: _borderColor),
                          ..._guestPayments.map((p) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.arrow_right, size: 16, color: AppColors.brandingOrange),
                                    Expanded(
                                      child: Text(
                                        '${p.amount.toStringAsFixed(2)} ${p.currency}${p.passengerName.isNotEmpty ? ' (${p.passengerName})' : ''}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _deleteGuestPayment(p, () {
                                          setDialogState(() {
                                            summary.guestPayments = List.from(_guestPayments);
                                            summary.cashCollectedPln = _cashCollectedPln;
                                            summary.cashCollectedEur = _cashCollectedEur;
                                          });
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.close, size: 14, color: Colors.redAccent),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              _showAddGuestPaymentDialog(() {
                                setDialogState(() {
                                  summary.guestPayments = List.from(_guestPayments);
                                  summary.cashCollectedPln = _cashCollectedPln;
                                  summary.cashCollectedEur = _cashCollectedEur;
                                });
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_circle_outline, size: 14, color: AppColors.brandingOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dodaj wpłatę',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: _isDark ? const Color(0xFFFFE7D0) : AppColors.brandingOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
                            const SizedBox(width: 8),
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
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        if (summary.advanceEur > 0) ...[
                          Divider(height: 14, color: _borderColor),
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 14,
                                color: summary.remainingAdvanceEur >= 0 ? const Color(0xFF27AE60) : const Color(0xFFC10801),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'POZOSTAŁO Z ZALICZKI:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: summary.remainingAdvanceEur >= 0 ? const Color(0xFF27AE60) : const Color(0xFFC10801),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${summary.remainingAdvanceEur.toStringAsFixed(2)} EUR',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: summary.remainingAdvanceEur >= 0 ? const Color(0xFF27AE60) : const Color(0xFFC10801),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                  DocxReportService.savePlanJazdyDocx(context, summary);
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

class _PulsingCommentBadge extends StatefulWidget {
  final String comment;
  final bool isHero;
  final bool animate;

  const _PulsingCommentBadge({
    required this.comment,
    this.isHero = false,
    this.animate = true,
  });

  @override
  State<_PulsingCommentBadge> createState() => _PulsingCommentBadgeState();
}

class _PulsingCommentBadgeState extends State<_PulsingCommentBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(covariant _PulsingCommentBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        if (_controller == null) {
          _startAnimation();
        } else {
          _controller!.repeat(reverse: true);
        }
      } else {
        _controller?.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate || _animation == null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isHero ? 9 : 8,
          vertical: widget.isHero ? 4 : 3,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFC10801).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC10801).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: widget.isHero ? 14.5 : 13,
              color: const Color(0xFFFF8A80),
            ),
            SizedBox(width: widget.isHero ? 5 : 4),
            Expanded(
              child: Text(
                'Uwagi: ${widget.comment}',
                style: TextStyle(
                  fontSize: widget.isHero ? 12.5 : 11.5,
                  color: const Color(0xFFFF8A80),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation!,
      builder: (context, child) {
        final val = _animation!.value;
        final bgAlpha = 0.20 + (val * 0.20);
        final borderAlpha = 0.45 + (val * 0.45);
        final glowAlpha = val * 0.22;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isHero ? 9 : 8,
            vertical: widget.isHero ? 4 : 3,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFC10801).withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFE53935).withValues(alpha: borderAlpha),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: glowAlpha),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: widget.isHero ? 14.5 : 13,
                color: Color.lerp(const Color(0xFFFF8A80), Colors.white, val * 0.35),
              ),
              SizedBox(width: widget.isHero ? 5 : 4),
              Expanded(
                child: Text(
                  'Uwagi: ${widget.comment}',
                  style: TextStyle(
                    fontSize: widget.isHero ? 12.5 : 11.5,
                    color: Color.lerp(const Color(0xFFFF8A80), Colors.white, val * 0.35),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}





