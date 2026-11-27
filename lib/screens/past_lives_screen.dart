import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';
import '../services/sound_service.dart';
import '../theme/omori_theme.dart';
import '../widgets/sketchy_widgets.dart';
import 'roadmap_screen.dart';

class PastLivesScreen extends StatefulWidget {
  const PastLivesScreen({super.key});

  @override
  State<PastLivesScreen> createState() => _PastLivesScreenState();
}

class _PastLivesScreenState extends State<PastLivesScreen> {
  List<PastLifeSummary> _lives = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lives = await DatabaseHelper.instance.getCompletedPastLives();
    if (!mounted) return;
    setState(() {
      _lives = lives;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmoriColors.whiteSpace,
      appBar: AppBar(
        backgroundColor: OmoriColors.whiteSpace,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OmoriColors.ink),
          onPressed: SoundService.withUiSound(
            UiSound.back,
            () => Navigator.pop(context),
          ),
        ),
        title: Text('PAST LIVES ALBUM', style: OmoriTheme.pixel(size: 22)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: OmoriColors.ink,
                ),
              )
            : _lives.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: SketchBox(
                    fillColor: OmoriColors.warmPaper,
                    child: Text(
                      'No completed lives yet.\n\nFinish raising yourself to unlock your first Memory Timeline.',
                      textAlign: TextAlign.center,
                      style: OmoriTheme.hand(
                        size: 18,
                        color: OmoriColors.mutedInk,
                      ),
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                itemCount: _lives.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = _lives[index];
                  final achieved = item.roadmap?.dreamAchieved ?? false;
                  return GestureDetector(
                    onTap: () {
                      SoundService.playUi(UiSound.memory);
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              RoadmapScreen(sessionId: item.session.sessionId!),
                        ),
                      );
                    },
                    child: SketchBox(
                      fillColor: achieved
                          ? OmoriColors.pastelLavender
                          : OmoriColors.paper,
                      borderColor: achieved
                          ? OmoriColors.dreamIndigo
                          : OmoriColors.ink,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.player.name,
                                style: OmoriTheme.hand(
                                  size: 22,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                color: achieved
                                    ? OmoriColors.dreamIndigo
                                    : OmoriColors.ink,
                                child: Text(
                                  achieved
                                      ? 'DREAM ACHIEVED'
                                      : 'DREAM UNFULFILLED',
                                  style: OmoriTheme.pixel(
                                    size: 14,
                                    color: OmoriColors.paper,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AGE 0 → ${item.session.targetAge}  •  ${item.decisionCount} MEMORIES',
                            style: OmoriTheme.pixel(
                              size: 15,
                              color: OmoriColors.mutedInk,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${item.player.dreamSelfSummary}"',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: OmoriTheme.hand(
                              size: 16,
                              color: OmoriColors.mutedInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
