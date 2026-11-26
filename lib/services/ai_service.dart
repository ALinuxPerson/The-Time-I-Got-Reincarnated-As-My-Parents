import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class DecisionAnalysisResult {
  final String childReaction;
  final String interpretation;
  final String mood; // neutral | happy | anxious | sad | proud | quiet
  final int happinessDelta;
  final int healthDelta;
  final int smartsDelta;
  final int ambitionDelta;

  const DecisionAnalysisResult({
    required this.childReaction,
    required this.interpretation,
    required this.mood,
    this.happinessDelta = 0,
    this.healthDelta = 0,
    this.smartsDelta = 0,
    this.ambitionDelta = 0,
  });
}

class StoryRoadmapResult {
  final String endingType; // 'dream_achieved' | 'dream_not_achieved'
  final String generatedStory;
  final String moralReflection;
  final Map<int, String> eventSummariesByDecisionId;

  const StoryRoadmapResult({
    required this.endingType,
    required this.generatedStory,
    required this.moralReflection,
    required this.eventSummariesByDecisionId,
  });
}

class AiService {
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static String? runtimeApiKey;

  static String get activeApiKey {
    final runtime = runtimeApiKey?.trim();
    if (runtime != null && runtime.isNotEmpty) return runtime;
    return _envApiKey.trim();
  }

  static bool get hasApiKey => activeApiKey.isNotEmpty;

  final http.Client _client;

  AiService({http.Client? client}) : _client = client ?? http.Client();

  Future<DecisionAnalysisResult> analyzeDecision({
    required Player player,
    required Scenario scenario,
    required String choiceText,
    required int ageAtDecision,
    required List<DecisionWithDetails> priorDecisions,
  }) async {
    if (hasApiKey) {
      try {
        final priorSummary = priorDecisions.isEmpty
            ? 'None yet.'
            : priorDecisions
                  .map(
                    (d) =>
                        '- Age ${d.decision.ageAtDecision} (${d.scenario.theme}): '
                        'Parent chose "${d.decision.choiceText}". '
                        'Impact: ${d.analysis?.interpretation ?? ''}',
                  )
                  .join('\n');

        final sexContext =
            (player.sex != 'Unspecified' && player.sex != 'Prefer not to say')
            ? ' (${player.sex})'
            : '';

        final prompt = '''
You are the quiet, bittersweet narrative engine of an OMORI-inspired life-choice game called "The Time I Got Reincarnated As My Parents".
The player died at age ${player.age}, wishing they had become: "${player.dreamSelfSummary}".
They were reincarnated as their own parents and are raising "${player.name}"$sexContext from infancy up to age ${player.age}.

Current milestone:
- Child age: $ageAtDecision (${scenario.ageStage})
- Theme: ${scenario.theme}
- Scenario: ${scenario.title} — ${scenario.description}
- Parent's decision: "$choiceText"

Prior parenting history:
$priorSummary

Return STRICT JSON with exactly these keys:
{
  "child_reaction": "1-2 short evocative sentences showing how young ${player.name} visibly reacts right now (BitLife life-log style, grounded and emotional, no melodrama).",
  "interpretation": "2 concise sentences analyzing the psychological trade-off of this parenting choice and how it subtly nudges ${player.name} toward or away from their dream self.",
  "mood": "one of: neutral, happy, anxious, sad, proud, quiet",
  "happiness_delta": integer between -15 and 15,
  "health_delta": integer between -15 and 15,
  "smarts_delta": integer between -15 and 15,
  "ambition_delta": integer between -15 and 15
}
''';

        final jsonMap = await _callGeminiJson(prompt);
        final reaction = (jsonMap['child_reaction'] as String?)?.trim();
        final interpretation = (jsonMap['interpretation'] as String?)?.trim();
        final mood = _sanitizeMood(jsonMap['mood'] as String?);
        if (reaction != null &&
            reaction.isNotEmpty &&
            interpretation != null &&
            interpretation.isNotEmpty) {
          return DecisionAnalysisResult(
            childReaction: reaction,
            interpretation: interpretation,
            mood: mood,
            happinessDelta: _clampDelta(jsonMap['happiness_delta']),
            healthDelta: _clampDelta(jsonMap['health_delta']),
            smartsDelta: _clampDelta(jsonMap['smarts_delta']),
            ambitionDelta: _clampDelta(jsonMap['ambition_delta']),
          );
        }
      } catch (_) {
        // Fall through gracefully to offline analysis.
      }
    }

    return _offlineAnalyzeDecision(
      player: player,
      scenario: scenario,
      choiceText: choiceText,
      ageAtDecision: ageAtDecision,
    );
  }

