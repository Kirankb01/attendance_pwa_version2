'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {
  "version.json": "1",
  "index.html": "1",
  "main.dart.js": "1",
  "flutter.js": "1",
  "favicon.png": "1",
  "icons/Icon-192.png": "1",
  "icons/Icon-512.png": "1",
  "manifest.json": "1",
};

// The application shell files that are downloaded before a service worker can
// start. These must not be cached, because they are updated by the Flutter
// build process.
const CORE = [
  "main.dart.js",
  "index.html",
  "flutter_bootstrap.js",
  "assets/AssetManifest.bin.json",
  "assets/FontManifest.json"
];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this is a new worker (in other words, not an update), the
// temporary cache is notified with 'activate' so it can clean itself up.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await contentCache.keys().then((keys) => {
          return Promise.all(keys.map((key) => contentCache.delete(key)));
        });
        contentCache = await caches.open(CACHE_NAME);
      }
      // Copy resources from the app cache to the content cache.
      var resources = Object.keys(RESOURCES);
      for (var request of await tempCache.keys()) {
        var key = request.url.substring(self.location.origin.length + 1);
        if (resources.indexOf(key) === -1) {
          await tempCache.delete(request);
        }
      }
    } finally {
      return self.clients.claim();
    }
  }());
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') return;

  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);

  // Redirect URLs to the index.html file.
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }

  // If the URL is not the RESOURCE list, skip the cache.
  if (!RESOURCES[key]) {
    event.respondWith(
      caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          return response || fetch(event.request);
        });
      })
    );
    return;
  }

  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(event.request).then((response) => {
        if (response) {
          return response;
        }
        return fetch(event.request).then((response) => {
          cache.put(event.request, response.clone());
          return response;
        });
      });
    })
  );
});
