import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'browser_history.dart';

BrowserHistory createBrowserHistory() => _WebHistory();

class _WebHistory implements BrowserHistory {
  @override
  void push() => web.window.history.pushState(null, '');

  @override
  void back() => web.window.history.back();

  @override
  void listen(void Function() onBack) {
    web.window.addEventListener('popstate', ((web.Event _) => onBack()).toJS);
  }
}
