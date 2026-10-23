import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart';

/// Core files the browser may still hold from the old build. GitHub Pages
/// lets browsers cache them for up to 10 minutes.
const _coreFiles = [
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
];

/// Reads the deployed build id, bypassing every cache. Paths resolve against
/// the page's `<base href>`.
Future<String?> fetchLatestBuild() async {
  final url = 'app_version.json?t=${DateTime.now().millisecondsSinceEpoch}';
  final response = await window
      .fetch(url.toJS, RequestInit(cache: 'no-store'))
      .toDart;
  if (!response.ok) {
    return null;
  }
  final body = (await response.text().toDart).toDart;
  final json = jsonDecode(body);
  return json is Map<String, dynamic> ? json['build'] as String? : null;
}

/// Refreshes the cached core files, then reloads onto the new build.
Future<void> reloadFresh() async {
  for (final file in _coreFiles) {
    try {
      await window.fetch(file.toJS, RequestInit(cache: 'reload')).toDart;
    } catch (_) {
      // A missing file must not block the reload.
    }
  }
  window.location.reload();
}

/// Calls [callback] whenever the tab or installed app is shown again.
void onVisible(void Function() callback) {
  document.addEventListener(
    'visibilitychange',
    ((Event _) {
      if (document.visibilityState == 'visible') {
        callback();
      }
    }).toJS,
  );
}
