import 'package:flutter/widgets.dart';

import 'browser_history.dart';

/// Keeps the browser's history in step with the app's pages, so the back
/// button and the edge-swipe back gesture close the top page instead of
/// leaving the app.
///
/// Each page opened on top of the home screen gets its own history entry.
/// The entry is added right when the page opens, after the user's tap, so
/// Chrome doesn't skip it (Chrome skips entries a page adds without user
/// interaction, which is why the app used to close on the first back).
/// Flutter's own single-entry history is turned off in `main.dart`.
class BrowserBackSync extends NavigatorObserver {
  BrowserBackSync({BrowserHistory? history})
    : _history = history ?? createBrowserHistory() {
    _history.listen(_onBrowserBack);
  }

  final BrowserHistory _history;

  /// Pages open above the first one, each with a history entry.
  int _depth = 0;

  /// History steps the app made itself, which must not close a page.
  int _ownSteps = 0;

  /// True while closing a page because the user went back in the browser.
  bool _closingForBrowser = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) {
      return;
    }
    _depth++;
    _history.push();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _pageClosed();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _pageClosed();

  void _pageClosed() {
    if (_depth == 0) {
      return;
    }
    _depth--;
    // Closed from inside the app (back arrow, dialog button): drop the
    // page's entry too, so the next browser back goes to the right page.
    if (!_closingForBrowser) {
      _ownSteps++;
      _history.back();
    }
  }

  Future<void> _onBrowserBack() async {
    if (_ownSteps > 0) {
      _ownSteps--;
      return;
    }
    final navigator = this.navigator;
    if (navigator == null || _depth == 0) {
      return;
    }
    final depthBefore = _depth;
    _closingForBrowser = true;
    try {
      await navigator.maybePop();
    } finally {
      _closingForBrowser = false;
    }
    // The page refused to close (e.g. it asks for confirmation): the
    // browser already stepped back, so restore the page's entry.
    if (_depth == depthBefore) {
      _history.push();
    }
  }
}
