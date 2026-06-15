import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// --- MODELS ---

class Package {
  final String id;
  final String trackingNumber;
  final String? receiverName;
  final String? receiverPhone;
  final String? notes;
  final double? lat;
  final double? lng;
  final String? street;
  final String? zone;
  final String? barangay;
  final String? city;
  final String paymentType; // 'cod_cash' | 'cod_digital' | 'prepaid'
  final double codCash;
  final double codDigital;
  final double tips;
  final double extraAmount;
  final String? extraLabel;
  final String status; // 'pending' | 'delivered' | 'failed' | 'returned' | 'rescheduled' | 'rejected'
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deliveredAt;
  final int attemptCount; // computed field (from attempts table joining or subquery)
  final String? photoPath;
  final String? deliveryPhotoPath;
  final String? rideId;
  final DateTime? rescheduledDate;
  final String? rejectionReason;

  Package({
    required this.id,
    required this.trackingNumber,
    this.receiverName,
    this.receiverPhone,
    this.notes,
    this.lat,
    this.lng,
    this.street,
    this.zone,
    this.barangay,
    this.city,
    required this.paymentType,
    required this.codCash,
    required this.codDigital,
    required this.tips,
    required this.extraAmount,
    this.extraLabel,
    required this.status,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deliveredAt,
    this.attemptCount = 0,
    this.photoPath,
    this.deliveryPhotoPath,
    this.rideId,
    this.rescheduledDate,
    this.rejectionReason,
  });

  double get totalCod => codCash + codDigital;
  double get grandTotal => totalCod + tips + extraAmount;

