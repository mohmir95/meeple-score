import 'package:flutter/material.dart';

/// [Image.asset] with a loading state: a soft pulsing placeholder fills the
/// image's place until it is decoded, then the image fades in. Images already
/// in memory show at once, with no flicker.
Image loadingImage(
  String name, {
  Key? key,
  double? width,
  double? height,
  BoxFit? fit,
  AlignmentGeometry alignment = Alignment.center,
  FilterQuality filterQuality = FilterQuality.medium,
  String? semanticLabel,
  bool excludeFromSemantics = false,
  Color? color,
  BlendMode? colorBlendMode,
  ImageErrorWidgetBuilder? errorBuilder,
  bool gaplessPlayback = false,
  bool isAntiAlias = false,
}) {
  return Image.asset(
    name,
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    filterQuality: filterQuality,
    semanticLabel: semanticLabel,
    excludeFromSemantics: excludeFromSemantics,
    color: color,
    colorBlendMode: colorBlendMode,
    errorBuilder: errorBuilder,
    gaplessPlayback: gaplessPlayback,
    isAntiAlias: isAntiAlias,
    frameBuilder: _frameBuilder,
  );
}

Widget _frameBuilder(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) {
    return child;
  }
  final loaded = frame != null;
  return Stack(
    fit: StackFit.passthrough,
    children: [
      if (!loaded) const Positioned.fill(child: _Placeholder()),
      AnimatedOpacity(
        opacity: loaded ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: child,
      ),
    ],
  );
}

/// A soft tone that gently pulses while the image loads.
class _Placeholder extends StatefulWidget {
  const _Placeholder();

  @override
  State<_Placeholder> createState() => _PlaceholderState();
}

class _PlaceholderState extends State<_Placeholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _pulse
        ..stop()
        ..value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = Theme.of(context).colorScheme.onSurface;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => ColoredBox(
          color: tone.withValues(
            alpha: 0.08 + 0.12 * Curves.easeInOut.transform(_pulse.value),
          ),
        ),
      ),
    );
  }
}
