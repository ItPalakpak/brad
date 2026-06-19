import 'dart:async';
import 'dart:convert';
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
      version: 7,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN photo_path TEXT');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN delivery_photo_path TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS rides (
            id TEXT PRIMARY KEY,
            ride_number INTEGER NOT NULL,
            date TEXT NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN ride_id TEXT REFERENCES rides(id)');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN rescheduled_date TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN rejection_reason TEXT');
      } catch (_) {}
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_rides_date ON rides(date)');
      } catch (_) {}
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_ride_id ON packages(ride_id)');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      // Self-healing migration for version 5: ensures everything is properly declared
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS rides (
            id TEXT PRIMARY KEY,
            ride_number INTEGER NOT NULL,
            date TEXT NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN photo_path TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN delivery_photo_path TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN ride_id TEXT REFERENCES rides(id)');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN rescheduled_date TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN rejection_reason TEXT');
      } catch (_) {}
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_rides_date ON rides(date)');
      } catch (_) {}
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_ride_id ON packages(ride_id)');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('''
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
        ''');
      } catch (_) {}
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_receiver_archives_phone ON receiver_archives(phone);');
      } catch (_) {}
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_receiver_archives_name ON receiver_archives(name);');
      } catch (_) {}

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
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS custom_perimeters (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            points TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
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

  // --- CRUD RECEIVER ARCHIVES ---

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
    if (name != null && name.trim().isNotEmpty) {
      final result = await db.query(
        'receiver_archives',
        where: 'LOWER(name) = ?',
        whereArgs: [name.trim().toLowerCase()],
        limit: 1,
      );
      if (result.isNotEmpty) return result.first;
    }
    return null;
  }

  Future<List<ReceiverArchive>> getAllReceiverArchives() async {
    final db = await database;
    final result = await db.query('receiver_archives');
    return result.map((map) => ReceiverArchive.fromMap(map)).toList();
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

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('delivery_attempts');
    await db.delete('packages');
    await db.delete('settings');
    await db.delete('rides');
  }

  // CHANGED: Added seedTestData to seed database with packages across multiple dates and rides (including today's ride) for verification
  Future<void> seedTestData() async {
    final now = DateTime.now();
    
    // 1. Create a ride for today
    final todayRideId = 'ride_today_${now.millisecondsSinceEpoch}';
    await insertRide(Ride(
      id: todayRideId,
      rideNumber: 1,
      date: now,
      startedAt: now.subtract(const Duration(hours: 3)),
    ));
    
    // 2. Create some packages for today's ride (some delivered, some pending)
    await insertPackage(Package(
      id: 'pkg_t1_${now.millisecondsSinceEpoch}',
      trackingNumber: 'TRK-TODAY-DEL-${now.millisecondsSinceEpoch}',
      receiverName: 'Juan Dela Cruz',
      receiverPhone: '09171234567',
      street: '123 Rizal St',
      zone: 'Zone 1',
      barangay: 'Brgy 1',
      city: 'Manila',
      paymentType: 'cod_cash',
      codCash: 1250.0,
      codDigital: 0.0,
      tips: 50.0,
      extraAmount: 0.0,
      status: 'delivered',
      sortOrder: 0,
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 1)),
      deliveredAt: now.subtract(const Duration(hours: 1)),
      rideId: todayRideId,
    ));

    await insertPackage(Package(
      id: 'pkg_t2_${now.millisecondsSinceEpoch}',
      trackingNumber: 'TRK-TODAY-PEND1-${now.millisecondsSinceEpoch}',
      receiverName: 'Maria Santos',
      receiverPhone: '09187654321',
      street: '456 Bonifacio St',
      zone: 'Zone 2',
      barangay: 'Brgy 2',
      city: 'Manila',
      paymentType: 'cod_digital',
      codCash: 0.0,
      codDigital: 850.0,
      tips: 0.0,
      extraAmount: 15.0,
      extraLabel: 'Fragile handling',
      status: 'pending',
      sortOrder: 1,
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 2)),
      rideId: todayRideId,
    ));

    // 3. Create another ride today (completed)
    final todayCompletedRideId = 'ride_today_comp_${now.millisecondsSinceEpoch}';
    await insertRide(Ride(
      id: todayCompletedRideId,
      rideNumber: 2,
      date: now,
      startedAt: now.subtract(const Duration(hours: 6)),
      endedAt: now.subtract(const Duration(hours: 4)),
    ));

    await insertPackage(Package(
      id: 'pkg_t3_${now.millisecondsSinceEpoch}',
      trackingNumber: 'TRK-TODAY-DEL2-${now.millisecondsSinceEpoch}',
      receiverName: 'Pedro Penduko',
      receiverPhone: '09192223333',
      street: '789 Mabini St',
      zone: 'Zone 3',
      barangay: 'Brgy 3',
      city: 'Manila',
      paymentType: 'prepaid',
      codCash: 0.0,
      codDigital: 0.0,
      tips: 20.0,
      extraAmount: 0.0,
      status: 'delivered',
      sortOrder: 0,
      createdAt: now.subtract(const Duration(hours: 5)),
      updatedAt: now.subtract(const Duration(hours: 4)),
      deliveredAt: now.subtract(const Duration(hours: 4)),
      rideId: todayCompletedRideId,
    ));

    // 4. Create historical rides (from yesterday, 2 days ago, and 5 days ago)
    final dates = [
      now.subtract(const Duration(days: 1)),
      now.subtract(const Duration(days: 2)),
      now.subtract(const Duration(days: 5)),
    ];
    
    int index = 1;
    for (final date in dates) {
      final rideId = 'ride_hist_${index}_${now.millisecondsSinceEpoch}';
      
      await insertRide(Ride(
        id: rideId,
        rideNumber: 1,
        date: date,
        startedAt: date.add(const Duration(hours: 9)), // 9:00 AM
        endedAt: date.add(const Duration(hours: 12)), // 12:00 PM
      ));
      
      // Seed a delivered package for this historical ride
      await insertPackage(Package(
        id: 'pkg_hist_del_${index}_${now.millisecondsSinceEpoch}',
        trackingNumber: 'TRK-HIST-DEL-$index-${now.millisecondsSinceEpoch}',
        receiverName: 'Customer Historical $index',
        receiverPhone: '0915999999$index',
        street: 'Street $index',
        zone: 'Zone $index',
        barangay: 'Barangay $index',
        city: 'Quezon City',
        paymentType: 'cod_cash',
        codCash: 500.0 + (index * 100),
        codDigital: 0.0,
        tips: 10.0 * index,
        extraAmount: 0.0,
        status: 'delivered',
        sortOrder: 0,
        createdAt: date.add(const Duration(hours: 8)),
        updatedAt: date.add(const Duration(hours: 11)),
        deliveredAt: date.add(const Duration(hours: 11)),
        rideId: rideId,
      ));

      // Seed a failed/returned package for this historical ride
      await insertPackage(Package(
        id: 'pkg_hist_fail_${index}_${now.millisecondsSinceEpoch}',
        trackingNumber: 'TRK-HIST-FAIL-$index-${now.millisecondsSinceEpoch}',
        receiverName: 'Failed Customer $index',
        receiverPhone: '0915888888$index',
        street: 'Street Fail $index',
        zone: 'Zone $index',
        barangay: 'Barangay $index',
        city: 'Quezon City',
        paymentType: 'cod_cash',
        codCash: 300.0,
        codDigital: 0.0,
        tips: 0.0,
        extraAmount: 0.0,
        status: 'failed',
        sortOrder: 1,
        createdAt: date.add(const Duration(hours: 8)),
        updatedAt: date.add(const Duration(hours: 11)),
        rideId: rideId,
      ));
      
      index++;
    }
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
      whereArgs: [rideId],
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
    
    return sqlStatements.join('\n');
  }

  String _sqlEscape(dynamic value) {
    if (value == null) return 'NULL';
    final str = value.toString().replaceAll("'", "''");
    return "'$str'";
  }

  // CHANGED: Added executeSqlScript method to execute raw SQL insert statements from restored backup files
  Future<void> executeSqlScript(String script) async {
    final db = await database;
    final lines = script.split('\n');
    await db.transaction((txn) async {
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('--')) continue;
        if (trimmed.toUpperCase().startsWith('INSERT ')) {
          await txn.execute(trimmed);
        }
      }
    });
  }
}
