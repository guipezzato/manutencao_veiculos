import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart'; // 👈 CORRIGIDO: Agora termina com .dart corretamente

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB('manutencao.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Subimos para a versão 2 para atualizar o banco existente
      onCreate: (db, version) async {
        // Tabela de Manutenções
        await db.execute('''
          CREATE TABLE manutencoes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            veiculo TEXT,
            descricao TEXT,
            data TEXT,
            custo REAL,
            km INTEGER,
            status TEXT
          )
        ''');

        // Tabela de Veículos
        await db.execute('''
          CREATE TABLE IF NOT EXISTS veiculo (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            placa TEXT NOT NULL UNIQUE,
            valor_ipva REAL NOT NULL,
            pago_ipva INTEGER NOT NULL,
            status_licenciamento TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS veiculo (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nome TEXT NOT NULL,
              placa TEXT NOT NULL UNIQUE,
              valor_ipva REAL NOT NULL,
              pago_ipva INTEGER NOT NULL,
              status_licenciamento TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }
}