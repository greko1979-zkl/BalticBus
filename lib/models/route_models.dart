enum PickupStatus {
  pending,
  pickedUp,
  delivered,
  noShow,
  cancelled,
}

class PassengerStop {
  final int order;
  final String name;
  final String address;
  final int passengerCount;
  final String phone;
  final String comment;
  final String office;
  final String resort;
  final String? hotelTime; // Sobota: godz. odbioru z hotelu w PL; Niedziela: godz. dojazdu do hotelu w PL
  final String? homeTime;  // Sobota: godz. dojazdu do domu w DE; Niedziela: godz. odbioru z domu w DE
  final String? driveTime;
  final String? distance;
  PickupStatus status;
  DateTime? pickedUpAt;
  DateTime? deliveredAt;
  bool isCollapsed;

  PassengerStop({
    required this.order,
    required this.name,
    required this.address,
    required this.passengerCount,
    required this.phone,
    this.comment = '',
    this.office = '',
    this.resort = '',
    this.hotelTime,
    this.homeTime,
    this.driveTime,
    this.distance,
    this.status = PickupStatus.pending,
    this.pickedUpAt,
    this.deliveredAt,
    this.isCollapsed = true,
  });

  /// Pasażer przesiadkowy (brak adresu domowego w Niemczech, w Excelu oznaczone jako XXX)
  bool get isTransfer {
    final clean = address.trim().toUpperCase();
    return clean == 'XXX' ||
        clean.startsWith('XXX') ||
        clean.contains('PRZESIADKA') ||
        comment.toUpperCase().contains('PRZESIADKA') ||
        office.toUpperCase().contains('PRZESIADKA');
  }

  /// Czytelny adres pasażera (gdy w Excelu jest XXX, informuje o przesiadce)
  String get displayAddress {
    final clean = address.trim().toUpperCase();
    if (clean == 'XXX' || clean.isEmpty) {
      return 'Przesiadka (brak adresu domowego)';
    }
    return address;
  }

  /// Wyświetlanie godziny domowej lub 'przesiadka' zamiast kresek
  String get homeTimeDisplay {
    if (homeTime != null &&
        homeTime!.isNotEmpty &&
        homeTime != '--:--' &&
        homeTime!.toUpperCase() != 'XXX') {
      return homeTime!;
    }
    if (isTransfer) {
      return 'przesiadka';
    }
    return '--:--';
  }
}

class TransferPoint {
  final String time;
  final String location;
  final String instruction;
  bool isCompleted;

  TransferPoint({
    required this.time,
    required this.location,
    required this.instruction,
    this.isCompleted = false,
  });
}

class RefuelingEntry {
  final String id;
  final int odometerKm;
  final double liters;
  final double amount;
  final String currency; // 'PLN' lub 'EUR'
  final String stationName; // 'MOYA' lub 'Tankowanie DE'
  final String paymentMethod; // 'Karta flota MOYA', 'Gotówka PLN', 'Gotówka EUR'
  final String fuelType; // 'Diesel (ON)' lub 'AdBlue'
  final DateTime timestamp;

