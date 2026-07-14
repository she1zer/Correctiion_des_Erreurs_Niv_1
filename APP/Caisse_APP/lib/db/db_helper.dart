import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/caisse_operation.dart';
import '../models/fiche_controle.dart';

/// Gère la base de données SQLite locale de l'application.
/// Deux tables : operations (Livre de caisse) et fiches_controle (Fiche de contrôle).
class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  factory DBHelper() => instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'caisse_isitek.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        annee TEXT NOT NULL,
        mois TEXT NOT NULL,
        semaine TEXT NOT NULL,
        periodeDu TEXT NOT NULL,
        periodeAu TEXT NOT NULL,
        date TEXT NOT NULL,
        numPiece TEXT,
        nomPrenoms TEXT,
        detailOperation TEXT,
        entree REAL NOT NULL DEFAULT 0,
        sortie REAL NOT NULL DEFAULT 0,
        solde REAL NOT NULL DEFAULT 0,
        signataireOk INTEGER NOT NULL DEFAULT 0,
        estSoldeOuverture INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE fiches_controle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semaine TEXT NOT NULL,
        periodeDu TEXT NOT NULL,
        periodeAu TEXT NOT NULL,
        soldeTheorique REAL NOT NULL DEFAULT 0,
        soldeReel REAL NOT NULL DEFAULT 0,
        ecartAvt REAL NOT NULL DEFAULT 0,
        observations TEXT,
        ecartApt REAL NOT NULL DEFAULT 0,
        repOperationsNom TEXT,
        comptableNom TEXT,
        directionNom TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_op_annee ON operations(annee)');
    await db.execute('CREATE INDEX idx_op_mois ON operations(mois)');
    await db.execute('CREATE INDEX idx_op_semaine ON operations(semaine)');
    await db.execute('CREATE INDEX idx_op_solde ON operations(solde)');
    await db.execute('CREATE INDEX idx_op_nom ON operations(nomPrenoms)');
    await db.execute('CREATE INDEX idx_fc_semaine ON fiches_controle(semaine)');
  }

  // ----------------- CRUD : OPERATIONS (Livre de caisse) -----------------

  Future<int> insertOperation(CaisseOperation op) async {
    final db = await database;
    return await db.insert('operations', op.toMap()..remove('id'));
  }

  Future<int> updateOperation(CaisseOperation op) async {
    final db = await database;
    return await db.update(
      'operations',
      op.toMap(),
      where: 'id = ?',
      whereArgs: [op.id],
    );
  }

  Future<int> deleteOperation(int id) async {
    final db = await database;
    return await db.delete('operations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CaisseOperation>> getAllOperations() async {
    final db = await database;
    final maps = await db.query('operations', orderBy: 'date ASC, id ASC');
    return maps.map((m) => CaisseOperation.fromMap(m)).toList();
  }

  /// Récupère les opérations d'une semaine précise (par période exacte).
  Future<List<CaisseOperation>> getOperationsBySemaine({
    required String annee,
    required String mois,
    required String semaine,
  }) async {
    final db = await database;
    final maps = await db.query(
      'operations',
      where: 'annee = ? AND mois = ? AND semaine = ?',
      whereArgs: [annee, mois, semaine],
      orderBy: 'estSoldeOuverture DESC, date ASC, id ASC',
    );
    return maps.map((m) => CaisseOperation.fromMap(m)).toList();
  }

  Future<List<CaisseOperation>> getOperationsByAnnee(String annee) async {
    final db = await database;
    final maps = await db.query(
      'operations',
      where: 'annee = ?',
      whereArgs: [annee],
      orderBy: 'date ASC, id ASC',
    );
    return maps.map((m) => CaisseOperation.fromMap(m)).toList();
  }

  /// Liste distincte des années présentes dans la base.
  Future<List<String>> getAnneesDisponibles() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT annee FROM operations ORDER BY annee DESC',
    );
    return result.map((r) => r['annee'] as String).toList();
  }

  /// Liste distincte (année, mois, semaine, periodeDu, periodeAu) pour navigation.
  Future<List<Map<String, dynamic>>> getSemainesDisponibles({String? annee}) async {
    final db = await database;
    final where = annee != null ? 'WHERE annee = ?' : '';
    final args = annee != null ? [annee] : <dynamic>[];
    final result = await db.rawQuery(
      'SELECT DISTINCT annee, mois, semaine, periodeDu, periodeAu FROM operations $where ORDER BY periodeDu DESC',
      args,
    );
    return result;
  }

  /// Recherche multicritère puissante : permet de taper un solde, un nom,
  /// un numéro de pièce, une année... et de retrouver la ou les lignes complètes.
  Future<List<CaisseOperation>> rechercherOperations({
    String? texte, // recherche libre : nom, détail, n° pièce
    double? solde, // recherche exacte ou approchée sur le solde
    String? annee,
    String? mois,
    String? semaine,
  }) async {
    final db = await database;
    final List<String> conditions = [];
    final List<dynamic> args = [];

    if (texte != null && texte.trim().isNotEmpty) {
      conditions.add(
          '(nomPrenoms LIKE ? OR detailOperation LIKE ? OR numPiece LIKE ?)');
      final like = '%${texte.trim()}%';
      args.addAll([like, like, like]);
    }
    if (solde != null) {
      // tolérance pour permettre une recherche même avec arrondis
      conditions.add('ABS(solde - ?) < 0.5');
      args.add(solde);
    }
    if (annee != null && annee.isNotEmpty) {
      conditions.add('annee = ?');
      args.add(annee);
    }
    if (mois != null && mois.isNotEmpty) {
      conditions.add('mois = ?');
      args.add(mois);
    }
    if (semaine != null && semaine.isNotEmpty) {
      conditions.add('semaine = ?');
      args.add(semaine);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final maps = await db.query(
      'operations',
      where: whereClause,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => CaisseOperation.fromMap(m)).toList();
  }

  // ----------------- CRUD : FICHES DE CONTROLE -----------------

  Future<int> insertFiche(FicheControle fiche) async {
    final db = await database;
    return await db.insert('fiches_controle', fiche.toMap()..remove('id'));
  }

  Future<int> updateFiche(FicheControle fiche) async {
    final db = await database;
    return await db.update(
      'fiches_controle',
      fiche.toMap(),
      where: 'id = ?',
      whereArgs: [fiche.id],
    );
  }

  Future<int> deleteFiche(int id) async {
    final db = await database;
    return await db.delete('fiches_controle', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FicheControle>> getAllFiches() async {
    final db = await database;
    final maps = await db.query('fiches_controle', orderBy: 'periodeDu DESC');
    return maps.map((m) => FicheControle.fromMap(m)).toList();
  }

  Future<FicheControle?> getFicheBySemaine(String semaine, DateTime periodeDu) async {
    final db = await database;
    final maps = await db.query(
      'fiches_controle',
      where: 'semaine = ? AND periodeDu = ?',
      whereArgs: [semaine, periodeDu.toIso8601String()],
    );
    if (maps.isEmpty) return null;
    return FicheControle.fromMap(maps.first);
  }

  Future<List<FicheControle>> rechercherFiches({
    String? semaine,
    double? soldeTheorique,
    double? soldeReel,
  }) async {
    final db = await database;
    final List<String> conditions = [];
    final List<dynamic> args = [];

    if (semaine != null && semaine.isNotEmpty) {
      conditions.add('semaine = ?');
      args.add(semaine);
    }
    if (soldeTheorique != null) {
      conditions.add('ABS(soldeTheorique - ?) < 0.5');
      args.add(soldeTheorique);
    }
    if (soldeReel != null) {
      conditions.add('ABS(soldeReel - ?) < 0.5');
      args.add(soldeReel);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final maps = await db.query(
      'fiches_controle',
      where: whereClause,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'periodeDu DESC',
    );
    return maps.map((m) => FicheControle.fromMap(m)).toList();
  }

  /// Calcule le solde de caisse courant (dernier solde enregistré, toutes périodes confondues)
  Future<double> getDernierSolde() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT solde FROM operations ORDER BY date DESC, id DESC LIMIT 1',
    );
    if (result.isEmpty) return 0.0;
    return (result.first['solde'] as num).toDouble();
  }
}
