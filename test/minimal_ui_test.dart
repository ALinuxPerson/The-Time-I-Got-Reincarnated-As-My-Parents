import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

import 'package:the_time_i_got_reincarnated_as_my_parents/data/database_helper.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/main.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/screens/game_screen.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/screens/ending_screen.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/screens/onboarding_screen.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/services/sound_service.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/theme/omori_theme.dart';
import 'package:the_time_i_got_reincarnated_as_my_parents/widgets/sketchy_widgets.dart';

Future<void> settleData(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  const directory = String.fromEnvironment('UI_SCREENSHOTS');
  if (directory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$directory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    SoundService.enabled = false;
    OmoriTheme.useSystemFallbackFonts = false;
    final hand = FontLoader('PatrickHand')
      ..addFont(
        rootBundle.load('assets/fonts/patrick-hand/PatrickHand-Regular.ttf'),
      );
    final pixel = FontLoader('VT323')
      ..addFont(rootBundle.load('assets/fonts/vt323/VT323-Regular.ttf'));
    await Future.wait([hand.load(), pixel.load()]);
  });

  group('Minimal game interface', () {
    late DatabaseHelper db;
    setUp(() {
      db = DatabaseHelper.forTest(factory: databaseFactoryFfiNoIsolate);
      DatabaseHelper.instance = db;
    });
    tearDown(() => db.close());

    for (final size in [
      const Size(320, 568),
      const Size(360, 640),
      const Size(1280, 720),
      const Size(1920, 1080),
    ]) {
      testWidgets('title, form and game fit ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.reset);
        await tester.runAsync(() => db.database);
        await tester.pumpWidget(
          const RepaintBoundary(
            key: ValueKey('capture'),
            child: ReincarnatedAsParentsApp(),
          ),
        );
        await settleData(tester);
        for (final label in ['New life', 'Memories', 'Settings']) {
          final button = find.ancestor(
            of: find.text(label),
            matching: find.byType(SketchButton),
          );
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
        await capture(tester, 'title_${size.width.toInt()}');
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: OmoriTheme.build(),
              home: const OnboardingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Begin'));
        expect(tester.takeException(), isNull);

        final session = await tester.runAsync(() async {
          final player = await db.createPlayer(
            name: 'Sunny',
            age: 21,
            dreamSelfSummary: 'An artist who is kind to themselves',
          );
          return db.createSession(playerId: player.playerId!, targetAge: 21);
        });
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: OmoriTheme.build(),
              home: GameScreen(sessionId: session!.sessionId!),
            ),
          ),
        );
        await settleData(tester);
        await settleData(tester);
        final typewriter = find.byType(TypewriterText);
        await tester.tapAt(tester.getTopLeft(typewriter) + const Offset(8, 8));
        await tester.pumpAndSettle();
        expect(find.text('HAPPINESS'), findsNothing);
        final panel = tester.getRect(
          find.byKey(const ValueKey('dialogue_panel')),
        );
        expect(panel.top, greaterThan(size.height * 0.60));
        expect(panel.bottom, lessThanOrEqualTo(size.height - 24));
        final menuRect = tester.getRect(
          find.byKey(const ValueKey('game_menu')),
        );
        expect(
          menuRect.width * menuRect.height / (size.width * size.height),
          lessThan(0.10),
        );
        await capture(tester, 'game_${size.width.toInt()}');
        await tester.tap(find.byKey(const ValueKey('game_menu')));
        await tester.pumpAndSettle();
        expect(find.text('HAPPINESS'), findsOneWidget);
        if (size.width >= 600) {
          await tester.drag(find.byType(Slider), const Offset(200, 0));
          await tester.pumpAndSettle();
          expect(find.text('HUD scale 130%'), findsOneWidget);
        }

        await capture(tester, 'menu_${size.width.toInt()}');
        await tester.ensureVisible(find.text('Resume'));
        await tester.tap(find.text('Resume'));
        await tester.pumpAndSettle();
        expect(find.text('HAPPINESS'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets('long ending text scrolls above a reachable continue button', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);
      final session = await tester.runAsync(() async {
        final player = await db.createPlayer(
          name: 'Sunny',
          age: 21,
          dreamSelfSummary: 'A happy artist',
        );
        final session = await db.createSession(
          playerId: player.playerId!,
          targetAge: 21,
        );
        await db.saveStoryRoadmap(
          sessionId: session.sessionId!,
          generatedStory: List.filled(
            80,
            'You kept trying, and they remembered.',
          ).join(' '),
          endingType: 'dream_achieved',
          moralReflection: 'You gave them time to grow.',
          events: [],
        );
        return session;
      });
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: OmoriTheme.build(),
          home: EndingScreen(sessionId: session!.sessionId!),
        ),
      );
      await settleData(tester);
      await tester.tapAt(
        tester.getTopLeft(find.byType(TypewriterText)) + const Offset(8, 8),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('Continue')).bottom,
        lessThanOrEqualTo(568),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('THE RAIN RETURNS'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('choice persists and is readable in the journal', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);
      final session = await tester.runAsync(() async {
        final player = await db.createPlayer(
          name: 'Sunny',
          age: 21,
          dreamSelfSummary: 'A happy artist',
        );
        return db.createSession(playerId: player.playerId!, targetAge: 21);
      });
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: OmoriTheme.build(),
          home: GameScreen(sessionId: session!.sessionId!),
        ),
      );
      await settleData(tester);
      await tester.tapAt(
        tester.getTopLeft(find.byType(TypewriterText)) + const Offset(8, 8),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('What do you do?'));
      await tester.tap(find.text('What do you do?'));
      await tester.pumpAndSettle();
      final scenarios = await tester.runAsync(
        () => db.getScenariosForTargetAge(21),
      );
      final choice = scenarios!.first.presetChoices.first;
      await tester.ensureVisible(find.text(choice));
      await tester.tap(find.text(choice));
      await settleData(tester);
      final decisions = await tester.runAsync(
        () => db.getDecisionsForSession(session.sessionId!),
      );
      expect(decisions!.single.decision.choiceText, choice);
      expect(decisions.single.analysis, isNotNull);
      await tester.tap(find.byKey(const ValueKey('game_menu')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Memories'));
      await tester.tap(find.text('Memories'));
      await tester.pumpAndSettle();
      expect(find.text(choice), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('keyboard follows authored order and activates choices', (
      tester,
    ) async {
      var chosen = '';
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: OmoriTheme.build(),
          home: Scaffold(
            body: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: SketchButton(
                      label: 'Second',
                      onPressed: () => chosen = 'second',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(0),
                    child: SketchButton(
                      label: 'First',
                      onPressed: () => chosen = 'first',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(chosen, 'first');
      expect(find.byKey(const ValueKey('selection_pointer')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(chosen, 'second');
    });
  });
}