  RefuelingEntry({
    required this.id,
    required this.odometerKm,
    required this.liters,
    required this.amount,
    this.currency = 'PLN',
    required this.stationName,
    this.paymentMethod = 'Karta flota MOYA',
    this.fuelType = 'Diesel (ON)',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'odometerKm': odometerKm,
    'liters': liters,
    'amount': amount,
    'currency': currency,
    'stationName': stationName,
    'paymentMethod': paymentMethod,
    'fuelType': fuelType,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RefuelingEntry.fromJson(Map<String, dynamic> json) => RefuelingEntry(
    id: json['id'] as String,
    odometerKm: json['odometerKm'] as int,
    liters: (json['liters'] as num).toDouble(),
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] as String? ?? 'PLN',
    stationName: json['stationName'] as String? ?? 'MOYA',
    paymentMethod: json['paymentMethod'] as String? ?? 'Karta flota MOYA',
    fuelType: json['fuelType'] as String? ?? 'Diesel (ON)',
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class DriverBreak {
  final String id;
  final DateTime startTime;
  DateTime? endTime;

  DriverBreak({
    required this.id,
    required this.startTime,
    this.endTime,
  });

  bool get isActive => endTime == null;

  int get durationMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
  };

  factory DriverBreak.fromJson(Map<String, dynamic> json) => DriverBreak(
    id: json['id'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
  );
}

class BusRoute {
  final String id;
  final String code; // np. BB.01
  final String title; // np. Rozklad_2026-08-01_PL-DE
  final String date;
  final String direction; // PL-DE lub DE-PL
  final String vehicleModel; // np. Ford Custom
  final String registrationNumber; // np. ZS_615RU
  final String driverName; // np. Grzesiek Korowajczyk
  final String driverPhone;
  final int plannedDistanceKm;
  final List<String> specialNotes;
  final List<PassengerStop> stops;
  final List<TransferPoint> transferPoints;
  final List<RefuelingEntry> refuelings;
  final List<DriverBreak> breaks;
  final String? googleMapsUrl;
  int? startOdometerKm;
  int? endOdometerKm;

  BusRoute({
    required this.id,
    required this.code,
    required this.title,
    required this.date,
    required this.direction,
    required this.vehicleModel,
    required this.registrationNumber,
    required this.driverName,
    required this.driverPhone,
    required this.plannedDistanceKm,
    this.specialNotes = const [],
    required this.stops,
    this.transferPoints = const [],
    List<RefuelingEntry>? refuelings,
    List<DriverBreak>? breaks,
    this.googleMapsUrl,
    this.startOdometerKm,
    this.endOdometerKm,
  })  : refuelings = refuelings ?? [],
        breaks = breaks ?? [];

  int get totalPassengers =>
      stops.fold(0, (sum, stop) => sum + stop.passengerCount);

  int get pickedUpPassengers => stops
      .where((s) =>
          s.status == PickupStatus.pickedUp || s.status == PickupStatus.delivered)
      .fold(0, (sum, stop) => sum + stop.passengerCount);

  double get totalRefueledLiters =>
      refuelings.fold(0.0, (sum, r) => sum + r.liters);

  double get totalDieselLiters => refuelings
      .where((r) => r.fuelType == 'Diesel (ON)')
      .fold(0.0, (sum, r) => sum + r.liters);

  double get totalAdBlueLiters => refuelings
      .where((r) => r.fuelType == 'AdBlue')
      .fold(0.0, (sum, r) => sum + r.liters);

  double get totalRefueledAmountPLN => refuelings
      .where((r) => r.currency == 'PLN')
      .fold(0.0, (sum, r) => sum + r.amount);

  double get totalRefueledAmountEUR => refuelings
      .where((r) => r.currency == 'EUR')
      .fold(0.0, (sum, r) => sum + r.amount);

  int? get actualDistanceKm {
    if (startOdometerKm != null && endOdometerKm != null) {
      return endOdometerKm! - startOdometerKm!;
    }
    return null;
  }

  // Średnie spalanie liczone wyłącznie z oleju napędowego (Diesel ON)
  double? get averageConsumptionLPer100Km {
    final dist = actualDistanceKm ?? plannedDistanceKm;
    if (dist > 0 && totalDieselLiters > 0) {
      return (totalDieselLiters / dist) * 100.0;
    }
    return null;
  }

  DriverBreak? get activeBreak {
    for (final b in breaks) {
      if (b.isActive) return b;
    }
    return null;
  }

  int get totalBreakMinutes =>
      breaks.fold(0, (sum, b) => sum + b.durationMinutes);
}

class WeekendTripSummary {
  final String busCode;
  final String dateRange; // np. 01.08 - 02.08.2026
  final String driverName;
  final String driverPhone;
  final String vehicleModel;
  final String registrationNumber;
  final BusRoute? saturdayRoute;
  final BusRoute? sundayRoute;
  double advanceEur;
  double advancePln;
  double cashCollectedPln;
  double cashCollectedEur;

  WeekendTripSummary({
    required this.busCode,
    required this.dateRange,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleModel,
    required this.registrationNumber,
    this.saturdayRoute,
    this.sundayRoute,
    this.advanceEur = 0.0,
    this.advancePln = 0.0,
    this.cashCollectedPln = 0.0,
    this.cashCollectedEur = 0.0,
  });

  int? get startOdometer =>
      saturdayRoute?.startOdometerKm ?? sundayRoute?.startOdometerKm;

  int? get endOdometer =>
      sundayRoute?.endOdometerKm ?? saturdayRoute?.endOdometerKm;

  int? get totalDistanceKm {
    if (startOdometer != null && endOdometer != null && endOdometer! >= startOdometer!) {
      return endOdometer! - startOdometer!;
    }
    final satDiff = saturdayRoute?.actualDistanceKm;
    final sunDiff = sundayRoute?.actualDistanceKm;
    if (satDiff != null && sunDiff != null) return satDiff + sunDiff;
    return satDiff ?? sunDiff;
  }

  int get plannedTotalDistanceKm =>
      (saturdayRoute?.plannedDistanceKm ?? 0) +
      (sundayRoute?.plannedDistanceKm ?? 0);

  List<RefuelingEntry> get allRefuelings => [
    if (saturdayRoute != null) ...saturdayRoute!.refuelings,
    if (sundayRoute != null) ...sundayRoute!.refuelings,
  ];

  List<RefuelingEntry> get expensesPln =>
      allRefuelings.where((r) => r.currency == 'PLN').toList();

  List<RefuelingEntry> get expensesEur =>
      allRefuelings.where((r) => r.currency == 'EUR').toList();

  double get totalDieselLiters => allRefuelings
      .where((r) => r.fuelType == 'Diesel (ON)')
      .fold(0.0, (sum, r) => sum + r.liters);

  double get totalAdBlueLiters => allRefuelings
      .where((r) => r.fuelType == 'AdBlue')
      .fold(0.0, (sum, r) => sum + r.liters);

  double get totalExpensesPln =>
      expensesPln.fold(0.0, (sum, r) => sum + r.amount);

  double get totalExpensesEur =>
      expensesEur.fold(0.0, (sum, r) => sum + r.amount);

  double? get averageConsumptionLPer100Km {
    final dist = totalDistanceKm ?? (plannedTotalDistanceKm > 0 ? plannedTotalDistanceKm : null);
    if (dist != null && dist > 0 && totalDieselLiters > 0) {
      return (totalDieselLiters / dist) * 100.0;
    }
    return null;
  }

  List<DriverBreak> get saturdayBreaks => saturdayRoute?.breaks ?? [];
  List<DriverBreak> get sundayBreaks => sundayRoute?.breaks ?? [];

  int get totalPassengers =>
      (saturdayRoute?.totalPassengers ?? 0) + (sundayRoute?.totalPassengers ?? 0);

  int get pickedUpPassengers =>
      (saturdayRoute?.pickedUpPassengers ?? 0) + (sundayRoute?.pickedUpPassengers ?? 0);
}

