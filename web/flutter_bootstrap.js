{{flutter_js}}
{{flutter_build_config}}

// Loads the app without Flutter's own service worker: it no longer caches
// anything and would unregister ours.
_flutter.loader.load();

// Keeps images on the device between visits (see image_cache_sw.js).
(function registerImageCache() {
  if (!('serviceWorker' in navigator)) {
    return;
  }
  const register = () => {
    // Relative to the page, so it works under the GitHub Pages base path.
    navigator.serviceWorker.register('image_cache_sw.js').catch((error) => {
      console.warn('Image cache unavailable:', error);
    });
  };
  if (document.readyState === 'complete') {
    register();
  } else {
    window.addEventListener('load', register);
  }
})();
