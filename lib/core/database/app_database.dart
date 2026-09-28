import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({Database? override, String? path})
    : _override = override,
      _path = path;

  final Database? _override;
  final String? _path;
  Database? _db;

  Future<Database> get database async {
    if (_override != null) return _override;
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = _path ?? p.join(await getDatabasesPath(), 'ofsc_inventory.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        employee_id TEXT NOT NULL,
        role TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        account_status TEXT NOT NULL,
        photo_url TEXT,
        store_json TEXT,
        projects_json TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        sku TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        minimum_stock REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        material_id INTEGER NOT NULL,
        scope_type TEXT NOT NULL,
        scope_id INTEGER NOT NULL,
        available REAL NOT NULL,
        reserved REAL NOT NULL,
        total REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        material_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        reference TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE dispatch_requests (
        id TEXT PRIMARY KEY,
        request_code TEXT NOT NULL,
        project_id INTEGER NOT NULL,
        project_name TEXT NOT NULL,
        store_id INTEGER NOT NULL,
        store_name TEXT NOT NULL,
        requested_by TEXT NOT NULL,
        requested_at TEXT NOT NULL,
        status TEXT NOT NULL,
        dispatch_code TEXT,
        remarks TEXT,
        local_id TEXT,
        sync_status TEXT NOT NULL,
        lines_json TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        parent_id TEXT NOT NULL,
        local_path TEXT NOT NULL,
        kind TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        remote_url TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE consumptions (
        id TEXT PRIMARY KEY,
        material_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        project_id INTEGER NOT NULL,
        project_name TEXT NOT NULL,
        work_task TEXT NOT NULL,
        recorded_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        remarks TEXT,
        client_transaction_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE requirements (
        id TEXT PRIMARY KEY,
        project_id INTEGER NOT NULL,
        project_name TEXT NOT NULL,
        material_id INTEGER NOT NULL,
        required_qty REAL NOT NULL,
        current_stock REAL NOT NULL,
        priority TEXT NOT NULL,
        required_date TEXT NOT NULL,
        status TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        remarks TEXT,
        client_transaction_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_read INTEGER NOT NULL,
        entity_type TEXT,
        entity_id TEXT,
        route TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_queue (
        local_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL,
        sync_status TEXT NOT NULL,
        server_id TEXT,
        last_attempt_at TEXT,
        error_message TEXT,
        idempotency_key TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
