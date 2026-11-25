import '../models/models.dart';

/// Curated bank of grounded parenting scenarios spanning life stages.
/// Every option represents a real parenting trade-off — no cartoonish villains.
const List<Scenario> seedScenarios = [
  Scenario(
    title: 'The 3:00 AM Crying',
    description:
        'You have work in three hours. Your infant self will not stop crying in the crib — fed, changed, just terrified of the dark.',
    ageStage: 'Infancy',
    theme: 'Attachment',
    minAge: 1,
    maxAge: 2,
    presetChoices: [
      'Pick them up and rock them until dawn, even if you collapse tomorrow.',
      'Sit beside the crib humming quietly without picking them up, teaching self-soothing.',
      'Leave the hallway light cracked and step out so you can rest enough to provide.',
      'Bring them into your bed and whisper promises that you will never let them fall.',
    ],
  ),
  Scenario(
    title: 'Crayon on the Living Room Wall',
    description:
        'You walk in to find a sprawling, crooked drawing of a house and stars scribbled across the newly painted wall. They hold up the red crayon, beaming.',
    ageStage: 'Early Childhood',
    theme: 'Curiosity',
    minAge: 3,
    maxAge: 5,
    presetChoices: [
      'Kneel down, ask them to explain the drawing, and tape butcher paper over the wall.',
      'Firmly hand them a sponge and make them scrub it off so they learn boundaries.',
      'Take a photo of it quietly, sigh, and paint over it after they fall asleep.',
      'Snap out of exhaustion about the rent deposit, then feel a pang of guilt immediately.',
    ],
  ),
  Scenario(
    title: 'Clinging at the School Gate',
    description:
        'First day of school. Their fingers lock around your sleeve like a vise as other children walk inside. The teacher waits patiently.',
    ageStage: 'Early Childhood',
    theme: 'Independence',
    minAge: 5,
    maxAge: 6,
    presetChoices: [
      'Crouch to eye level, draw a tiny star on their wrist, and promise to be first at pickup.',
      'Gently pry their fingers loose and tell them to be brave — everyone has to grow up.',
      'Stay by the classroom window for the first hour until they stop looking back.',
      'Promise them their favorite treat after school if they walk in without crying.',
    ],
  ),
  Scenario(
    title: 'The Second-Place Ribbon',
    description:
        'They practiced for weeks for the school contest, tripped at the finish, and came home holding a crinkled participation ribbon, eyes red.',
    ageStage: 'Childhood',
    theme: 'Failure',
    minAge: 7,
    maxAge: 9,
    presetChoices: [
      'Hang the ribbon on the fridge anyway and celebrate that they had the courage to try.',
      'Review what went wrong together and set up a stricter practice schedule for next year.',
      'Tell them contests are unfair anyway and distract them with ice cream.',
      'Sit beside them in silence until they are ready to talk, without trying to fix it.',
    ],
  ),
  Scenario(
    title: 'The Uninvited Birthday',
    description:
        'Half the class went to a classmate’s birthday party. Your child wasn’t invited. They pretend not to care while staring at the floor.',
    ageStage: 'Childhood',
    theme: 'Friendship',
    minAge: 8,
    maxAge: 10,
    presetChoices: [
      'Take the afternoon off and turn it into an unforgettable "just us" adventure.',
      'Gently ask if anything happened at school and coach them on making kinder friends.',
      'Tell them not everyone will like them in life, and that being independent is better.',
      'Call the other parent to ask what happened, risking embarrassing your child.',
    ],
  ),
  Scenario(
    title: 'The Folded Report Card',
    description:
        'You find a crumpled report card at the bottom of their backpack — failing grades in the subject you always wished you had mastered.',
    ageStage: 'Pre-Teen',
    theme: 'Academics',
    minAge: 11,
    maxAge: 12,
    presetChoices: [
      'Take away their free time and hire a tutor — their future depends on discipline now.',
      'Ask why they felt afraid to show it to you before even looking at the grades.',
      'Sit at the kitchen table every night to study alongside them, even when you’re tired.',
      'Shrug it off and tell them grades don’t define their worth, hoping they’ll find their own drive.',
    ],
  ),
  Scenario(
    title: 'The Locked Bedroom Door',
    description:
        'Lately the bedroom door stays shut. You knock and hear a sharp "Leave me alone!" followed by muffled music.',
    ageStage: 'Pre-Teen',
    theme: 'Boundaries',
    minAge: 12,
    maxAge: 13,
    presetChoices: [
      'Respect the closed door and slip a plate of sliced fruit outside with a tiny note.',
      'Insist the door stays open — you cannot protect them if you don’t know what’s inside.',
      'Knock again calmly and say you’ll be in the living room whenever they want to talk.',
      'Let it go and retreat to your own room, remembering how suffocating your own parents felt.',
    ],
  ),
  Scenario(
    title: 'The Midnight Sketchbook',
    description:
        'You catch them awake at 2:00 AM pouring their soul into a creative passion instead of studying for tomorrow’s exam.',
    ageStage: 'Teenager',
    theme: 'Identity',
    minAge: 14,
    maxAge: 15,
    presetChoices: [
      'Close the notebook gently and tell them dreams need a stable foundation first.',
      'Sit beside them, admire what they made, and help them plan how to chase it seriously.',
      'Tell them to sleep now, but secretly sign them up for a weekend workshop in it.',
      'Confiscate it until exams are over — you’ve seen how hard the world is on dreamers.',
    ],
  ),
  Scenario(
    title: 'Past Curfew in the Rain',
    description:
        'It is 1:15 AM. Your phone has no replies. Then the front door clicks open — soaked sneakers, smelling faintly of reckless freedom.',
    ageStage: 'Teenager',
    theme: 'Freedom',
    minAge: 15,
    maxAge: 16,
    presetChoices: [
      'Throw a dry towel over their shoulders first, then have an honest talk about fear and trust.',
      'Ground them for a month — rules exist because the world is not forgiving.',
      'Explode in panic about how terrified you were, your voice shaking with unspoken dread.',
      'Pretend you were asleep so you don’t start another war under this roof.',
    ],
  ),
  Scenario(
    title: 'The Quiet Heartbreak',
    description:
        'They come home and collapse onto the couch, staring at the ceiling after their first real heartbreak or betrayal by a best friend.',
    ageStage: 'Teenager',
    theme: 'Vulnerability',
    minAge: 16,
    maxAge: 17,
    presetChoices: [
      'Make warm soup, sit beside them, and share a story of a time your own heart broke.',
      'Tell them they’re too young to let someone else derail their focus and goals.',
      'Hold them while they cry without offering a single piece of advice.',
      'Encourage them to channel the pain into becoming stronger and never relying on anyone.',
    ],
  ),
  Scenario(
    title: 'The Fork in the Road',
    description:
        'Graduation looms. They want to take a risky leap toward something uncertain; the safe, practical path is sitting right on the table.',
    ageStage: 'Young Adult',
    theme: 'Ambition',
    minAge: 18,
    maxAge: 19,
    presetChoices: [
      'Back their risky leap wholeheartedly — you refuse to let them live with your old regrets.',
      'Push hard for the practical path; love sometimes means being the bad guy who keeps them safe.',
      'Propose a compromise: build a safety net first, then chase the dream with both feet.',
      'Tell them it’s their life now and step back completely, refusing to tip the scale.',
    ],
  ),
  Scenario(
    title: 'The Empty Chair at Dinner',
    description:
        'They’ve moved out or grown busy with their own life. Calls get shorter. Tonight they cancel dinner again because "work is crazy."',
    ageStage: 'Young Adult',
    theme: 'Distance',
    minAge: 20,
    maxAge: 23,
    presetChoices: [
      'Reply warmly that you’re proud of how hard they’re working and freeze their portion.',
      'Be honest that you miss them terribly and ask to carve out one real hour this week.',
      'Guilt-trip them subtly about how much you sacrificed so they could get here.',
      'Hide your ache behind a quick thumbs-up, telling yourself distance means you raised them right.',
    ],
  ),
  Scenario(
    title: 'The 11:00 PM Burnout Call',
    description:
        'They call late at night, voice cracking. They feel like a fraud, exhausted, wondering if they wasted their years chasing the wrong thing.',
    ageStage: 'Adulthood',
    theme: 'Resilience',
    minAge: 24,
    maxAge: 30,
    presetChoices: [
      'Tell them to come home for the weekend — no questions, no expectations, just rest.',
      'Remind them of every hard thing they’ve survived and urge them not to quit right before a breakthrough.',
      'Admit that you never figured life out either, and that it’s okay to start over.',
      'Help them write a concrete plan to pivot, staying calm and practical through their tears.',
    ],
  ),
  Scenario(
    title: 'The Unspoken Apology',
    description:
        'Over coffee, they bring up a childhood moment you barely remember — something small you did out of stress that left a lasting scar.',
    ageStage: 'Adulthood',
    theme: 'Legacy',
    minAge: 31,
    maxAge: 60,
    presetChoices: [
      'Apologize without a single excuse — validate their memory and ask how you can do better now.',
      'Explain how exhausted and scared you were back then, hoping they’ll finally understand.',
      'Get defensive about everything you sacrificed, then fall into a heavy, regretful silence.',
      'Take their hand and say you were only a beginner at being a parent, and you love them fiercely.',
    ],
  ),
];
