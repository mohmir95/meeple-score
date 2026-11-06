import 'open_url_stub.dart'
    if (dart.library.js_interop) 'open_url_web.dart'
    as impl;

typedef OpenUrlHook = void Function(String url);

/// Tests swap this to see which link was opened.
OpenUrlHook? openUrlOverride;

/// Opens [url] in a new browser tab.
void openUrl(String url) => (openUrlOverride ?? impl.openUrl)(url);
