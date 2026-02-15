const CACHE_NAME = 'bambu-viewer-v4';
const SHARE_CACHE = 'bambu-share';
const ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './base.stl',
  'https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.module.js',
  'https://cdn.jsdelivr.net/npm/three@0.170.0/examples/jsm/controls/OrbitControls.js',
  'https://cdn.jsdelivr.net/npm/three@0.170.0/examples/jsm/loaders/3MFLoader.js',
  'https://cdn.jsdelivr.net/npm/three@0.170.0/examples/jsm/loaders/STLLoader.js',
  'https://cdn.jsdelivr.net/npm/fflate@0.8.2/esm/browser.js',
];

// Install: cache shell assets
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(ASSETS).catch(err => {
        console.warn('SW: some assets failed to cache', err);
        return cache.addAll(['./index.html', './manifest.json']);
      });
    })
  );
  self.skipWaiting();
});

// Activate: clean old caches (keep share cache)
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME && k !== SHARE_CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Message handler: store a 3MF file for serving via URL
self.addEventListener('message', event => {
  if (event.data?.type === 'STORE_3MF') {
    const { buffer, fileName } = event.data;
    const url = new URL(`/shared/${encodeURIComponent(fileName)}`, self.location.origin).href;
    const response = new Response(buffer, {
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': `attachment; filename="${fileName}"`,
        'Access-Control-Allow-Origin': '*'
      }
    });
    caches.open(SHARE_CACHE).then(cache => {
      cache.put(url, response).then(() => {
        event.source.postMessage({ type: '3MF_STORED', url });
      });
    });
  }
});

// Fetch handler
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // Serve shared 3MF files from cache
  if (url.pathname.startsWith('/shared/')) {
    event.respondWith(
      caches.open(SHARE_CACHE).then(cache =>
        cache.match(event.request).then(cached => cached || new Response('Not found', { status: 404 }))
      )
    );
    return;
  }

  // For CDN assets (Three.js), use cache-first
  if (url.hostname.includes('cdn.jsdelivr.net')) {
    event.respondWith(
      caches.match(event.request).then(cached => {
        return cached || fetch(event.request).then(response => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
          return response;
        });
      })
    );
    return;
  }

  // For local assets, cache-first with network fallback
  if (url.origin === self.location.origin) {
    event.respondWith(
      caches.match(event.request).then(cached => {
        const fetchPromise = fetch(event.request).then(response => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
          return response;
        }).catch(() => cached);
        return cached || fetchPromise;
      })
    );
    return;
  }
});
