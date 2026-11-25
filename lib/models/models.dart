import 'dart:convert';

class Player {
  final int? playerId;
  final String name;
  final int age;
  final String dreamSelfSummary;
  final DateTime createdAt;

  const Player({
    this.playerId,
    required this.name,
    required this.age,
    required this.dreamSelfSummary,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    if (playerId != null) 'player_id': playerId,
    'name': name,
    'age': age,
    'dream_self_summary': dreamSelfSummary,
    'created_at': createdAt.toIso8601String(),
  };

  factory Player.fromMap(Map<String, Object?> map) => Player(
    playerId: map['player_id'] as int?,
    name: map['name'] as String,
    age: map['age'] as int,
    dreamSelfSummary: map['dream_self_summary'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}

class GameSession {
  final int? sessionId;
  final int playerId;
  final int targetAge;
  final String status; // 'in_progress' | 'completed'
  final int currentAge;
  final int happiness;
  final int health;
  final int smarts;
  final int ambition;
  final DateTime createdAt;
  final DateTime? completedAt;

  const GameSession({
    this.sessionId,
    required this.playerId,
    required this.targetAge,
    required this.status,
    this.currentAge = 0,
    this.happiness = 50,
    this.health = 50,
    this.smarts = 50,
    this.ambition = 50,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'completed';

  GameSession copyWith({
    int? currentAge,
    int? happiness,
    int? health,
    int? smarts,
    int? ambition,
    String? status,
    DateTime? completedAt,
  }) => GameSession(
    sessionId: sessionId,
    playerId: playerId,
    targetAge: targetAge,
    status: status ?? this.status,
    currentAge: currentAge ?? this.currentAge,
    happiness: happiness ?? this.happiness,
    health: health ?? this.health,
    smarts: smarts ?? this.smarts,
    ambition: ambition ?? this.ambition,
    createdAt: createdAt,
    completedAt: completedAt ?? this.completedAt,
  );

  Map<String, Object?> toMap() => {
    if (sessionId != null) 'session_id': sessionId,
    'player_id': playerId,
    'target_age': targetAge,
    'status': status,
    'current_age': currentAge,
    'happiness': happiness,
    'health': health,
    'smarts': smarts,
    'ambition': ambition,
    'created_at': createdAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };

  factory GameSession.fromMap(Map<String, Object?> map) => GameSession(
    sessionId: map['session_id'] as int?,
    playerId: map['player_id'] as int,
    targetAge: map['target_age'] as int,
    status: map['status'] as String,
    currentAge: (map['current_age'] as int?) ?? 0,
    happiness: (map['happiness'] as int?) ?? 50,
    health: (map['health'] as int?) ?? 50,
    smarts: (map['smarts'] as int?) ?? 50,
    ambition: (map['ambition'] as int?) ?? 50,
    createdAt: DateTime.parse(map['created_at'] as String),
    completedAt: map['completed_at'] != null
        ? DateTime.parse(map['completed_at'] as String)
        : null,
  );
}

class Scenario {
  final int? scenarioId;
  final String title;
  final String description;
  final String ageStage;
  final String theme;
  final int minAge;
  final int maxAge;
  final List<String> presetChoices;

  const Scenario({
    this.scenarioId,
    required this.title,
    required this.description,
    required this.ageStage,
    required this.theme,
    required this.minAge,
    required this.maxAge,
    required this.presetChoices,
  });

  Map<String, Object?> toMap() => {
    if (scenarioId != null) 'scenario_id': scenarioId,
    'title': title,
    'description': description,
    'age_stage': ageStage,
    'theme': theme,
    'min_age': minAge,
    'max_age': maxAge,
    'preset_choices': jsonEncode(presetChoices),
  };

  factory Scenario.fromMap(Map<String, Object?> map) {
    final rawChoices = map['preset_choices'] as String;
    final decoded = (jsonDecode(rawChoices) as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    return Scenario(
      scenarioId: map['scenario_id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      ageStage: map['age_stage'] as String,
      theme: map['theme'] as String,
      minAge: map['min_age'] as int,
      maxAge: map['max_age'] as int,
      presetChoices: decoded,
    );
  }
}

class Decision {
  final int? decisionId;
  final int sessionId;
  final int scenarioId;
  final String choiceText;
  final int ageAtDecision;
  final DateTime createdAt;

  const Decision({
    this.decisionId,
    required this.sessionId,
    required this.scenarioId,
    required this.choiceText,
    required this.ageAtDecision,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    if (decisionId != null) 'decision_id': decisionId,
    'session_id': sessionId,
    'scenario_id': scenarioId,
    'choice_text': choiceText,
    'age_at_decision': ageAtDecision,
    'created_at': createdAt.toIso8601String(),
  };

  factory Decision.fromMap(Map<String, Object?> map) => Decision(
    decisionId: map['decision_id'] as int?,
    sessionId: map['session_id'] as int,
    scenarioId: map['scenario_id'] as int,
    choiceText: map['choice_text'] as String,
    ageAtDecision: map['age_at_decision'] as int,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}

class AiAnalysis {
  final int? analysisId;
  final int decisionId;
  final String interpretation;
  final String childReaction;
  final String mood; // 'neutral' | 'happy' | 'anxious' | 'sad' | 'proud' | 'quiet'
  final int happinessDelta;
  final int healthDelta;
  final int smartsDelta;
  final int ambitionDelta;

  const AiAnalysis({
    this.analysisId,
    required this.decisionId,
    required this.interpretation,
    required this.childReaction,
    this.mood = 'neutral',
    this.happinessDelta = 0,
    this.healthDelta = 0,
    this.smartsDelta = 0,
    this.ambitionDelta = 0,
  });

  Map<String, Object?> toMap() => {
    if (analysisId != null) 'analysis_id': analysisId,
    'decision_id': decisionId,
    'interpretation': interpretation,
    'child_reaction': childReaction,
    'mood': mood,
    'happiness_delta': happinessDelta,
    'health_delta': healthDelta,
    'smarts_delta': smartsDelta,
    'ambition_delta': ambitionDelta,
  };

  factory AiAnalysis.fromMap(Map<String, Object?> map) => AiAnalysis(
    analysisId: map['analysis_id'] as int?,
    decisionId: map['decision_id'] as int,
    interpretation: map['interpretation'] as String,
    childReaction: map['child_reaction'] as String,
    mood: (map['mood'] as String?) ?? 'neutral',
    happinessDelta: (map['happiness_delta'] as int?) ?? 0,
    healthDelta: (map['health_delta'] as int?) ?? 0,
    smartsDelta: (map['smarts_delta'] as int?) ?? 0,
    ambitionDelta: (map['ambition_delta'] as int?) ?? 0,
  );
}

class StoryRoadmap {
  final int? roadmapId;
  final int sessionId;
  final String generatedStory;
  final String endingType; // 'dream_achieved' | 'dream_not_achieved'
  final String moralReflection;
  final DateTime createdAt;

  const StoryRoadmap({
    this.roadmapId,
    required this.sessionId,
    required this.generatedStory,
    required this.endingType,
    required this.moralReflection,
    required this.createdAt,
  });

  bool get dreamAchieved => endingType == 'dream_achieved';

  Map<String, Object?> toMap() => {
    if (roadmapId != null) 'roadmap_id': roadmapId,
    'session_id': sessionId,
    'generated_story': generatedStory,
    'ending_type': endingType,
    'moral_reflection': moralReflection,
    'created_at': createdAt.toIso8601String(),
  };

  factory StoryRoadmap.fromMap(Map<String, Object?> map) => StoryRoadmap(
    roadmapId: map['roadmap_id'] as int?,
    sessionId: map['session_id'] as int,
    generatedStory: map['generated_story'] as String,
    endingType: map['ending_type'] as String,
    moralReflection: map['moral_reflection'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}

class StoryEvent {
  final int? eventId;
  final int roadmapId;
  final int decisionId;
  final int sequenceOrder;
  final String eventSummary;

  const StoryEvent({
    this.eventId,
    required this.roadmapId,
    required this.decisionId,
    required this.sequenceOrder,
    required this.eventSummary,
  });

  Map<String, Object?> toMap() => {
    if (eventId != null) 'event_id': eventId,
    'roadmap_id': roadmapId,
    'decision_id': decisionId,
    'sequence_order': sequenceOrder,
    'event_summary': eventSummary,
  };

  factory StoryEvent.fromMap(Map<String, Object?> map) => StoryEvent(
    eventId: map['event_id'] as int?,
    roadmapId: map['roadmap_id'] as int,
    decisionId: map['decision_id'] as int,
    sequenceOrder: map['sequence_order'] as int,
    eventSummary: map['event_summary'] as String,
  );
}

/// Composite models for UI consumption.
class DecisionWithDetails {
  final Decision decision;
  final Scenario scenario;
  final AiAnalysis? analysis;

  const DecisionWithDetails({
    required this.decision,
    required this.scenario,
    this.analysis,
  });
}

class StoryEventWithDetails {
  final StoryEvent event;
  final DecisionWithDetails decisionDetails;

  const StoryEventWithDetails({
    required this.event,
    required this.decisionDetails,
  });
}

class FullRoadmapView {
  final Player player;
  final GameSession session;
  final StoryRoadmap roadmap;
  final List<StoryEventWithDetails> events;

  const FullRoadmapView({
    required this.player,
    required this.session,
    required this.roadmap,
    required this.events,
  });
}

class PastLifeSummary {
  final GameSession session;
  final Player player;
  final StoryRoadmap? roadmap;
  final int decisionCount;

  const PastLifeSummary({
    required this.session,
    required this.player,
    this.roadmap,
    required this.decisionCount,
  });
}
