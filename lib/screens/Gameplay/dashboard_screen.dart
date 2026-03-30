import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../services/ui_asset_catalog.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import 'main_game_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.activeTabIndex = 0,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<UiAssetCatalog> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _catalogFuture = UiAssetCatalog.load();
  }

  Future<void> _openBattleHub(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MainGameScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UiAssetCatalog>(
      future: _catalogFuture,
      builder: (context, snapshot) {
        final catalog = snapshot.data;

        return Consumer<UserStatsController>(
          builder: (context, controller, _) {
            final stats = controller.stats;
            final savingsRate =
                ((stats.gold / 3400) * 100).clamp(1, 100).toDouble();
            final completion =
                ((stats.literacyPoints + stats.xp) / 2400).clamp(0.08, 1.0).toDouble();

            return Scaffold(
              backgroundColor: const Color(0xFF1A4D3D),
              bottomNavigationBar: widget.onNavSelected == null
                  ? null
                  : CustomBottomNav(
                      activeIndex: widget.activeTabIndex,
                      onSelected: widget.onNavSelected,
                    ),
              body: SafeArea(
                child: controller.isLoading || catalog == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF85EFAC),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Finance Wizard Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your offline-ready command center for balance, progress, and battles.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.78),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _GlassAssetCard(
                              title: 'Current Balance',
                              subtitle: stats.levelTitle,
                              trailing: '\$${stats.gold}',
                              imageAsset: catalog.imageForSlot('balance'),
                              onTap: () => widget.onNavSelected?.call(1),
                            ),
                            const SizedBox(height: 14),
                            _GlassProgressCard(
                              imageAsset: catalog.imageForSlot('progress'),
                              savingsRate: savingsRate,
                              completion: completion,
                            ),
                            const SizedBox(height: 14),
                            _GlassHeroCard(
                              imageAsset: catalog.imageForSlot('hero'),
                              onTap: () => _openBattleHub(context),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Quick Navigation',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _DashboardActionTile(
                                  label: 'Budget',
                                  imageAsset: catalog.imageForSlot('budget'),
                                  onTap: () => widget.onNavSelected?.call(1),
                                ),
                                _DashboardActionTile(
                                  label: 'Invest',
                                  imageAsset: catalog.imageForSlot('invest'),
                                  onTap: () => widget.onNavSelected?.call(2),
                                ),
                                _DashboardActionTile(
                                  label: 'Challenges',
                                  imageAsset: catalog.imageForSlot('challenge'),
                                  onTap: () => widget.onNavSelected?.call(3),
                                ),
                                _DashboardActionTile(
                                  label: 'Profile',
                                  imageAsset: catalog.imageForSlot('profile'),
                                  onTap: () => widget.onNavSelected?.call(4),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GlassAssetCard extends StatelessWidget {
  const _GlassAssetCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _GlassPanel(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 110,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trailing,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF85EFAC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassProgressCard extends StatelessWidget {
  const _GlassProgressCard({
    required this.imageAsset,
    required this.savingsRate,
    required this.completion,
  });

  final String imageAsset;
  final double savingsRate;
  final double completion;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 120,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress Snapshot',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _ProgressLine(
                  label: 'Savings Rate',
                  progress: savingsRate / 100,
                  valueLabel: '${savingsRate.toStringAsFixed(0)}%',
                ),
                const SizedBox(height: 10),
                _ProgressLine(
                  label: 'Overall Completion',
                  progress: completion,
                  valueLabel: '${(completion * 100).round()}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassHeroCard extends StatelessWidget {
  const _GlassHeroCard({
    required this.imageAsset,
    required this.onTap,
  });

  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Budget Battle Hub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Launch the local battle engine and sync gold + XP back into your dashboard instantly.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.74),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF85EFAC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Open Battle Hub',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1A4D3D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardActionTile extends StatelessWidget {
  const _DashboardActionTile({
    required this.label,
    required this.imageAsset,
    required this.onTap,
  });

  final String label;
  final String imageAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 156,
        child: _GlassPanel(
          child: Column(
            children: [
              SizedBox(
                height: 70,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.progress,
    required this.valueLabel,
  });

  final String label;
  final double progress;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress.clamp(0.0, 1.0).toDouble(),
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF85EFAC)),
          ),
        ),
      ],
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D4D3C).withOpacity(0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF85EFAC).withOpacity(0.24),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
