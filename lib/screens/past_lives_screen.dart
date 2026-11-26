import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('MEMORIES', style: OmoriTheme.pixel(size: 22)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _lives.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No memories yet.', style: OmoriTheme.hand()),
              )
            : FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _lives.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final item = _lives[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.player.name,
                          style: OmoriTheme.hand(size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.roadmap?.dreamAchieved == true
                              ? 'DREAM ACHIEVED'
                              : 'DREAM UNFULFILLED',
                          style: OmoriTheme.pixel(size: 16),
                        ),
                        Text(
                          '0-${item.session.targetAge} years · ${item.decisionCount} memories',
                          style: OmoriTheme.hand(
                            size: 16,
                            color: OmoriColors.mutedInk,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FocusTraversalOrder(
                          order: NumericFocusOrder(index.toDouble()),
                          child: SketchButton(
                            label: 'Read memories',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => RoadmapScreen(
                                  sessionId: item.session.sessionId!,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
