import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_update_impl.dart' as impl;

/// Notices when a newer build of the web app has been deployed.
///
/// CI compiles the commit id in as `APP_BUILD` and publishes the same id in
/// `app_version.json`. While the running id differs from the published one,
/// [available] is true and the app offers to reload.
class AppUpdateController extends ChangeNotifier {
  AppUpdateController({
    String? currentBuild,
    Future<String?> Function()? fetchLatestBuild,
    Future<void> Function()? applyUpdate,
    void Function(void Function() onVisible)? watchVisibility,
    this.interval = const Duration(minutes: 15),
  }) : currentBuild = currentBuild ?? const String.fromEnvironment('APP_BUILD'),
       _fetchLatestBuild = fetchLatestBuild ?? impl.fetchLatestBuild,
       _applyUpdate = applyUpdate ?? impl.reloadFresh,
       _watchVisibility = watchVisibility ?? impl.onVisible;

  /// Empty for local and test builds, which never look for updates.
  final String currentBuild;
  final Duration interval;
  final Future<String?> Function() _fetchLatestBuild;
  final Future<void> Function() _applyUpdate;
  final void Function(void Function() onVisible) _watchVisibility;

  Timer? _timer;
  var _available = false;
  var _dismissed = false;
  var _updating = false;

  bool get enabled => currentBuild.isNotEmpty;

  /// A newer build is live and the user has not dismissed the prompt.
  bool get available => _available && !_dismissed;

  bool get updating => _updating;

  /// Checks now, then on every [interval] and whenever the app is shown again.
  void start() {
    if (!enabled || _timer != null) {
      return;
    }
    unawaited(check());
    _timer = Timer.periodic(interval, (_) => check());
    _watchVisibility(() => unawaited(check()));
  }

  Future<void> check() async {
    if (!enabled || _available) {
      return;
    }
    try {
      final latest = await _fetchLatestBuild();
      if (latest != null && latest.isNotEmpty && latest != currentBuild) {
        _available = true;
        notifyListeners();
      }
    } catch (_) {
      // Offline or not deployed yet: try again on the next check.
    }
  }

  /// Hides the prompt until the next app launch.
  void dismiss() {
    _dismissed = true;
    notifyListeners();
  }

  Future<void> update() async {
    if (_updating) {
      return;
    }
    _updating = true;
    notifyListeners();
    await _applyUpdate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