  factory Package.fromMap(Map<String, dynamic> map, {int attempts = 0}) {
    return Package(
      id: map['id'] as String,
      trackingNumber: map['tracking_number'] as String,
      receiverName: map['receiver_name'] as String?,
      receiverPhone: map['receiver_phone'] as String?,
      notes: map['notes'] as String?,
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      street: map['street'] as String?,
      zone: map['zone'] as String?,
      barangay: map['barangay'] as String?,
      city: map['city'] as String?,
      paymentType: map['payment_type'] as String? ?? 'cod_cash',
      codCash: (map['cod_cash'] as num? ?? 0.0).toDouble(),
      codDigital: (map['cod_digital'] as num? ?? 0.0).toDouble(),
      tips: (map['tips'] as num? ?? 0.0).toDouble(),
      extraAmount: (map['extra_amount'] as num? ?? 0.0).toDouble(),
      extraLabel: map['extra_label'] as String?,
      status: map['status'] as String? ?? 'pending',
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deliveredAt: map['delivered_at'] != null ? DateTime.parse(map['delivered_at'] as String) : null,
      attemptCount: attempts,
      photoPath: map['photo_path'] as String?,
      deliveryPhotoPath: map['delivery_photo_path'] as String?,
      rideId: map['ride_id'] as String?,
      rescheduledDate: map['rescheduled_date'] != null ? DateTime.parse(map['rescheduled_date'] as String) : null,
      rejectionReason: map['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tracking_number': trackingNumber,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'notes': notes,
      'lat': lat,
      'lng': lng,
      'street': street,
      'zone': zone,
      'barangay': barangay,
      'city': city,
      'payment_type': paymentType,
      'cod_cash': codCash,
      'cod_digital': codDigital,
      'tips': tips,
      'extra_amount': extraAmount,
      'extra_label': extraLabel,
      'status': status,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'photo_path': photoPath,
      'delivery_photo_path': deliveryPhotoPath,
      'ride_id': rideId,
      'rescheduled_date': rescheduledDate?.toIso8601String(),
      'rejection_reason': rejectionReason,
    };
  }

  Package copyWith({
    String? id,
    String? trackingNumber,
    String? receiverName,
    String? receiverPhone,
    String? notes,
    double? lat,
    double? lng,
    String? street,
    String? zone,
    String? barangay,
    String? city,
    String? paymentType,
    double? codCash,
    double? codDigital,
    double? tips,
    double? extraAmount,
    String? extraLabel,
    String? status,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    int? attemptCount,
    String? photoPath,
    String? deliveryPhotoPath,
    String? rideId,
    DateTime? rescheduledDate,
    String? rejectionReason,
  }) {
    return Package(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      notes: notes ?? this.notes,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      street: street ?? this.street,
      zone: zone ?? this.zone,
      barangay: barangay ?? this.barangay,
      city: city ?? this.city,
      paymentType: paymentType ?? this.paymentType,
      codCash: codCash ?? this.codCash,
      codDigital: codDigital ?? this.codDigital,
      tips: tips ?? this.tips,
      extraAmount: extraAmount ?? this.extraAmount,
      extraLabel: extraLabel ?? this.extraLabel,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      attemptCount: attemptCount ?? this.attemptCount,
      photoPath: photoPath ?? this.photoPath,
      deliveryPhotoPath: deliveryPhotoPath ?? this.deliveryPhotoPath,
      rideId: rideId ?? this.rideId,
      rescheduledDate: rescheduledDate ?? this.rescheduledDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class Ride {
  final String id;
  final int rideNumber;
  final DateTime date;
  final DateTime startedAt;
  final DateTime? endedAt;

  Ride({
    required this.id,
    required this.rideNumber,
    required this.date,
    required this.startedAt,
    this.endedAt,
  });

  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'] as String,
      rideNumber: map['ride_number'] as int,
      date: DateTime.parse(map['date'] as String),
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ride_number': rideNumber,
      'date': date.toIso8601String().substring(0, 10),
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }

  Ride copyWith({
    String? id,
    int? rideNumber,
    DateTime? date,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return Ride(
      id: id ?? this.id,
      rideNumber: rideNumber ?? this.rideNumber,
      date: date ?? this.date,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}

class DeliveryAttempt {
  final int? id;
  final String packageId;
  final String status; // 'success' | 'failed' | 'no_answer' | 'refused'
  final String? notes;
  final DateTime attemptedAt;

  DeliveryAttempt({
    this.id,
    required this.packageId,
    required this.status,
    this.notes,
    required this.attemptedAt,
  });

  factory DeliveryAttempt.fromMap(Map<String, dynamic> map) {
    return DeliveryAttempt(
      id: map['id'] as int?,
      packageId: map['package_id'] as String,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      attemptedAt: DateTime.parse(map['attempted_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'package_id': packageId,
      'status': status,
      'notes': notes,
      'attempted_at': attemptedAt.toIso8601String(),
    };
  }
}

class PaymentSummary {
  final double codCash;
  final double codDigital;
  final double tips;
  final double extraAmount;

  PaymentSummary({
    required this.codCash,
    required this.codDigital,
    required this.tips,
    required this.extraAmount,
  });

  double get totalCod => codCash + codDigital;
  double get grandTotal => totalCod + tips + extraAmount;

  factory PaymentSummary.empty() {
    return PaymentSummary(codCash: 0, codDigital: 0, tips: 0, extraAmount: 0);
  }
}

// --- DATABASE HELPER ---

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ridertrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE packages ADD COLUMN photo_path TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE packages ADD COLUMN delivery_photo_path TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS rides (
          id TEXT PRIMARY KEY,
          ride_number INTEGER NOT NULL,
          date TEXT NOT NULL,
          started_at TEXT NOT NULL,
          ended_at TEXT
        )
      ''');
      await db.execute('ALTER TABLE packages ADD COLUMN ride_id TEXT REFERENCES rides(id)');
      await db.execute('ALTER TABLE packages ADD COLUMN rescheduled_date TEXT');
      await db.execute('ALTER TABLE packages ADD COLUMN rejection_reason TEXT');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_rides_date ON rides(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_ride_id ON packages(ride_id)');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE packages (
        id TEXT PRIMARY KEY,
        tracking_number TEXT NOT NULL UNIQUE,
        receiver_name TEXT,
        receiver_phone TEXT,
        notes TEXT,
        lat REAL,
        lng REAL,
        street TEXT,
        zone TEXT,
        barangay TEXT,
        city TEXT,
        payment_type TEXT NOT NULL DEFAULT 'cod_cash',
        cod_cash REAL NOT NULL DEFAULT 0,
        cod_digital REAL NOT NULL DEFAULT 0,
        tips REAL NOT NULL DEFAULT 0,
        extra_amount REAL NOT NULL DEFAULT 0,
        extra_label TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        delivered_at TEXT,
        photo_path TEXT,
        delivery_photo_path TEXT,
        ride_id TEXT REFERENCES rides(id),
        rescheduled_date TEXT,
        rejection_reason TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE delivery_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_id TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        attempted_at TEXT NOT NULL,
        FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create Indexes
    await db.execute('CREATE INDEX idx_packages_barangay ON packages(barangay);');
    await db.execute('CREATE INDEX idx_packages_city ON packages(city);');
    await db.execute('CREATE INDEX idx_packages_status ON packages(status);');
    await db.execute('CREATE INDEX idx_packages_sort_order ON packages(sort_order);');
    await db.execute('CREATE INDEX idx_packages_created_at ON packages(created_at);');

    await db.execute('''
      CREATE TABLE rides (
        id TEXT PRIMARY KEY,
        ride_number INTEGER NOT NULL,
        date TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_rides_date ON rides(date);');
    await db.execute('CREATE INDEX idx_packages_ride_id ON packages(ride_id);');
  }

  // --- CRUD PACKAGES ---

  Future<List<Package>> getPackages({
    String? searchQuery,
    List<String>? statusFilters,
    List<String>? barangayFilters,
    List<String>? paymentTypeFilters,
  }) async {
    final db = await database;
    
    // Build filter queries
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('(tracking_number LIKE ? OR receiver_name LIKE ? OR city LIKE ? OR barangay LIKE ?)');
      final term = '%$searchQuery%';
      whereArgs.addAll([term, term, term, term]);
    }

    if (statusFilters != null && statusFilters.isNotEmpty) {
      final placeholders = List.filled(statusFilters.length, '?').join(', ');
      whereClauses.add('status IN ($placeholders)');
      whereArgs.addAll(statusFilters);
    }

    if (barangayFilters != null && barangayFilters.isNotEmpty) {
      final placeholders = List.filled(barangayFilters.length, '?').join(', ');
      whereClauses.add('barangay IN ($placeholders)');
      whereArgs.addAll(barangayFilters);
    }

    if (paymentTypeFilters != null && paymentTypeFilters.isNotEmpty) {
      final placeholders = List.filled(paymentTypeFilters.length, '?').join(', ');
      whereClauses.add('payment_type IN ($placeholders)');
      whereArgs.addAll(paymentTypeFilters);
    }

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    
    // Fetch packages with their attempt counts
    final sql = '''
      SELECT p.*, (SELECT COUNT(*) FROM delivery_attempts WHERE package_id = p.id) as attempt_count
      FROM packages p
      $whereString
      ORDER BY p.sort_order ASC, p.created_at DESC
    ''';

    final result = await db.rawQuery(sql, whereArgs);
    return result.map((map) {
      final attempts = map['attempt_count'] as int? ?? 0;
      return Package.fromMap(map, attempts: attempts);
    }).toList();
  }

  Future<List<Package>> getPendingPackagesWithLocation() async {
    final db = await database;
    final result = await db.query(
      'packages',
      where: "status = 'pending' AND lat IS NOT NULL AND lng IS NOT NULL",
      orderBy: 'sort_order ASC',
    );
    return result.map((map) => Package.fromMap(map)).toList();
  }

  Future<Package?> getPackageById(String id) async {
    final db = await database;
    final maps = await db.query(
      'packages',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      // Get attempt count
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM delivery_attempts WHERE package_id = ?',
        [id],
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      return Package.fromMap(maps.first, attempts: count);
    }
    return null;
  }

  Future<Package?> getPackageByTrackingNumber(String trk) async {
    final db = await database;
    final maps = await db.query(
      'packages',
      where: 'tracking_number = ?',
      whereArgs: [trk],
    );

    if (maps.isNotEmpty) {
      final id = maps.first['id'] as String;
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM delivery_attempts WHERE package_id = ?',
        [id],
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      return Package.fromMap(maps.first, attempts: count);
    }
    return null;
  }

  Future<int> insertPackage(Package package) async {
    final db = await database;
    
    // Auto-calculate sort order as the max sort_order + 1
    final maxOrderResult = await db.rawQuery('SELECT MAX(sort_order) as max_order FROM packages');
    final maxOrder = Sqflite.firstIntValue(maxOrderResult) ?? -1;
    final newSortOrder = maxOrder + 1;

    final p = package.copyWith(sortOrder: newSortOrder);
    return await db.insert('packages', p.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<int> updatePackage(Package package) async {
    final db = await database;
    final p = package.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'packages',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [package.id],
    );
  }

  Future<int> deletePackage(String id) async {
    final db = await database;
    return await db.delete(
      'packages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSortOrders(List<String> orderedIds) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(
        'packages',
        {'sort_order': i, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> getUniqueBarangays() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT barangay FROM packages WHERE barangay IS NOT NULL AND barangay != "" ORDER BY barangay ASC'
    );
    return result.map((r) => r['barangay'] as String).toList();
  }

  Future<List<String>> getUniqueStreets() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT street FROM packages WHERE street IS NOT NULL AND street != "" ORDER BY street ASC'
    );
    return result.map((r) => r['street'] as String).toList();
  }

  Future<List<String>> getUniqueZones() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT zone FROM packages WHERE zone IS NOT NULL AND zone != "" ORDER BY zone ASC'
    );
    return result.map((r) => r['zone'] as String).toList();
  }

  Future<List<String>> getUniqueCities() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT city FROM packages WHERE city IS NOT NULL AND city != "" ORDER BY city ASC'
    );
    return result.map((r) => r['city'] as String).toList();
  }

  Future<List<String>> getUniqueStatuses() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT status FROM packages WHERE status IS NOT NULL AND status != "" ORDER BY status ASC'
    );
    return result.map((r) => r['status'] as String).toList();
  }

