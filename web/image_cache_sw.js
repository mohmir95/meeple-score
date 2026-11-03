'use strict';

// Keeps the app's images and fonts on the device, so later visits show them
// at once instead of waiting on the network.
//
// Stale-while-revalidate: a cached file is served immediately while a fresh
// copy is fetched in the background for next time, so replaced artwork
// arrives one visit later. App code, translations and everything else always
// go to the network, so a new release never pairs new code with old text.

const CACHE = 'meeple-images-v1';
const CACHED_FILES = /\.(png|jpe?g|webp|gif|svg|ico|ttf|otf|woff2?)$/i;

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      // Drops caches from older versions of this worker.
      const names = await caches.keys();
      await Promise.all(
        names
          .filter((name) => name.startsWith('meeple-images-') && name !== CACHE)
          .map((name) => caches.delete(name)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') {
    return;
  }
  const url = new URL(request.url);
  if (url.origin !== self.location.origin || !CACHED_FILES.test(url.pathname)) {
    return;
  }

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      const cached = await cache.match(request, { ignoreSearch: true });
      const fresh = fetch(request).then((response) => {
        if (response.ok) {
          cache.put(request, response.clone());
        }
        return response;
      });
      if (cached) {
        event.waitUntil(fresh.catch(() => {}));
        return cached;
      }
      return fresh;
    })(),
  );
});
