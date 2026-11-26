import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'scenario_seed.dart';

class DatabaseHelper {
  static const String _dbName = 'reincarnated_as_parents.db';
  static const int _dbVersion = 3;

  static DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;
  final DatabaseFactory? _customFactory;
  final String? _customPath;

  DatabaseHelper._internal()
    : _customFactory = null,
      _customPath = null;

  /// Constructor for unit tests (e.g. sqflite_common_ffi in-memory DB).
  DatabaseHelper.forTest({
    required DatabaseFactory factory,
    String path = inMemoryDatabasePath,
  }) : _customFactory = factory,
       _customPath = path;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (_customFactory != null) {
      return _customFactory.openDatabase(
        _customPath ?? inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE GAME_SESSION ADD COLUMN happiness INTEGER NOT NULL DEFAULT 50',
      );
      await db.execute(
        'ALTER TABLE GAME_SESSION ADD COLUMN health INTEGER NOT NULL DEFAULT 50',
      );
      await db.execute(
        'ALTER TABLE GAME_SESSION ADD COLUMN smarts INTEGER NOT NULL DEFAULT 50',
      );
      await db.execute(
        'ALTER TABLE GAME_SESSION ADD COLUMN ambition INTEGER NOT NULL DEFAULT 50',
      );
      await db.execute(
        'ALTER TABLE AI_ANALYSIS ADD COLUMN happiness_delta INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE AI_ANALYSIS ADD COLUMN health_delta INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE AI_ANALYSIS ADD COLUMN smarts_delta INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE AI_ANALYSIS ADD COLUMN ambition_delta INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE PLAYER ADD COLUMN sex TEXT NOT NULL DEFAULT 'Unspecified'",
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. PLAYER
    await db.execute('''
      CREATE TABLE PLAYER (
        player_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sex TEXT NOT NULL DEFAULT 'Unspecified',
        age INTEGER NOT NULL,
        dream_self_summary TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. GAME_SESSION (1:N from PLAYER)
    await db.execute('''
      CREATE TABLE GAME_SESSION (
        session_id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        target_age INTEGER NOT NULL,
        status TEXT NOT NULL,
        current_age INTEGER NOT NULL DEFAULT 0,
        happiness INTEGER NOT NULL DEFAULT 50,
        health INTEGER NOT NULL DEFAULT 50,
        smarts INTEGER NOT NULL DEFAULT 50,
        ambition INTEGER NOT NULL DEFAULT 50,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (player_id) REFERENCES PLAYER(player_id) ON DELETE CASCADE
      )
    ''');

    // 3. SCENARIO
    await db.execute('''
      CREATE TABLE SCENARIO (
        scenario_id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        age_stage TEXT NOT NULL,
        theme TEXT NOT NULL,
        min_age INTEGER NOT NULL,
        max_age INTEGER NOT NULL,
        preset_choices TEXT NOT NULL
      )
    ''');

    // 4. DECISION (1:N from GAME_SESSION, 1:N from SCENARIO)
    await db.execute('''
      CREATE TABLE DECISION (
        decision_id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        scenario_id INTEGER NOT NULL,
        choice_text TEXT NOT NULL,
        age_at_decision INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES GAME_SESSION(session_id) ON DELETE CASCADE,
        FOREIGN KEY (scenario_id) REFERENCES SCENARIO(scenario_id)
      )
    ''');

    // 5. AI_ANALYSIS (1:1 with DECISION)
    await db.execute('''
      CREATE TABLE AI_ANALYSIS (
        analysis_id INTEGER PRIMARY KEY AUTOINCREMENT,
        decision_id INTEGER NOT NULL UNIQUE,
        interpretation TEXT NOT NULL,
        child_reaction TEXT NOT NULL,
        mood TEXT NOT NULL DEFAULT 'neutral',
        happiness_delta INTEGER NOT NULL DEFAULT 0,
        health_delta INTEGER NOT NULL DEFAULT 0,
        smarts_delta INTEGER NOT NULL DEFAULT 0,
        ambition_delta INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (decision_id) REFERENCES DECISION(decision_id) ON DELETE CASCADE
      )
    ''');

    // 6. STORY_ROADMAP (1:1 with GAME_SESSION)
    await db.execute('''
      CREATE TABLE STORY_ROADMAP (
        roadmap_id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL UNIQUE,
        generated_story TEXT NOT NULL,
        ending_type TEXT NOT NULL,
        moral_reflection TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES GAME_SESSION(session_id) ON DELETE CASCADE
      )
    ''');

    // 7. STORY_EVENT (1:N from STORY_ROADMAP, references DECISION)
    await db.execute('''
      CREATE TABLE STORY_EVENT (
        event_id INTEGER PRIMARY KEY AUTOINCREMENT,
        roadmap_id INTEGER NOT NULL,
        decision_id INTEGER NOT NULL,
        sequence_order INTEGER NOT NULL,
        event_summary TEXT NOT NULL,
        FOREIGN KEY (roadmap_id) REFERENCES STORY_ROADMAP(roadmap_id) ON DELETE CASCADE,
        FOREIGN KEY (decision_id) REFERENCES DECISION(decision_id) ON DELETE CASCADE
      )
    ''');

    // Seed curated scenarios.
    final batch = db.batch();
    for (final scenario in seedScenarios) {
      batch.insert('SCENARIO', scenario.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // --- PLAYER & SESSION ---

  Future<Player> createPlayer({
    required String name,
    String sex = 'Unspecified',
    required int age,
    required String dreamSelfSummary,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final normalizedSex = sex.trim().isEmpty ? 'Unspecified' : sex.trim();
    final id = await db.insert('PLAYER', {
      'name': name.trim(),
      'sex': normalizedSex,
      'age': age,
      'dream_self_summary': dreamSelfSummary.trim(),
      'created_at': now.toIso8601String(),
    });
    return Player(
      playerId: id,
      name: name.trim(),
      sex: normalizedSex,
      age: age,
      dreamSelfSummary: dreamSelfSummary.trim(),
      createdAt: now,
    );
  }

  Future<Player?> getPlayer(int playerId) async {
    final db = await database;
    final rows = await db.query(
      'PLAYER',
      where: 'player_id = ?',
      whereArgs: [playerId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Player.fromMap(rows.first);
  }

  Future<GameSession> createSession({
    required int playerId,
    required int targetAge,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final id = await db.insert('GAME_SESSION', {
      'player_id': playerId,
      'target_age': targetAge,
      'status': 'in_progress',
      'current_age': 0,
      'created_at': now.toIso8601String(),
      'completed_at': null,
    });
    return GameSession(
      sessionId: id,
      playerId: playerId,
      targetAge: targetAge,
      status: 'in_progress',
      currentAge: 0,
      createdAt: now,
    );
  }

  Future<GameSession?> getSession(int sessionId) async {
    final db = await database;
    final rows = await db.query(
      'GAME_SESSION',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GameSession.fromMap(rows.first);
  }

  Future<GameSession?> getLatestInProgressSession() async {
    final db = await database;
    final rows = await db.query(
      'GAME_SESSION',
      where: 'status = ?',
      whereArgs: ['in_progress'],
      orderBy: 'session_id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GameSession.fromMap(rows.first);
  }

  Future<void> updateSessionProgress({
    required int sessionId,
    required int currentAge,
    required int happiness,
    required int health,
    required int smarts,
    required int ambition,
  }) async {
    final db = await database;
    await db.update(
      'GAME_SESSION',
      {
        'current_age': currentAge,
        'happiness': happiness.clamp(0, 100),
        'health': health.clamp(0, 100),
        'smarts': smarts.clamp(0, 100),
        'ambition': ambition.clamp(0, 100),
      },
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> markSessionCompleted(int sessionId, int targetAge) async {
    final db = await database;
    await db.update(
      'GAME_SESSION',
      {
        'status': 'completed',
        'current_age': targetAge,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // --- SCENARIOS ---

  /// Returns a curated, chronologically ordered list of 6–9 scenarios fitting
  /// up to [targetAge].
  Future<List<Scenario>> getScenariosForTargetAge(int targetAge) async {
    final db = await database;
    final rows = await db.query(
      'SCENARIO',
      where: 'min_age <= ?',
      whereArgs: [targetAge],
      orderBy: 'min_age ASC, scenario_id ASC',
    );
    final all = rows.map(Scenario.fromMap).toList();
    if (all.length <= 8) return all;

    // Sample evenly across life stages so the run stays 8 pivotal moments.
    final selected = <Scenario>[];
    final step = (all.length - 1) / 7.0;
    final usedIndices = <int>{};
    for (int i = 0; i < 8; i++) {
      final idx = (i * step).round().clamp(0, all.length - 1);
      if (usedIndices.add(idx)) {
        selected.add(all[idx]);
      }
    }
    return selected;
  }

  // --- DECISIONS & AI_ANALYSIS ---

  Future<Decision> insertDecision({
    required int sessionId,
    required int scenarioId,
    required String choiceText,
    required int ageAtDecision,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final id = await db.insert('DECISION', {
      'session_id': sessionId,
      'scenario_id': scenarioId,
      'choice_text': choiceText.trim(),
      'age_at_decision': ageAtDecision,
      'created_at': now.toIso8601String(),
    });
    return Decision(
      decisionId: id,
      sessionId: sessionId,
      scenarioId: scenarioId,
      choiceText: choiceText.trim(),
      ageAtDecision: ageAtDecision,
      createdAt: now,
    );
  }

  Future<AiAnalysis> insertAiAnalysis({
    required int decisionId,
    required String interpretation,
    required String childReaction,
    required String mood,
    int happinessDelta = 0,
    int healthDelta = 0,
    int smartsDelta = 0,
    int ambitionDelta = 0,
  }) async {
    final db = await database;
    final id = await db.insert('AI_ANALYSIS', {
      'decision_id': decisionId,
      'interpretation': interpretation,
      'child_reaction': childReaction,
      'mood': mood,
      'happiness_delta': happinessDelta,
      'health_delta': healthDelta,
      'smarts_delta': smartsDelta,
      'ambition_delta': ambitionDelta,
    });
    return AiAnalysis(
      analysisId: id,
      decisionId: decisionId,
      interpretation: interpretation,
      childReaction: childReaction,
      mood: mood,
      happinessDelta: happinessDelta,
      healthDelta: healthDelta,
      smartsDelta: smartsDelta,
      ambitionDelta: ambitionDelta,
    );
  }

  Future<List<DecisionWithDetails>> getDecisionsForSession(
    int sessionId,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        d.decision_id, d.session_id, d.scenario_id, d.choice_text,
        d.age_at_decision, d.created_at AS d_created_at,
        s.title, s.description, s.age_stage, s.theme, s.min_age, s.max_age, s.preset_choices,
        a.analysis_id, a.interpretation, a.child_reaction, a.mood,
        a.happiness_delta, a.health_delta, a.smarts_delta, a.ambition_delta
      FROM DECISION d
      INNER JOIN SCENARIO s ON s.scenario_id = d.scenario_id
      LEFT JOIN AI_ANALYSIS a ON a.decision_id = d.decision_id
      WHERE d.session_id = ?
      ORDER BY d.age_at_decision ASC, d.decision_id ASC
      ''',
      [sessionId],
    );

    return rows.map((row) {
      final decision = Decision(
        decisionId: row['decision_id'] as int,
        sessionId: row['session_id'] as int,
        scenarioId: row['scenario_id'] as int,
        choiceText: row['choice_text'] as String,
        ageAtDecision: row['age_at_decision'] as int,
        createdAt: DateTime.parse(row['d_created_at'] as String),
      );
      final scenario = Scenario.fromMap({
        'scenario_id': row['scenario_id'],
        'title': row['title'],
        'description': row['description'],
        'age_stage': row['age_stage'],
        'theme': row['theme'],
        'min_age': row['min_age'],
        'max_age': row['max_age'],
        'preset_choices': row['preset_choices'],
      });
      final analysis = row['analysis_id'] != null
          ? AiAnalysis(
              analysisId: row['analysis_id'] as int,
              decisionId: decision.decisionId!,
              interpretation: row['interpretation'] as String,
              childReaction: row['child_reaction'] as String,
              mood: (row['mood'] as String?) ?? 'neutral',
              happinessDelta: (row['happiness_delta'] as int?) ?? 0,
              healthDelta: (row['health_delta'] as int?) ?? 0,
              smartsDelta: (row['smarts_delta'] as int?) ?? 0,
              ambitionDelta: (row['ambition_delta'] as int?) ?? 0,
            )
          : null;
      return DecisionWithDetails(
        decision: decision,
        scenario: scenario,
        analysis: analysis,
      );
    }).toList();
  }

  // --- STORY_ROADMAP & STORY_EVENT ---

  Future<StoryRoadmap> saveStoryRoadmap({
    required int sessionId,
    required String generatedStory,
    required String endingType,
    required String moralReflection,
    required List<({int decisionId, String eventSummary})> events,
  }) async {
    final db = await database;
    final now = DateTime.now();

    late int roadmapId;
    await db.transaction((txn) async {
      roadmapId = await txn.insert('STORY_ROADMAP', {
        'session_id': sessionId,
        'generated_story': generatedStory,
        'ending_type': endingType,
        'moral_reflection': moralReflection,
        'created_at': now.toIso8601String(),
      });

      for (int i = 0; i < events.length; i++) {
        await txn.insert('STORY_EVENT', {
          'roadmap_id': roadmapId,
          'decision_id': events[i].decisionId,
          'sequence_order': i + 1,
          'event_summary': events[i].eventSummary,
        });
      }
    });

    return StoryRoadmap(
      roadmapId: roadmapId,
      sessionId: sessionId,
      generatedStory: generatedStory,
      endingType: endingType,
      moralReflection: moralReflection,
      createdAt: now,
    );
  }

  Future<FullRoadmapView?> getFullRoadmap(int sessionId) async {
    final db = await database;
    final session = await getSession(sessionId);
    if (session == null) return null;

    final player = await getPlayer(session.playerId);
    if (player == null) return null;

    final roadmapRows = await db.query(
      'STORY_ROADMAP',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (roadmapRows.isEmpty) return null;
    final roadmap = StoryRoadmap.fromMap(roadmapRows.first);

    final decisions = await getDecisionsForSession(sessionId);
    final decisionMap = {
      for (final d in decisions) d.decision.decisionId!: d,
    };

    final eventRows = await db.query(
      'STORY_EVENT',
      where: 'roadmap_id = ?',
      whereArgs: [roadmap.roadmapId],
      orderBy: 'sequence_order ASC',
    );

    final events = <StoryEventWithDetails>[];
    for (final row in eventRows) {
      final event = StoryEvent.fromMap(row);
      final details = decisionMap[event.decisionId];
      if (details != null) {
        events.add(
          StoryEventWithDetails(event: event, decisionDetails: details),
        );
      }
    }

    return FullRoadmapView(
      player: player,
      session: session,
      roadmap: roadmap,
      events: events,
    );
  }

  Future<List<PastLifeSummary>> getCompletedPastLives() async {
    final db = await database;
    final sessionRows = await db.query(
      'GAME_SESSION',
      where: 'status = ?',
      whereArgs: ['completed'],
      orderBy: 'session_id DESC',
    );

    final summaries = <PastLifeSummary>[];
    for (final row in sessionRows) {
      final session = GameSession.fromMap(row);
      final player = await getPlayer(session.playerId);
      if (player == null) continue;

      final roadmapRows = await db.query(
        'STORY_ROADMAP',
        where: 'session_id = ?',
        whereArgs: [session.sessionId],
        limit: 1,
      );
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM DECISION WHERE session_id = ?',
        [session.sessionId],
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;

      summaries.add(
        PastLifeSummary(
          session: session,
          player: player,
          roadmap: roadmapRows.isNotEmpty
              ? StoryRoadmap.fromMap(roadmapRows.first)
              : null,
          decisionCount: count,
        ),
      );
    }
    return summaries;
  }
}