  Future<List<String>> getUniquePaymentTypes() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT payment_type FROM packages WHERE payment_type IS NOT NULL AND payment_type != "" ORDER BY payment_type ASC'
    );
    return result.map((r) => r['payment_type'] as String).toList();
  }

  // --- CRUD ATTEMPTS ---

  Future<int> insertAttempt(DeliveryAttempt attempt) async {
    final db = await database;
    return await db.insert('delivery_attempts', attempt.toMap());
  }

  Future<List<DeliveryAttempt>> getAttemptsForPackage(String packageId) async {
    final db = await database;
    final result = await db.query(
      'delivery_attempts',
      where: 'package_id = ?',
      whereArgs: [packageId],
      orderBy: 'attempted_at DESC',
    );
    return result.map((map) => DeliveryAttempt.fromMap(map)).toList();
  }

  // --- SETTINGS KEY-VALUE ---

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- FINANCIAL SUMMARY ---

  Future<PaymentSummary> getPaymentSummary() async {
    final db = await database;
    // Compute total Cash and total Digital and total Tips from packages where status = 'delivered'
    final result = await db.rawQuery('''
      SELECT 
        SUM(cod_cash) as total_cash, 
        SUM(cod_digital) as total_digital, 
        SUM(tips) as total_tips,
        SUM(extra_amount) as total_extra
      FROM packages 
      WHERE status = 'delivered'
    ''');
    
    if (result.isNotEmpty && result.first['total_cash'] != null) {
      return PaymentSummary(
        codCash: (result.first['total_cash'] as num? ?? 0.0).toDouble(),
        codDigital: (result.first['total_digital'] as num? ?? 0.0).toDouble(),
        tips: (result.first['total_tips'] as num? ?? 0.0).toDouble(),
        extraAmount: (result.first['total_extra'] as num? ?? 0.0).toDouble(),
      );
    }
    return PaymentSummary.empty();
  }

  Future<void> clearDeliveredPackages() async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete attempts for delivered packages first to be safe (cascade should handle it, but let's be explicit)
      await txn.rawDelete('''
        DELETE FROM delivery_attempts 
        WHERE package_id IN (SELECT id FROM packages WHERE status = 'delivered')
      ''');
      // Delete delivered packages
      await txn.delete('packages', where: "status = 'delivered'");
    });
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('delivery_attempts');
    await db.delete('packages');
    await db.delete('settings');
    await db.delete('rides');
  }

  // --- RIDE HELPER METHODS ---

  Future<int> insertRide(Ride ride) async {
    final db = await database;
    return await db.insert('rides', ride.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateRide(Ride ride) async {
    final db = await database;
    return await db.update(
      'rides',
      ride.toMap(),
      where: 'id = ?',
      whereArgs: [ride.id],
    );
  }

  Future<Ride?> getRideById(String id) async {
    final db = await database;
    final result = await db.query(
      'rides',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Ride.fromMap(result.first);
    }
    return null;
  }

  Future<Ride?> getActiveRide() async {
    final db = await database;
    final result = await db.query(
      'rides',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Ride.fromMap(result.first);
    }
    return null;
  }

  Future<List<Ride>> getRidesForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final result = await db.query(
      'rides',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'ride_number ASC',
    );
    return result.map((map) => Ride.fromMap(map)).toList();
  }

  Future<List<Ride>> getAllRides() async {
    final db = await database;
    final result = await db.query('rides', orderBy: 'started_at DESC');
    return result.map((map) => Ride.fromMap(map)).toList();
  }

  Future<int> getNextRideNumberForDate(DateTime date) async {
    final rides = await getRidesForDate(date);
    if (rides.isEmpty) return 1;
    int maxNum = 0;
    for (final r in rides) {
      if (r.rideNumber > maxNum) {
        maxNum = r.rideNumber;
      }
    }
    return maxNum + 1;
  }

  Future<List<Package>> getPackagesForRide(String rideId) async {
    final db = await database;
    final result = await db.query(
      'packages',
      where: 'ride_id = ?',
      orderBy: 'sort_order ASC',
    );
    return result.map((map) => Package.fromMap(map)).toList();
  }

  Future<void> revertExpiredRescheduledPackages() async {
    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    final today = DateTime.now();
    final tomorrowStart = DateTime(today.year, today.month, today.day + 1).toIso8601String();
    await db.update(
      'packages',
      {
        'status': 'pending',
        'updated_at': nowStr,
      },
      where: "status = 'rescheduled' AND rescheduled_date < ?",
      whereArgs: [tomorrowStart],
    );
  }

  Future<List<Package>> getTodayPackages({
    String? searchQuery,
    List<String>? statusFilters,
    List<String>? barangayFilters,
    List<String>? paymentTypeFilters,
  }) async {
    await revertExpiredRescheduledPackages();

    final db = await database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    whereClauses.add('''
      (
        p.status = 'pending' OR
        p.created_at LIKE ? OR
        p.delivered_at LIKE ? OR
        p.ride_id IN (SELECT id FROM rides WHERE date = ?)
      )
    ''');
    whereArgs.addAll(['$todayStr%', '$todayStr%', todayStr]);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('(p.tracking_number LIKE ? OR p.receiver_name LIKE ? OR p.city LIKE ? OR p.barangay LIKE ?)');
      final term = '%$searchQuery%';
      whereArgs.addAll([term, term, term, term]);
    }

    if (statusFilters != null && statusFilters.isNotEmpty) {
      final placeholders = List.filled(statusFilters.length, '?').join(', ');
      whereClauses.add('p.status IN ($placeholders)');
      whereArgs.addAll(statusFilters);
    }

    if (barangayFilters != null && barangayFilters.isNotEmpty) {
      final placeholders = List.filled(barangayFilters.length, '?').join(', ');
      whereClauses.add('p.barangay IN ($placeholders)');
      whereArgs.addAll(barangayFilters);
    }

    if (paymentTypeFilters != null && paymentTypeFilters.isNotEmpty) {
      final placeholders = List.filled(paymentTypeFilters.length, '?').join(', ');
      whereClauses.add('p.payment_type IN ($placeholders)');
      whereArgs.addAll(paymentTypeFilters);
    }

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    
    final sql = '''
      SELECT p.*, (SELECT COUNT(*) FROM delivery_attempts WHERE package_id = p.id) as attempt_count
      FROM packages p
      $whereString
      ORDER BY p.sort_order ASC, p.created_at DESC
    ''';

    final result = await db.rawQuery(sql, whereArgs);
    return result.map((map) {
      final attempts = map['attempt_count'] as int? ?? 0;
      return Package.fromMap(map, attempts: attempts);
    }).toList();
  }

  Future<List<Package>> getPackagesInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? searchQuery,
    List<String>? statusFilters,
    List<String>? barangayFilters,
    List<String>? paymentTypeFilters,
  }) async {
    final db = await database;
    
    final startStr = "${startDate.toIso8601String().substring(0, 10)} 00:00:00";
    final endStr = "${endDate.toIso8601String().substring(0, 10)} 23:59:59";
    
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];
    
    whereClauses.add('''
      (
        (p.created_at BETWEEN ? AND ?) OR 
        (p.delivered_at BETWEEN ? AND ?) OR
        (p.ride_id IN (SELECT id FROM rides WHERE date BETWEEN ? AND ?))
      )
    ''');
    final startDay = startDate.toIso8601String().substring(0, 10);
    final endDay = endDate.toIso8601String().substring(0, 10);
    whereArgs.addAll([startStr, endStr, startStr, endStr, startDay, endDay]);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('(p.tracking_number LIKE ? OR p.receiver_name LIKE ? OR p.city LIKE ? OR p.barangay LIKE ?)');
      final term = '%$searchQuery%';
      whereArgs.addAll([term, term, term, term]);
    }

    if (statusFilters != null && statusFilters.isNotEmpty) {
      final placeholders = List.filled(statusFilters.length, '?').join(', ');
      whereClauses.add('p.status IN ($placeholders)');
      whereArgs.addAll(statusFilters);
    }

    if (barangayFilters != null && barangayFilters.isNotEmpty) {
      final placeholders = List.filled(barangayFilters.length, '?').join(', ');
      whereClauses.add('p.barangay IN ($placeholders)');
      whereArgs.addAll(barangayFilters);
    }

    if (paymentTypeFilters != null && paymentTypeFilters.isNotEmpty) {
      final placeholders = List.filled(paymentTypeFilters.length, '?').join(', ');
      whereClauses.add('p.payment_type IN ($placeholders)');
      whereArgs.addAll(paymentTypeFilters);
    }

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    
    final sql = '''
      SELECT p.*, (SELECT COUNT(*) FROM delivery_attempts WHERE package_id = p.id) as attempt_count
      FROM packages p
      $whereString
      ORDER BY p.sort_order ASC, p.created_at DESC
    ''';

    final result = await db.rawQuery(sql, whereArgs);
    return result.map((map) {
      final attempts = map['attempt_count'] as int? ?? 0;
      return Package.fromMap(map, attempts: attempts);
    }).toList();
  }
}