  Future<StoryRoadmapResult> generateStoryRoadmap({
    required Player player,
    required int targetAge,
    required List<DecisionWithDetails> decisions,
  }) async {
    if (hasApiKey) {
      try {
        final timelineText = decisions
            .map(
              (d) =>
                  'decision_id=${d.decision.decisionId} | Age ${d.decision.ageAtDecision} (${d.scenario.title}, ${d.scenario.theme}): '
                  'Parent chose "${d.decision.choiceText}". '
                  'Child reaction: "${d.analysis?.childReaction ?? ''}". '
                  'Analysis: "${d.analysis?.interpretation ?? ''}".',
            )
            .join('\n');

        final sexContext =
            (player.sex != 'Unspecified' && player.sex != 'Prefer not to say')
            ? ' (${player.sex})'
            : '';

        final prompt = '''
You are the narrative engine of an OMORI-inspired game: "The Time I Got Reincarnated As My Parents".
The player died at age $targetAge wishing they had become: "${player.dreamSelfSummary}".
They reincarnated as their own parents and raised "${player.name}"$sexContext from birth up to age $targetAge.

Full parenting timeline:
$timelineText

Decide holistically whether ${player.name} achieved their dream self ("dream_achieved") or did not ("dream_not_achieved") by age $targetAge — be honest and nuanced, recognizing that both strictness and warmth have trade-offs.
Regardless of the ending, at age $targetAge the exact same fatal crosswalk accident happens again.
The core moral lesson of the game is: living your life to the fullest, despite knowing how it all ends.
- If "dream_achieved": emphasize that even though you could not outrun the ending at the crosswalk, you didn't waste a single year — you helped ${player.name} truly live before the rain fell.
- If "dream_not_achieved": emphasize that the ending arrived anyway, even when fear and hesitation held ${player.name} back — reminding the player that when you know how it all ends, the only real loss is not living fully while you have the chance.

Return STRICT JSON with this exact schema:
{
  "ending_type": "dream_achieved" or "dream_not_achieved",
  "generated_story": "3-4 poignant, grounded sentences summarizing who ${player.name} became by age $targetAge because of these choices, right up to the rainy crosswalk.",
  "moral_reflection": "2-3 gentle, unforgettable OMORI-toned sentences delivering the moral lesson for this ending.",
  "events": [
    { "decision_id": 1, "event_summary": "1 concise poetic sentence linking this childhood moment to the person ${player.name} became." }
  ]
}
''';

        final jsonMap = await _callGeminiJson(prompt);
        final rawEnding = (jsonMap['ending_type'] as String?)?.trim();
        final endingType = rawEnding == 'dream_achieved'
            ? 'dream_achieved'
            : 'dream_not_achieved';
        final generatedStory = (jsonMap['generated_story'] as String?)?.trim();
        final moralReflection =
            (jsonMap['moral_reflection'] as String?)?.trim();
        final rawEvents = jsonMap['events'] as List<dynamic>? ?? [];

        final summaries = <int, String>{};
        for (final item in rawEvents) {
          if (item is Map<String, dynamic>) {
            final id = item['decision_id'];
            final summary = item['event_summary']?.toString().trim();
            if (id is int && summary != null && summary.isNotEmpty) {
              summaries[id] = summary;
            }
          }
        }

        if (generatedStory != null &&
            generatedStory.isNotEmpty &&
            moralReflection != null &&
            moralReflection.isNotEmpty) {
          for (final d in decisions) {
            summaries.putIfAbsent(
              d.decision.decisionId!,
              () =>
                  d.analysis?.interpretation ??
                  'A quiet turning point at age ${d.decision.ageAtDecision}.',
            );
          }
          return StoryRoadmapResult(
            endingType: endingType,
            generatedStory: generatedStory,
            moralReflection: moralReflection,
            eventSummariesByDecisionId: summaries,
          );
        }
      } catch (_) {
        // Fall through gracefully to offline generator.
      }
    }

    return _offlineGenerateRoadmap(
      player: player,
      targetAge: targetAge,
      decisions: decisions,
    );
  }

