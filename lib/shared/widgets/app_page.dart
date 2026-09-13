import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';
import 'language_toggle.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions,
    this.coverImageAsset,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;
  final String? coverImageAsset;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      appBar: AppBar(
        leading: leading,
        titleSpacing: coverImageAsset == null ? null : 8,
        title: Row(
          children: [
            if (coverImageAsset != null) ...[
              _AppBarCover(asset: coverImageAsset!, label: title),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(title),
              ),
            ),
          ],
        ),
        actions: [...?actions, const LanguageToggle()],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: constraints.maxWidth
                    .clamp(0, Breakpoints.contentMaxWidth)
                    .toDouble(),
                height: constraints.maxHeight,
                child: body,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AppBarCover extends StatelessWidget {
  const _AppBarCover({required this.asset, required this.label});

  final String asset;
  final String label;

  static const size = 32.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: label,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(width: size, height: size);
        },
      ),
    );
  }
}
