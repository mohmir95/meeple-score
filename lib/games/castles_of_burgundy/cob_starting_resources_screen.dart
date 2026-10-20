import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'cob_game.dart';

/// Setup chart for Castles of Burgundy Special Edition starting resources.
///
/// Each player receives 1 silver coin and 3 goods tiles. Workers are handed
/// out by turn order: the starting player gets 1, then 2, 3, and 4 clockwise.
class CobStartingResourcesScreen extends StatelessWidget {
  const CobStartingResourcesScreen({super.key});

  static const silverAsset =
      'assets/games/castles_of_burgundy/icons/silver.png';
  static const workerAsset =
      'assets/games/castles_of_burgundy/icons/worker.png';
  static const goodsAsset = 'assets/games/castles_of_burgundy/icons/goods.png';

  /// The worker tile is portrait (274 x 384 px).
  static const workerAspectRatio = 274 / 384;

  static const _goodsPerPlayer = 3;
  static const _silverPerPlayer = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    final accent = const CastlesOfBurgundySpecialEditionGame().accentColor;
    final maxSeat = const CastlesOfBurgundySpecialEditionGame().maxPlayers;

    return AppPage(
      title: l10n.t('hub.startingResources'),
      coverImageAsset: CastlesOfBurgundySpecialEditionGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _SetupPanel(
              key: const ValueKey('cob-starting-resources-panel'),
              accent: accent,
              compact: compact,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PanelTitle(text: l10n.t('hub.startingResources')),
                  SizedBox(height: compact ? 10 : 12),
                  Text(
                    l10n.t('cob.startingResources.note'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2A2620),
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 24),
                  for (var seat = 1; seat <= maxSeat; seat++) ...[
                    if (seat > 1) SizedBox(height: compact ? 16 : 22),
                    _PlayerResourceRow(
                      label: l10n.t('players.numbered', {'n': '$seat'}),
                      workers: seat,
                      silver: _silverPerPlayer,
                      goods: _goodsPerPlayer,
                      maxWorkers: maxSeat,
                      compact: compact,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupPanel extends StatelessWidget {
  const _SetupPanel({
    super.key,
    required this.accent,
    required this.compact,
    required this.child,
  });

  final Color accent;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 28,
          vertical: compact ? 22 : 28,
        ),
        child: child,
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: const Color(0xFF6B2030),
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        height: 1.15,
      ),
    );
  }
}

class _PlayerResourceRow extends StatelessWidget {
  const _PlayerResourceRow({
    required this.label,
    required this.workers,
    required this.silver,
    required this.goods,
    required this.maxWorkers,
    required this.compact,
  });

  final String label;
  final int workers;
  final int silver;
  final int goods;
  final int maxWorkers;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gap = compact ? 4.0 : 8.0;
    final groupGap = compact ? 10.0 : 24.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: compact ? 80 : 120,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1C1A17),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        // Size for the widest row (most workers) so all rows match and fit
        // on one line. If the screen is too narrow even at the minimum size,
        // silver + goods and the workers wrap as whole groups.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fronts = silver + goods;
              final fixed =
                  (fronts - 1) * gap + (maxWorkers - 1) * gap + groupGap + 1;
              final units =
                  fronts +
                  maxWorkers * CobStartingResourcesScreen.workerAspectRatio;
              final fitted = (constraints.maxWidth - fixed) / units;
              final iconSize = fitted.clamp(18.0, compact ? 40.0 : 52.0);

              return Wrap(
                spacing: groupGap,
                runSpacing: gap,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _IconGroup(
                    gap: gap,
                    children: [
                      for (var i = 0; i < silver; i++)
                        _ResourceIcon(
                          asset: CobStartingResourcesScreen.silverAsset,
                          size: iconSize,
                          label: l10n.t('cob.silver'),
                        ),
                      for (var i = 0; i < goods; i++)
                        _ResourceIcon(
                          asset: CobStartingResourcesScreen.goodsAsset,
                          size: iconSize,
                          label: l10n.t('cob.goods'),
                        ),
                    ],
                  ),
                  _IconGroup(
                    gap: gap,
                    children: [
                      for (var i = 0; i < workers; i++)
                        _ResourceIcon(
                          asset: CobStartingResourcesScreen.workerAsset,
                          size: iconSize,
                          aspectRatio:
                              CobStartingResourcesScreen.workerAspectRatio,
                          label: l10n.t('cob.worker'),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IconGroup extends StatelessWidget {
  const _IconGroup({required this.gap, required this.children});

  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          children[i],
        ],
      ],
    );
  }
}

class _ResourceIcon extends StatelessWidget {
  const _ResourceIcon({
    required this.asset,
    required this.size,
    required this.label,
    this.aspectRatio = 1,
  });

  final String asset;
  final double size;
  final String label;

  /// Width / height of the artwork, so non-square pieces aren't padded.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size * aspectRatio,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      semanticLabel: label,
    );
  }
}