  Future<Map<String, dynamic>> _callGeminiJson(String prompt) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-2.5-flash:generateContent?key=$activeApiKey',
    );

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'temperature': 0.8,
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Empty Gemini response');
    }
    final text =
        candidates.first['content']['parts'][0]['text'] as String? ?? '';
    final cleaned = text
        .replaceAll(RegExp(r'^```json\s*'), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  String _sanitizeMood(String? raw) {
    const allowed = {'neutral', 'happy', 'anxious', 'sad', 'proud', 'quiet'};
    final normalized = raw?.toLowerCase().trim() ?? 'neutral';
    return allowed.contains(normalized) ? normalized : 'neutral';
  }

  int _clampDelta(dynamic raw) {
    if (raw is int) return raw.clamp(-15, 15);
    if (raw is num) return raw.round().clamp(-15, 15);
    return 0;
  }

  // --- OFFLINE FALLBACK ENGINE ---

  DecisionAnalysisResult _offlineAnalyzeDecision({
    required Player player,
    required Scenario scenario,
    required String choiceText,
    required int ageAtDecision,
  }) {
    final lower = choiceText.toLowerCase();

    final isWarm = RegExp(
      r'hug|hold|rock|listen|warm|love|apolog|celebrate|star|admire|proud|support|soup|towel|honest|talk|sit beside|fruit|back their|come home|courage',
    ).hasMatch(lower);
    final isStrict = RegExp(
      r'strict|ground|confiscat|tutor|scrub|discipline|firm|rules|practical|push hard|explode|snap|insist|guilt',
    ).hasMatch(lower);
    final isDistant = RegExp(
      r'leave|step back|shrug|pretend|let it go|thumbs-up|distract|alone|silence',
    ).hasMatch(lower);
    final isStudyOrDream = RegExp(
      r'study|tutor|practice|plan|workshop|leap|dream|foundation|breakthrough|pivot',
    ).hasMatch(lower);
    final isRestOrCare = RegExp(
      r'rest|sleep|soup|towel|home|fruit|health|bed|rock',
    ).hasMatch(lower);

    if (isWarm && !isStrict) {
      return DecisionAnalysisResult(
        childReaction:
            'At age $ageAtDecision, ${player.name} exhales slowly and looks up at you — the tightness in their shoulders fades, even if only for tonight.',
        interpretation:
            'You chose presence over perfection during "${scenario.title}". Warmth builds a safe harbor for ${player.name}, though shelter alone cannot always toughen them for the world outside.',
        mood: 'happy',
        happinessDelta: 10,
        healthDelta: isRestOrCare ? 8 : 4,
        smartsDelta: isStudyOrDream ? 6 : 2,
        ambitionDelta: isStudyOrDream ? 8 : 3,
      );
    }

    if (isStrict) {
      return DecisionAnalysisResult(
        childReaction:
            '${player.name} lowers their eyes and nods stiffly. They obey, though something small and unspoken retreats behind their expression.',
        interpretation:
            'In "${scenario.title}", fear for their future guided your hand toward discipline. Structure can forge capability toward "${player.dreamSelfSummary}", yet it often leaves a quiet distance between parent and child.',
        mood: 'anxious',
        happinessDelta: -8,
        healthDelta: -4,
        smartsDelta: 9,
        ambitionDelta: 10,
      );
    }

    if (isDistant) {
      return DecisionAnalysisResult(
        childReaction:
            '${player.name} lingers for a second as if waiting for one more word, then turns quietly back to their own world.',
        interpretation:
            'Giving space during "${scenario.title}" spared them suffocation, teaching self-reliance — though in the silence, ${player.name} sometimes wondered whether you noticed how much they needed you.',
        mood: 'quiet',
        happinessDelta: -3,
        healthDelta: isRestOrCare ? 5 : -2,
        smartsDelta: 3,
        ambitionDelta: -4,
      );
    }

    return DecisionAnalysisResult(
      childReaction:
          '${player.name} takes your words in silently, filing the moment away in the quiet way children remember everything.',
      interpretation:
          'Your choice in "${scenario.title}" carried both hope and hesitation — a deeply human compromise while trying to guide ${player.name} toward "${player.dreamSelfSummary}".',
      mood: 'neutral',
      happinessDelta: 3,
      healthDelta: 2,
      smartsDelta: 4,
      ambitionDelta: 4,
    );
  }

  StoryRoadmapResult _offlineGenerateRoadmap({
    required Player player,
    required int targetAge,
    required List<DecisionWithDetails> decisions,
  }) {
    int warmCount = 0;
    int strictCount = 0;
    int balancedCount = 0;

    for (final d in decisions) {
      final mood = d.analysis?.mood ?? 'neutral';
      if (mood == 'happy' || mood == 'proud') {
        warmCount++;
      } else if (mood == 'anxious' || mood == 'sad') {
        strictCount++;
      } else {
        balancedCount++;
      }
    }

    // Achieve the dream when there is consistent care and balance rather than
    // extremes or neglect.
    final total = decisions.isEmpty ? 1 : decisions.length;
    final warmRatio = warmCount / total;
    final strictRatio = strictCount / total;
    final dreamAchieved =
        warmRatio >= 0.45 && strictRatio <= 0.4 && (warmCount + balancedCount) >= (total * 0.6);

    final endingType =
        dreamAchieved ? 'dream_achieved' : 'dream_not_achieved';

    final generatedStory = dreamAchieved
        ? 'By age $targetAge, ${player.name} had grown into the very person you once ached to be — "${player.dreamSelfSummary}". Every late-night worry, every quiet sacrifice, and every imperfect hug had braided together into a life they were genuinely proud to stand inside. And yet, on an ordinary rainy evening, the crosswalk light flickered just the same.'
        : 'By age $targetAge, ${player.name} had not become "${player.dreamSelfSummary}". Even with your memories of the future, every protective rule cost a little courage, and every gentle mercy left an unguarded edge. They grew into someone real, flawed, and still figuring it out — right up until the rain began to fall on that familiar crosswalk.';

    final moralReflection = dreamAchieved
        ? 'Even knowing how it all ends, you didn’t let fear steal the years in between. You couldn’t stop the rain at the crosswalk — but you proved that a life lived fully is never wasted, no matter how soon the light turns.'
        : 'The rain at the crosswalk came anyway, no matter how carefully you tried to brace for it. Knowing how it all ends shouldn’t make you shrink back from life — it’s the very reason to live every single day to the fullest while you’re here.';

    final summaries = <int, String>{};
    for (final d in decisions) {
      summaries[d.decision.decisionId!] =
          d.analysis?.interpretation ??
          'At age ${d.decision.ageAtDecision}, your choice in "${d.scenario.title}" left a quiet mark on ${player.name}.';
    }

    return StoryRoadmapResult(
      endingType: endingType,
      generatedStory: generatedStory,
      moralReflection: moralReflection,
      eventSummariesByDecisionId: summaries,
    );
  }
}
