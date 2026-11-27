import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';
import '../services/sound_service.dart';
import '../theme/omori_theme.dart';
import 'game_screen.dart';
import 'onboarding_screen.dart';
import 'past_lives_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _titleVolume = 0.55;
  static const _fadeSteps = 12;
  static const _fadeInterval = Duration(milliseconds: 30);

  GameSession? _inProgressSession;
  Player? _inProgressPlayer;
  int _completedCount = 0;
  bool _loading = true;
  AudioPlayer? _titleMusic;
  Future<void> _musicUpdate = Future<void>.value();
  bool _musicReady = false;
  bool _musicPlaying = false;
  ModalRoute<dynamic>? _titleRoute;
  bool _settingsOpen = false;

  bool get _appIsActive {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  bool get _shouldPlayMusic =>
      mounted &&
      _appIsActive &&
      (_settingsOpen || (_titleRoute?.isCurrent ?? true));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _titleRoute = ModalRoute.of(context);
    _syncTitleMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _syncTitleMusic();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTitleMusic();
    super.dispose();
  }

  void _syncTitleMusic() {
    // Serialize native player operations across navigation and app focus changes.
    _musicUpdate = _musicUpdate.then((_) async {
      try {
        final player = _titleMusic;
        if (!mounted) {
          _titleMusic = null;
          await player?.dispose();
        } else if (_shouldPlayMusic) {
          final music = _titleMusic ??= (AudioPlayer()..positionUpdater = null);
          if (!_musicReady) {
            await music.setReleaseMode(ReleaseMode.loop);
            await music.setSource(AssetSource('title-screen.mp3'));
            _musicReady = true;
          }
          if (_shouldPlayMusic && music.volume != _titleVolume) {
            await music.setVolume(_titleVolume);
          }
          if (_shouldPlayMusic && !_musicPlaying) {
            await music.resume();
            _musicPlaying = true;
          }
        } else if (player != null && _musicPlaying) {
          if (_appIsActive) await _fadeOutMusic(player);
          if (mounted && !_shouldPlayMusic) {
            await player.pause();
            _musicPlaying = false;
          }
        }
      } catch (error) {
        debugPrint('Title music unavailable: $error');
      }
    });
  }

  Future<void> _fadeOutMusic(AudioPlayer player) async {
    final startVolume = player.volume;
    for (var step = 1; step <= _fadeSteps; step++) {
      await Future<void>.delayed(_fadeInterval);
      if (!mounted || !_appIsActive || _shouldPlayMusic) return;
      await player.setVolume(startVolume * (1 - step / _fadeSteps));
    }
  }

  Future<void> _loadState() async {
    final db = DatabaseHelper.instance;
    final active = await db.getLatestInProgressSession();
    Player? activePlayer;
    if (active != null) {
      activePlayer = await db.getPlayer(active.playerId);
    }
    final pastLives = await db.getCompletedPastLives();

    if (!mounted) return;
    setState(() {
      _inProgressSession = active;
      _inProgressPlayer = activePlayer;
      _completedCount = pastLives.length;
      _loading = false;
    });
  }

  Future<void> _openSettings() async {
    if (_settingsOpen) return;
    _settingsOpen = true;
    try {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    } finally {
      _settingsOpen = false;
      if (mounted) _syncTitleMusic();
    }
  }

  static const _night = Color(0xFF1C1929);
  static const _paper = Color(0xFFFFF2DC);
  static const _mutedPaper = Color(0xFFE1D6C9);
  static const _sunlight = Color(0xFFFFD294);

  Future<void> _openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) await _loadState();
  }

  ButtonStyle _menuStyle(Color foreground) {
    return TextButton.styleFrom(
      enableFeedback: false,
      foregroundColor: foreground,
      backgroundColor: Colors.transparent,
      overlayColor: _sunlight,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      alignment: Alignment.centerLeft,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
    );
  }

  Widget _menuEntry(
    String label,
    VoidCallback onPressed, {
    bool primary = false,
    UiSound sound = UiSound.advance,
  }) {
    final color = primary ? _sunlight : _paper;

    return TextButton(
      onPressed: SoundService.withUiSound(sound, onPressed),
      style: _menuStyle(color),
      child: Row(
        children: [
          Icon(
            primary
                ? Icons.arrow_right_alt_rounded
                : Icons.chevron_right_rounded,
            size: 22,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: OmoriTheme.hand(
                size: 19,
                color: color,
                height: 1.15,
                weight: primary ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _inProgressSession;
    final player = _inProgressPlayer;
    final hasSavedLife = session != null && player != null;

    return Scaffold(
      backgroundColor: _night,
      body: LayoutBuilder(
        builder: (context, viewport) {
          final wide = viewport.maxWidth >= 720;
          final compact = viewport.maxHeight < 620;
          final horizontalInset = (viewport.maxWidth * 0.065).clamp(
            22.0,
            110.0,
          );
          final verticalInset = compact
              ? 18.0
              : (viewport.maxHeight * 0.065).clamp(32.0, 68.0);
          final titleSize = wide
              ? (viewport.maxHeight * 0.08).clamp(36.0, 62.0)
              : 36.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/banner.gif',
                fit: BoxFit.cover,
                alignment: Alignment(wide ? 0.18 : 0.50, 0.9),
                filterQuality: FilterQuality.none,
                excludeFromSemantics: true,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: wide
                        ? const [Color(0x651C1929), Color(0x001C1929)]
                        : [
                            Color(0xEC1C1929),
                            Color(0xBF1C1929),
                            compact ? Color(0xAE1C1929) : Color(0x141C1929),
                          ],
                    stops: wide ? const [0.12, 0.66] : const [0, 0.57, 1],
                  ),
                ),
              ),
              if (wide)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xEE1C1929),
                        Color(0xA31C1929),
                        Color(0x001C1929),
                      ],
                      stops: [0, 0.30, 0.73],
                    ),
                  ),
                ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalInset,
                    vertical: verticalInset,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 550),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: compact ? 12 : 18),
                            child: Semantics(
                              header: true,
                              child: Text(
                                'The Time I Got\nReincarnated as\nMy Parents',
                                style: OmoriTheme.hand(
                                  size: titleSize,
                                  height: 0.99,
                                  color: _paper,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'You already know how it ends.\nHow will you live the years before it?',
                            style: OmoriTheme.hand(
                              size: 15,
                              height: 1.28,
                              color: _mutedPaper,
                            ),
                          ),
                          SizedBox(height: compact ? 12 : 22),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 410),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_loading)
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.all(11),
                                      child: SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _sunlight,
                                        ),
                                      ),
                                    ),
                                  )
                                else ...[
                                  if (hasSavedLife)
                                    _menuEntry(
                                      'Continue: ${player.name} (Age ${session.currentAge} / ${session.targetAge})',
                                      () => _openScreen(
                                        GameScreen(
                                          sessionId: session.sessionId!,
                                        ),
                                      ),
                                      primary: true,
                                    ),
                                  _menuEntry(
                                    'Begin a New Life',
                                    () => _openScreen(const OnboardingScreen()),
                                    primary: !hasSavedLife,
                                  ),
                                  _menuEntry(
                                    _completedCount > 0
                                        ? 'Past Lives & Memory Album ($_completedCount)'
                                        : 'Past Lives & Memory Album',
                                    () => _openScreen(const PastLivesScreen()),
                                    sound: UiSound.memory,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 14),
                          TextButton.icon(
                            onPressed: SoundService.withUiSound(
                              UiSound.advance,
                              _openSettings,
                            ),
                            style: _menuStyle(_mutedPaper),
                            icon: const Icon(Icons.settings_outlined, size: 17),
                            label: Text(
                              'Settings',
                              style: OmoriTheme.hand(
                                size: 13,
                                color: _mutedPaper,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
