import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

import 'package:the_time_i_got_reincarnated_as_my_parents/data/database_helper.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/main.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/services/ai_service.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/services/sound_service.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/theme/omori_theme.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    OmoriTheme.useSystemFallbackFonts = true;
    SoundService.enabled = false;
  });

  group('SQLite 7-table ERD & Offline AI Engine', () {
    late DatabaseHelper db;

    setUp(() {
      db = DatabaseHelper.forTest(factory: databaseFactoryFfiNoIsolate);
      DatabaseHelper.instance = db;
    });

    tearDown(() async {
      await db.close();
    });

    test('creates all 7 ERD tables, seeds scenarios, and completes a full run', () async {
      final rawDb = await db.database;
      final tables = await rawDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final tableNames = tables.map((r) => r['name'] as String).toSet();

      expect(
        tableNames,
        containsAll({
          'PLAYER',
          'GAME_SESSION',
          'SCENARIO',
          'DECISION',
          'AI_ANALYSIS',
          'STORY_ROADMAP',
          'STORY_EVENT',
        }),
      );

      final player = await db.createPlayer(
        name: 'Sunny',
        age: 20,
        dreamSelfSummary: 'A gentle artist who is proud of who they are',
      );
      final session = await db.createSession(
        playerId: player.playerId!,
        targetAge: player.age,
      );

      final scenarios = await db.getScenariosForTargetAge(player.age);
      expect(scenarios.length, inInclusiveRange(6, 8));

      final ai = AiService();
      for (int i = 0; i < scenarios.length; i++) {
        final s = scenarios[i];
        final decision = await db.insertDecision(
          sessionId: session.sessionId!,
          scenarioId: s.scenarioId!,
          choiceText: s.presetChoices.first,
          ageAtDecision: i + 2,
        );
        final prior = await db.getDecisionsForSession(session.sessionId!);
        final analysisResult = await ai.analyzeDecision(
          player: player,
          scenario: s,
          choiceText: decision.choiceText,
          ageAtDecision: decision.ageAtDecision,
          priorDecisions: prior,
        );
        await db.insertAiAnalysis(
          decisionId: decision.decisionId!,
          interpretation: analysisResult.interpretation,
          childReaction: analysisResult.childReaction,
          mood: analysisResult.mood,
        );
      }

      final decisions = await db.getDecisionsForSession(session.sessionId!);
      expect(decisions.length, scenarios.length);

      final roadmapResult = await ai.generateStoryRoadmap(
        player: player,
        targetAge: session.targetAge,
        decisions: decisions,
      );
      expect(
        roadmapResult.endingType,
        anyOf('dream_achieved', 'dream_not_achieved'),
      );

      await db.saveStoryRoadmap(
        sessionId: session.sessionId!,
        generatedStory: roadmapResult.generatedStory,
        endingType: roadmapResult.endingType,
        moralReflection: roadmapResult.moralReflection,
        events: decisions
            .map(
              (d) => (
                decisionId: d.decision.decisionId!,
                eventSummary:
                    roadmapResult.eventSummariesByDecisionId[d.decision.decisionId!]!,
              ),
            )
            .toList(),
      );
      await db.markSessionCompleted(session.sessionId!, session.targetAge);

      final fullView = await db.getFullRoadmap(session.sessionId!);
      expect(fullView, isNotNull);
      expect(fullView!.events.length, scenarios.length);

      final pastLives = await db.getCompletedPastLives();
      expect(pastLives.length, 1);
      expect(pastLives.first.player.name, 'Sunny');
    });

    testWidgets('renders HomeScreen in White Space', (tester) async {
      await tester.runAsync(() async {
        await db.database;
      });
      await tester.pumpWidget(const ReincarnatedAsParentsApp());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();

      expect(find.textContaining('REINCARNATED AS'), findsOneWidget);
      expect(find.text('Begin a New Life'), findsOneWidget);
      expect(find.text('Past Lives & Memory Album'), findsOneWidget);
    });
  });
}
