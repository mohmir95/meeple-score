import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import 'app_update.dart';

/// Floats a "new version" prompt over the app while an update is available.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({
    super.key,
    required this.controller,
    required this.child,
  });

  final AppUpdateController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (!controller.available) {
              return const SizedBox.shrink();
            }
            return Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _Prompt(controller: controller),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.controller});

  final AppUpdateController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('app-update-banner'),
      elevation: 6,
      color: scheme.inverseSurface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.system_update_alt, color: scheme.onInverseSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.t('update.available'),
                style: TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('app-update-later'),
              onPressed: controller.updating ? null : controller.dismiss,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onInverseSurface,
              ),
              child: Text(l10n.t('update.later')),
            ),
            const SizedBox(width: 4),
            FilledButton(
              key: const ValueKey('app-update-now'),
              onPressed: controller.updating ? null : controller.update,
              child: controller.updating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.t('update.now')),
            ),
          ],
        ),
      ),
    );
  }
}
