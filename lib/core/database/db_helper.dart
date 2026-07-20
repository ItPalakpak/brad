import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';

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
  final String? signaturePath;
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
    this.signaturePath,
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
      signaturePath: map['signature_path'] as String?,
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
      'signature_path': signaturePath,
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
    String? signaturePath,
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
      signaturePath: signaturePath ?? this.signaturePath,
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

class ReceiverArchive {
  final String id;
  final String name;
  final String? phone;
  final String? street;
  final String? zone;
  final String? barangay;
  final String? city;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReceiverArchive({
    required this.id,
    required this.name,
    this.phone,
    this.street,
    this.zone,
    this.barangay,
    this.city,
    required this.lat,
    required this.lng,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReceiverArchive.fromMap(Map<String, dynamic> map) {
    return ReceiverArchive(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      street: map['street'] as String?,
      zone: map['zone'] as String?,
      barangay: map['barangay'] as String?,
      city: map['city'] as String?,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'street': street,
      'zone': zone,
      'barangay': barangay,
      'city': city,
      'lat': lat,
      'lng': lng,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CustomPerimeter {
  final String id;
  final String name;
  final List<LatLng> points;
  final DateTime createdAt;

  CustomPerimeter({
    required this.id,
    required this.name,
    required this.points,
    required this.createdAt,
  });

  factory CustomPerimeter.fromMap(Map<String, dynamic> map) {
    final pointsJson = jsonDecode(map['points'] as String) as List<dynamic>;
    final points = pointsJson.map((p) {
      final list = p as List<dynamic>;
      return LatLng((list[0] as num).toDouble(), (list[1] as num).toDouble());
    }).toList();

    return CustomPerimeter(
      id: map['id'] as String,
      name: map['name'] as String,
      points: points,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final pointsJson = points.map((p) => [p.latitude, p.longitude]).toList();
    return {
      'id': id,
      'name': name,
      'points': jsonEncode(pointsJson),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// --- DATABASE HELPER ---

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;
  // BUG-14 FIX: Completer prevents race condition during concurrent database initialization
  static Completer<Database>? _initCompleter;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<Database>();
    try {
      _database = await _initDB('ridertrack.db');
      _initCompleter!.complete(_database!);
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    // BUG-25 FIX: Backup database before opening/upgrading
    final file = File(path);
    if (await file.exists()) {
      try {
        final backupPath = '$path.bak';
        await file.copy(backupPath);
        debugPrint('Database backup created successfully at $backupPath');
      } catch (e) {
        debugPrint('Error creating database backup: $e');
      }
    }

    return await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _safeExecute(Database db, String sql, String stepDesc) async {
    try {
      await db.execute(sql);
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('duplicate') || err.contains('already exists')) {
        debugPrint('Migration info ($stepDesc): $e');
      } else {
        debugPrint('Migration warning/error ($stepDesc): $e');
      }
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion...');
    if (oldVersion < 2) {
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN photo_path TEXT', 'v2 add photo_path');
    }
    if (oldVersion < 3) {
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN delivery_photo_path TEXT', 'v3 add delivery_photo_path');
    }
    if (oldVersion < 4) {
      await _safeExecute(db, '''
        CREATE TABLE IF NOT EXISTS rides (
          id TEXT PRIMARY KEY,
          ride_number INTEGER NOT NULL,
          date TEXT NOT NULL,
          started_at TEXT NOT NULL,
          ended_at TEXT
        )
      ''', 'v4 create rides table');
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN ride_id TEXT REFERENCES rides(id)', 'v4 add ride_id');
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN rescheduled_date TEXT', 'v4 add rescheduled_date');
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN rejection_reason TEXT', 'v4 add rejection_reason');
      await _safeExecute(db, 'CREATE INDEX IF NOT EXISTS idx_rides_date ON rides(date)', 'v4 create rides index');
      await _safeExecute(db, 'CREATE INDEX IF NOT EXISTS idx_packages_ride_id ON packages(ride_id)', 'v4 create packages index');
    }
    if (oldVersion < 5) {
      // Self-healing migration for version 5: ensures everything is properly declared
      await _safeExecute(db, '''
        CREATE TABLE IF NOT EXISTS rides (
          id TEXT PRIMARY KEY,
          ride_number INTEGER NOT NULL,
          date TEXT NOT NULL,
          started_at TEXT NOT NULL,
          ended_at TEXT
        )
      ''', 'v5 create rides table self-heal');
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN photo_path TEXT', 'v5 add photo_path self-heal');
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN delivery_photo_path TEXT', 'v5 add delivery_photo_path self-heal');
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN ride_id TEXT REFERENCES rides(id)', 'v5 add ride_id self-heal');
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN rescheduled_date TEXT', 'v5 add rescheduled_date self-heal');
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN rejection_reason TEXT', 'v5 add rejection_reason self-heal');
      await _safeExecute(db, 'CREATE INDEX IF NOT EXISTS idx_rides_date ON rides(date)', 'v5 create rides index self-heal');
      await _safeExecute(db, 'CREATE INDEX IF NOT EXISTS idx_packages_ride_id ON packages(ride_id)', 'v5 create packages index self-heal');
    }
    if (oldVersion < 6) {
      await _safeExecute(db, '''
        CREATE TABLE IF NOT EXISTS receiver_archives (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT,
          street TEXT,
          zone TEXT,
          barangay TEXT,
          city TEXT,
          lat REAL NOT NULL,
          lng REAL NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''', 'v6 create receiver_archives');
      await _safeExecute(db, 'CREATE INDEX IF NOT EXISTS idx_receiver_archives_phone ON receiver_archives(phone);', 'v6 create archive phone index');
      await _safeExecute(db, 'CREATE INDEX IF NOT EXISTS idx_receiver_archives_name ON receiver_archives(name);', 'v6 create archive name index');

      // Migrate existing packages with coordinates
      try {
        final List<Map<String, dynamic>> packages = await db.query(
          'packages',
          where: 'lat IS NOT NULL AND lng IS NOT NULL AND receiver_name IS NOT NULL AND receiver_name != ""',
        );
        final now = DateTime.now().toIso8601String();
        for (final pkg in packages) {
          final name = pkg['receiver_name'] as String;
          final phone = pkg['receiver_phone'] as String?;
          final street = pkg['street'] as String?;
          final zone = pkg['zone'] as String?;
          final barangay = pkg['barangay'] as String?;
          final city = pkg['city'] as String?;
          final lat = pkg['lat'] as double;
          final lng = pkg['lng'] as double;

          List<Map<String, dynamic>> existing;
          if (phone != null && phone.trim().isNotEmpty) {
            existing = await db.query(
              'receiver_archives',
              where: 'phone = ?',
              whereArgs: [phone.trim()],
            );
          } else {
            existing = await db.query(
              'receiver_archives',
              where: 'name = ?',
              whereArgs: [name.trim()],
            );
          }

          if (existing.isEmpty) {
            await db.insert('receiver_archives', {
              'id': pkg['id'] as String,
              'name': name.trim(),
              'phone': phone?.trim(),
              'street': street?.trim(),
              'zone': zone?.trim(),
              'barangay': barangay?.trim(),
              'city': city?.trim(),
              'lat': lat,
              'lng': lng,
              'created_at': now,
              'updated_at': now,
            });
          }
        }
      } catch (e) {
        debugPrint('Migration error running v6 data migration: $e');
      }
    }
    if (oldVersion < 7) {
      await _safeExecute(db, '''
        CREATE TABLE IF NOT EXISTS custom_perimeters (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          points TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''', 'v7 create custom_perimeters');
    }
    if (oldVersion < 8) {
      await _safeExecute(db, '''
        CREATE TABLE IF NOT EXISTS ride_locations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ride_id TEXT NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
          lat REAL NOT NULL,
          lng REAL NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''', 'v8 create ride_locations');
      await _safeExecute(db, 'CREATE INDEX IF NOT EXISTS idx_ride_locations_ride_id ON ride_locations(ride_id);', 'v8 create locations index');
    }
    if (oldVersion < 9) {
      await _safeExecute(db, 'ALTER TABLE packages ADD COLUMN signature_path TEXT', 'v9 add signature_path');
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
        signature_path TEXT,
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

    await db.execute('''
      CREATE TABLE receiver_archives (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        street TEXT,
        zone TEXT,
        barangay TEXT,
        city TEXT,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_receiver_archives_phone ON receiver_archives(phone);');
    await db.execute('CREATE INDEX idx_receiver_archives_name ON receiver_archives(name);');

    await db.execute('''
      CREATE TABLE custom_perimeters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        points TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ride_locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ride_id TEXT NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_ride_locations_ride_id ON ride_locations(ride_id);');
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
    final result = await db.insert('packages', p.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);

    if (p.lat != null && p.lng != null && p.receiverName != null && p.receiverName!.trim().isNotEmpty) {
      await upsertReceiverArchive(
        name: p.receiverName!,
        phone: p.receiverPhone,
        street: p.street,
        zone: p.zone,
        barangay: p.barangay,
        city: p.city,
        lat: p.lat!,
        lng: p.lng!,
      );
    }

    return result;
  }

  Future<int> updatePackage(Package package) async {
    final db = await database;
    final p = package.copyWith(updatedAt: DateTime.now());
    final result = await db.update(
      'packages',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [package.id],
    );

    if (p.lat != null && p.lng != null && p.receiverName != null && p.receiverName!.trim().isNotEmpty) {
      await upsertReceiverArchive(
        name: p.receiverName!,
        phone: p.receiverPhone,
        street: p.street,
        zone: p.zone,
        barangay: p.barangay,
        city: p.city,
        lat: p.lat!,
        lng: p.lng!,
      );
    }

    return result;
  }

  Future<int> deletePackage(String id) async {
    final db = await database;
    return await db.delete(
      'packages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // BUG-11 FIX: Capture timestamp once before loop for consistency
  Future<void> updateSortOrders(List<String> orderedIds) async {
    final db = await database;
    final batch = db.batch();
    final nowStr = DateTime.now().toIso8601String();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(
        'packages',
        {'sort_order': i, 'updated_at': nowStr},
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

  Future<List<String>> getTodayUniqueBarangays() async {
    final db = await database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      '''SELECT DISTINCT barangay FROM packages 
         WHERE barangay IS NOT NULL AND barangay != "" 
         AND (
           status = 'pending' OR
           created_at LIKE ? OR
           delivered_at LIKE ? OR
           ride_id IN (SELECT id FROM rides WHERE date = ?)
         )
         ORDER BY barangay ASC''',
      ['$todayStr%', '$todayStr%', todayStr]
    );
    return result.map((r) => r['barangay'] as String).toList();
  }

  Future<List<String>> getTodayUniqueStreets() async {
    final db = await database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      '''SELECT DISTINCT street FROM packages 
         WHERE street IS NOT NULL AND street != "" 
         AND (
           status = 'pending' OR
           created_at LIKE ? OR
           delivered_at LIKE ? OR
           ride_id IN (SELECT id FROM rides WHERE date = ?)
         )
         ORDER BY street ASC''',
      ['$todayStr%', '$todayStr%', todayStr]
    );
    return result.map((r) => r['street'] as String).toList();
  }

  Future<List<String>> getTodayUniqueZones() async {
    final db = await database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      '''SELECT DISTINCT zone FROM packages 
         WHERE zone IS NOT NULL AND zone != "" 
         AND (
           status = 'pending' OR
           created_at LIKE ? OR
           delivered_at LIKE ? OR
           ride_id IN (SELECT id FROM rides WHERE date = ?)
         )
         ORDER BY zone ASC''',
      ['$todayStr%', '$todayStr%', todayStr]
    );
    return result.map((r) => r['zone'] as String).toList();
  }

  Future<List<String>> getTodayUniqueCities() async {
    final db = await database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      '''SELECT DISTINCT city FROM packages 
         WHERE city IS NOT NULL AND city != "" 
         AND (
           status = 'pending' OR
           created_at LIKE ? OR
           delivered_at LIKE ? OR
           ride_id IN (SELECT id FROM rides WHERE date = ?)
         )
         ORDER BY city ASC''',
      ['$todayStr%', '$todayStr%', todayStr]
    );
    return result.map((r) => r['city'] as String).toList();
  }

  Future<List<String>> getTodayUniqueStatuses() async {
    final db = await database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      '''SELECT DISTINCT status FROM packages 
         WHERE status IS NOT NULL AND status != "" 
         AND (
           status = 'pending' OR
           created_at LIKE ? OR
           delivered_at LIKE ? OR
           ride_id IN (SELECT id FROM rides WHERE date = ?)
         )
         ORDER BY status ASC''',
      ['$todayStr%', '$todayStr%', todayStr]
    );
    return result.map((r) => r['status'] as String).toList();
  }

  Future<List<String>> getTodayUniquePaymentTypes() async {
    final db = await database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      '''SELECT DISTINCT payment_type FROM packages 
         WHERE payment_type IS NOT NULL AND payment_type != "" 
         AND (
           status = 'pending' OR
           created_at LIKE ? OR
           delivered_at LIKE ? OR
           ride_id IN (SELECT id FROM rides WHERE date = ?)
         )
         ORDER BY payment_type ASC''',
      ['$todayStr%', '$todayStr%', todayStr]
    );
    return result.map((r) => r['payment_type'] as String).toList();
  }

  // --- CRUD ATTEMPTS ---

  Future<int> insertAttempt(DeliveryAttempt attempt) async {
    final db = await database;
    return await db.insert('delivery_attempts', attempt.toMap());
  }

  Future<void> deleteLastAttempt(String packageId) async {
    final db = await database;
    await db.rawDelete(
      'DELETE FROM delivery_attempts WHERE id = (SELECT id FROM delivery_attempts WHERE package_id = ? ORDER BY attempted_at DESC LIMIT 1)',
      [packageId],
    );
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

  // --- CRUD RECEIVER ARCHIVES ---

  // CHANGED: Helper to normalize names for duplicate prevention and case-insensitive OCR matching
  String _normalizeName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> upsertReceiverArchive({
    required String name,
    String? phone,
    String? street,
    String? zone,
    String? barangay,
    String? city,
    required double lat,
    required double lng,
  }) async {
    if (name.trim().isEmpty) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();

    List<Map<String, dynamic>> existing = [];
    if (phone != null && phone.trim().isNotEmpty) {
      existing = await db.query(
        'receiver_archives',
        where: 'phone = ?',
        whereArgs: [phone.trim()],
      );
    } 
    
    // BUG-09 FIX: Use SQL LOWER() query instead of O(n) full-table scan for name matching
    if (existing.isEmpty) {
      final targetNormalized = _normalizeName(name);
      if (targetNormalized.isNotEmpty) {
        existing = await db.query(
          'receiver_archives',
          where: "REPLACE(REPLACE(REPLACE(LOWER(name), ' ', ''), '-', ''), '.', '') = ?",
          whereArgs: [targetNormalized],
          limit: 1,
        );
      }
    }

    if (existing.isNotEmpty) {
      final existingId = existing.first['id'] as String;
      await db.update(
        'receiver_archives',
        {
          'name': name.trim(),
          'phone': phone?.trim(),
          'street': street?.trim(),
          'zone': zone?.trim(),
          'barangay': barangay?.trim(),
          'city': city?.trim(),
          'lat': lat,
          'lng': lng,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [existingId],
      );
    } else {
      await db.insert(
        'receiver_archives',
        {
          'id': const Uuid().v4(),
          'name': name.trim(),
          'phone': phone?.trim(),
          'street': street?.trim(),
          'zone': zone?.trim(),
          'barangay': barangay?.trim(),
          'city': city?.trim(),
          'lat': lat,
          'lng': lng,
          'created_at': now,
          'updated_at': now,
        },
      );
    }
  }

  Future<Map<String, dynamic>?> lookupReceiverArchive(String? name, String? phone) async {
    final db = await database;
    if (phone != null && phone.trim().isNotEmpty) {
      final result = await db.query(
        'receiver_archives',
        where: 'phone = ?',
        whereArgs: [phone.trim()],
        limit: 1,
      );
      if (result.isNotEmpty) return result.first;
    }
    // BUG-10 FIX: Use SQL LOWER() query instead of O(n) full-table scan for name lookup
    if (name != null && name.trim().isNotEmpty) {
      final targetNormalized = _normalizeName(name);
      if (targetNormalized.isNotEmpty) {
        final result = await db.query(
          'receiver_archives',
          where: "REPLACE(REPLACE(REPLACE(LOWER(name), ' ', ''), '-', ''), '.', '') = ?",
          whereArgs: [targetNormalized],
          limit: 1,
        );
        if (result.isNotEmpty) return result.first;
      }
    }
    return null;
  }

  Future<List<ReceiverArchive>> getAllReceiverArchives() async {
    final db = await database;
    final result = await db.query('receiver_archives');
    return result.map((map) => ReceiverArchive.fromMap(map)).toList();
  }

  // CHANGED: Added updateReceiverArchiveLocation to support updating pin coordinates of archived consignees
  Future<void> updateReceiverArchiveLocation(String id, double lat, double lng) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'receiver_archives',
      {
        'lat': lat,
        'lng': lng,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CHANGED: Added updatePackageLocationsForReceiver to update all active/pending package locations matching a receiver name and phone
  Future<void> updatePackageLocationsForReceiver(String name, String? phone, double lat, double lng) async {
    final db = await database;
    await db.update(
      'packages',
      {
        'lat': lat,
        'lng': lng,
      },
      where: 'receiver_name = ? AND (receiver_phone = ? OR receiver_phone IS NULL OR ? IS NULL)',
      whereArgs: [name, phone, phone],
    );
  }

  // CHANGED: Added findArchivesByZoneAndBarangay to locate archives in the same zone & barangay, or same barangay
  Future<List<Map<String, dynamic>>> findArchivesByZoneAndBarangay(String? zone, String? barangay) async {
    final db = await database;
    if (barangay == null || barangay.trim().isEmpty) return const [];

    final brgyLower = barangay.trim().toLowerCase();

    if (zone != null && zone.trim().isNotEmpty) {
      final zoneLower = zone.trim().toLowerCase();
      final results = await db.query(
        'receiver_archives',
        where: 'LOWER(zone) = ? AND LOWER(barangay) = ?',
        whereArgs: [zoneLower, brgyLower],
      );
      if (results.isNotEmpty) return results;
    }

    return await db.query(
      'receiver_archives',
      where: 'LOWER(barangay) = ?',
      whereArgs: [brgyLower],
    );
  }


  // --- CRUD CUSTOM PERIMETERS ---

  Future<int> insertPerimeter(CustomPerimeter perimeter) async {
    final db = await database;
    return await db.insert('custom_perimeters', perimeter.toMap());
  }

  Future<List<CustomPerimeter>> getAllPerimeters() async {
    final db = await database;
    final result = await db.query('custom_perimeters', orderBy: 'created_at DESC');
    return result.map((map) => CustomPerimeter.fromMap(map)).toList();
  }

  Future<int> deletePerimeter(String id) async {
    final db = await database;
    return await db.delete(
      'custom_perimeters',
      where: 'id = ?',
      whereArgs: [id],
    );
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
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    // Compute total Cash and total Digital and total Tips from packages where status = 'delivered'
    // CHANGED: Scoped payment summary to today's packages only to prevent showing historical totals on the packages screen
    final result = await db.rawQuery('''
      SELECT 
        SUM(cod_cash) as total_cash, 
        SUM(cod_digital) as total_digital, 
        SUM(tips) as total_tips,
        SUM(extra_amount) as total_extra
      FROM packages 
      WHERE status = 'delivered' AND (
        created_at LIKE ? OR
        delivered_at LIKE ? OR
        ride_id IN (SELECT id FROM rides WHERE date = ?)
      )
    ''', ['$todayStr%', '$todayStr%', todayStr]);
    
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

  // CHANGED: Added helper to fetch the earliest work date from packages and rides tables to determine first day of work
  Future<DateTime> getEarliestWorkDate() async {
    final db = await database;
    final pkgResult = await db.rawQuery('SELECT MIN(created_at) as min_date FROM packages');
    final rideResult = await db.rawQuery('SELECT MIN(started_at) as min_date FROM rides');
    
    DateTime? earliestPkg;
    if (pkgResult.isNotEmpty && pkgResult.first['min_date'] != null) {
      earliestPkg = DateTime.tryParse(pkgResult.first['min_date'] as String);
    }
    
    DateTime? earliestRide;
    if (rideResult.isNotEmpty && rideResult.first['min_date'] != null) {
      earliestRide = DateTime.tryParse(rideResult.first['min_date'] as String);
    }
    
    DateTime earliest = DateTime.now();
    if (earliestPkg != null && earliestPkg.isBefore(earliest)) {
      earliest = earliestPkg;
    }
    if (earliestRide != null && earliestRide.isBefore(earliest)) {
      earliest = earliestRide;
    }
    
    return DateTime(earliest.year, earliest.month, earliest.day);
  }

  Future<void> clearDeliveredPackages() async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete attempts for delivered and failed packages first to be safe (cascade should handle it, but let's be explicit)
      await txn.rawDelete('''
        DELETE FROM delivery_attempts 
        WHERE package_id IN (SELECT id FROM packages WHERE status IN ('delivered', 'failed', 'returned', 'rejected'))
      ''');
      // Delete delivered and failed packages
      await txn.delete(
        'packages',
        where: "status IN ('delivered', 'failed', 'returned', 'rejected')",
      );
    });
  }

  // BUG-26 FIX: Removed dangerous clearAllData method that had no confirmation/backup.
  // Use clearDelivered() instead which auto-backs-up before clearing.




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
      whereArgs: [rideId],
      orderBy: 'sort_order ASC',
    );
    return result.map((map) => Package.fromMap(map)).toList();
  }

  // BUG-08 FIX: Revert packages rescheduled for today or earlier (not tomorrow)
  Future<void> revertExpiredRescheduledPackages() async {
    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    final today = DateTime.now();
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    await db.update(
      'packages',
      {
        'status': 'pending',
        'updated_at': nowStr,
      },
      where: "status = 'rescheduled' AND rescheduled_date <= ?",
      whereArgs: [todayEnd],
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

  // CHANGED: Added helper to export all delivered and failed packages, their referenced rides, and delivery attempts as SQL INSERT statements
  Future<String> exportDeliveredPackagesToSql() async {
    final db = await database;
    
    final packages = await db.query(
      'packages',
      where: "status IN ('delivered', 'failed', 'returned', 'rejected')",
    );
    if (packages.isEmpty) {
      return '';
    }
    
    final List<String> sqlStatements = [];
    sqlStatements.add('-- BRAD SQL Backup Generated on ${DateTime.now().toIso8601String()}');
    
    // 1. Get all unique ride IDs referenced by these packages
    final rideIds = packages
        .map((p) => p['ride_id'])
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();
        
    if (rideIds.isNotEmpty) {
      sqlStatements.add('-- RIDES');
      final placeholders = List.filled(rideIds.length, '?').join(', ');
      final rides = await db.query('rides', where: 'id IN ($placeholders)', whereArgs: rideIds);
      for (final r in rides) {
        final id = _sqlEscape(r['id']);
        final numVal = r['ride_number'];
        final date = _sqlEscape(r['date']);
        final started = _sqlEscape(r['started_at']);
        final ended = _sqlEscape(r['ended_at']);
        sqlStatements.add(
          "INSERT OR REPLACE INTO rides (id, ride_number, date, started_at, ended_at) VALUES ($id, $numVal, $date, $started, $ended);"
        );
      }
    }
    
    // 2. Get packages SQL
    sqlStatements.add('-- PACKAGES');
    for (final p in packages) {
      final id = _sqlEscape(p['id']);
      final trk = _sqlEscape(p['tracking_number']);
      final name = _sqlEscape(p['receiver_name']);
      final phone = _sqlEscape(p['receiver_phone']);
      final notes = _sqlEscape(p['notes']);
      final lat = p['lat'] ?? 'NULL';
      final lng = p['lng'] ?? 'NULL';
      final street = _sqlEscape(p['street']);
      final zone = _sqlEscape(p['zone']);
      final barangay = _sqlEscape(p['barangay']);
      final city = _sqlEscape(p['city']);
      final ptype = _sqlEscape(p['payment_type']);
      final codCash = p['cod_cash'] ?? 0.0;
      final codDigital = p['cod_digital'] ?? 0.0;
      final tips = p['tips'] ?? 0.0;
      final extraAmt = p['extra_amount'] ?? 0.0;
      final extraLbl = _sqlEscape(p['extra_label']);
      final status = _sqlEscape(p['status']);
      final sortOrder = p['sort_order'] ?? 0;
      final created = _sqlEscape(p['created_at']);
      final updated = _sqlEscape(p['updated_at']);
      final delivered = _sqlEscape(p['delivered_at']);
      final photo = _sqlEscape(p['photo_path']);
      final delPhoto = _sqlEscape(p['delivery_photo_path']);
      final rideId = _sqlEscape(p['ride_id']);
      final resched = _sqlEscape(p['rescheduled_date']);
      final reject = _sqlEscape(p['rejection_reason']);
      
      sqlStatements.add(
        "INSERT OR REPLACE INTO packages (id, tracking_number, receiver_name, receiver_phone, notes, lat, lng, street, zone, barangay, city, payment_type, cod_cash, cod_digital, tips, extra_amount, extra_label, status, sort_order, created_at, updated_at, delivered_at, photo_path, delivery_photo_path, ride_id, rescheduled_date, rejection_reason) VALUES ($id, $trk, $name, $phone, $notes, $lat, $lng, $street, $zone, $barangay, $city, $ptype, $codCash, $codDigital, $tips, $extraAmt, $extraLbl, $status, $sortOrder, $created, $updated, $delivered, $photo, $delPhoto, $rideId, $resched, $reject);"
      );
    }
    
    // 3. Get all delivery attempts for these packages
    final packageIds = packages.map((p) => p['id'] as String).toList();
    if (packageIds.isNotEmpty) {
      sqlStatements.add('-- DELIVERY_ATTEMPTS');
      final placeholders = List.filled(packageIds.length, '?').join(', ');
      final attempts = await db.query('delivery_attempts', where: 'package_id IN ($placeholders)', whereArgs: packageIds);
      for (final a in attempts) {
        final id = a['id'];
        final pkgId = _sqlEscape(a['package_id']);
        final attemptStatus = _sqlEscape(a['status']);
        final notes = _sqlEscape(a['notes']);
        final attemptedAt = _sqlEscape(a['attempted_at']);
        sqlStatements.add(
          "INSERT OR REPLACE INTO delivery_attempts (id, package_id, status, notes, attempted_at) VALUES ($id, $pkgId, $attemptStatus, $notes, $attemptedAt);"
        );
      }
    }
    
    // BUG-18 FIX: Include receiver_archives in backup to preserve the rider's address book
    sqlStatements.add('-- RECEIVER_ARCHIVES');
    final archives = await db.query('receiver_archives');
    for (final a in archives) {
      final id = _sqlEscape(a['id']);
      final aName = _sqlEscape(a['name']);
      final aPhone = _sqlEscape(a['phone']);
      final aStreet = _sqlEscape(a['street']);
      final aZone = _sqlEscape(a['zone']);
      final aBrgy = _sqlEscape(a['barangay']);
      final aCity = _sqlEscape(a['city']);
      final aLat = a['lat'] ?? 'NULL';
      final aLng = a['lng'] ?? 'NULL';
      final aCreated = _sqlEscape(a['created_at']);
      final aUpdated = _sqlEscape(a['updated_at']);
      sqlStatements.add(
        "INSERT OR REPLACE INTO receiver_archives (id, name, phone, street, zone, barangay, city, lat, lng, created_at, updated_at) VALUES ($id, $aName, $aPhone, $aStreet, $aZone, $aBrgy, $aCity, $aLat, $aLng, $aCreated, $aUpdated);"
      );
    }

    // BUG-18 FIX: Include custom_perimeters in backup to preserve custom map zones
    sqlStatements.add('-- CUSTOM_PERIMETERS');
    final perimeters = await db.query('custom_perimeters');
    for (final cp in perimeters) {
      final cpId = _sqlEscape(cp['id']);
      final cpName = _sqlEscape(cp['name']);
      final cpPoints = _sqlEscape(cp['points']);
      final cpCreated = _sqlEscape(cp['created_at']);
      sqlStatements.add(
        "INSERT OR REPLACE INTO custom_perimeters (id, name, points, created_at) VALUES ($cpId, $cpName, $cpPoints, $cpCreated);"
      );
    }

    return sqlStatements.join('\n');
  }

  String _sqlEscape(dynamic value) {
    if (value == null) return 'NULL';
    final str = value.toString().replaceAll("'", "''");
    return "'$str'";
  }

  // BUG-13 FIX: Added validation to prevent SQL injection from malformed backup files.
  // Only allows INSERT OR REPLACE INTO known tables.
  static const _allowedTables = {'packages', 'rides', 'delivery_attempts', 'receiver_archives', 'custom_perimeters', 'ride_locations'};

  Future<void> executeSqlScript(String script) async {
    final db = await database;
    final lines = script.split('\n');
    await db.transaction((txn) async {
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('--')) continue;
        // Only allow INSERT OR REPLACE INTO <known_table>
        final upper = trimmed.toUpperCase();
        if (!upper.startsWith('INSERT ')) continue;
        // Validate target table is in our allowlist
        final tableMatch = RegExp(r'INSERT\s+OR\s+REPLACE\s+INTO\s+(\w+)', caseSensitive: false).firstMatch(trimmed);
        if (tableMatch == null) continue;
        final tableName = tableMatch.group(1)!.toLowerCase();
        if (!_allowedTables.contains(tableName)) {
          debugPrint('SQL restore: skipping disallowed table "$tableName"');
          continue;
        }
        // Reject statements containing multiple SQL commands (semicolon injection)
        final semiCount = trimmed.split(';').where((s) => s.trim().isNotEmpty).length;
        if (semiCount > 1) {
          debugPrint('SQL restore: skipping multi-statement line');
          continue;
        }
        await txn.execute(trimmed);
      }
    });
  }

  // CHANGED: Added helper to insert a location trace point for a ride (Strava-style tracking)
  Future<int> insertRideLocation(String rideId, double lat, double lng) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('ride_locations', {
      'ride_id': rideId,
      'lat': lat,
      'lng': lng,
      'timestamp': now,
    });
  }

  // CHANGED: Added helper to fetch all recorded location trace points for a ride (Strava-style tracking)
  Future<List<LatLng>> getRideLocations(String rideId) async {
    final db = await database;
    final result = await db.query(
      'ride_locations',
      where: 'ride_id = ?',
      whereArgs: [rideId],
      orderBy: 'timestamp ASC',
    );
    return result.map((r) => LatLng(r['lat'] as double, r['lng'] as double)).toList();
  }

  // CHANGED: Added helper to fetch all recorded location trace points with timestamps for a ride (Strava-style tracking)
  Future<List<Map<String, dynamic>>> getRideLocationsWithTimestamps(String rideId) async {
    final db = await database;
    return await db.query(
      'ride_locations',
      where: 'ride_id = ?',
      whereArgs: [rideId],
      orderBy: 'timestamp ASC',
    );
  }
}
