import 'browser_history_stub.dart'
    if (dart.library.js_interop) 'browser_history_web.dart'
    as impl;

/// The parts of the browser's history the app needs.
abstract class BrowserHistory {
  /// Adds an entry for a page that just opened.
  void push();

  /// Steps back one entry, as if the user pressed back.
  void back();

  /// Calls [onBack] when the user goes back (back button or edge swipe).
  void listen(void Function() onBack);
}

/// The real browser history on the web; does nothing elsewhere.
BrowserHistory createBrowserHistory() => impl.createBrowserHistory();
