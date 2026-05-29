import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/ticket_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('event_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tickets (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        eventId TEXT NOT NULL,
        zoneId TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT,
        status TEXT NOT NULL,
        basePrice REAL NOT NULL,
        gstAmount REAL NOT NULL,
        totalAmount REAL NOT NULL,
        qrHash TEXT NOT NULL,
        isScanned INTEGER NOT NULL,
        lastScannedAt TEXT,
        createdAt TEXT NOT NULL,
        eventName TEXT,
        zoneName TEXT,
        zoneType TEXT,
        eventVenue TEXT
      )
    ''');
  }

  Future<void> saveTickets(List<TicketModel> tickets) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var ticket in tickets) {
      batch.insert(
        'tickets',
        ticket.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<TicketModel>> getCachedTickets(String userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'tickets',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) {
      // Map raw SQL fields back to format expected by TicketModel.fromJson
      final jsonMap = Map<String, dynamic>.from(map);
      // SQLite returns integer for boolean, but TicketModel.fromJson handles boolean
      jsonMap['isScanned'] = map['isScanned'] == 1;
      // Database saved key as "id" but fromJson checks "_id" or "id"
      jsonMap['_id'] = map['id'];
      return TicketModel.fromJson(jsonMap);
    }).toList();
  }

  Future<void> clearTickets() async {
    final db = await instance.database;
    await db.delete('tickets');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
