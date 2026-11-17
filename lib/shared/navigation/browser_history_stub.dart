import 'browser_history.dart';

BrowserHistory createBrowserHistory() => const _NoHistory();

class _NoHistory implements BrowserHistory {
  const _NoHistory();

  @override
  void push() {}

  @override
  void back() {}

  @override
  void listen(void Function() onBack) {}
}
